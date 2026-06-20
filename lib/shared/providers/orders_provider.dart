import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/cloudflare/api_client.dart';
import '../../core/services/notification_service.dart';
import '../models/models.dart';
import 'auth_provider.dart';
import 'cart_provider.dart';

// ── Orders Notifier ───────────────────────────────────────────────────────────

class OrdersNotifier extends Notifier<List<Order>> {
  String _localKey(String userId) => 'cf_cached_orders_$userId';
  final ApiClient _api = ApiClient.instance;
  Timer? _pollingTimer;

  @override
  List<Order> build() {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      _pollingTimer?.cancel();
      _pollingTimer = null;
      Future.microtask(() => state = []);
      return [];
    }

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _poll();
    });

    ref.onDispose(() {
      _pollingTimer?.cancel();
    });

    Future.microtask(() => _load());
    return [];
  }

  Future<void> _load() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await _loadLocal(user.id);

      try {
        final resp = await _api.get('/api/orders');
        final raw = resp.data['orders'] as List? ?? [];
        final orders = raw.map((j) => _parseOrder(Map<String, dynamic>.from(j as Map))).toList();
        state = orders;
        await _saveLocal(user.id, orders);
      } catch (_) {}
    }
  }

  Future<void> _poll() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final resp = await _api.get('/api/orders');
      final raw = resp.data['orders'] as List? ?? [];
      final newOrders = raw.map((j) => _parseOrder(Map<String, dynamic>.from(j as Map))).toList();

      _checkDifferencesAndNotify(state, newOrders);

      state = newOrders;
      await _saveLocal(user.id, newOrders);
    } catch (_) {}
  }

  void _checkDifferencesAndNotify(List<Order> oldOrders, List<Order> newOrders) {
    if (oldOrders.isEmpty) return;

    for (final newOrder in newOrders) {
      final oldOrderIndex = oldOrders.indexWhere((o) => o.id == newOrder.id);
      if (oldOrderIndex == -1) continue;
      final oldOrder = oldOrders[oldOrderIndex];

      // Check status change
      if (newOrder.status != oldOrder.status) {
        NotificationService.showLocalNotification(
          newOrder.id.hashCode,
          'Order Update',
          'Your order #${newOrder.id} status is now: ${newOrder.status.toUpperCase()}',
        );
      }

      // Check items confirmation changes
      for (final newItem in newOrder.items) {
        final oldItemIndex = oldOrder.items.indexWhere(
          (item) => item.product.id == newItem.product.id &&
                    item.selectedColor == newItem.selectedColor &&
                    item.selectedSize == newItem.selectedSize,
        );
        if (oldItemIndex == -1) continue;
        final oldItem = oldOrder.items[oldItemIndex];

        if (newItem.isConfirmed != oldItem.isConfirmed) {
          final statusStr = newItem.isConfirmed ? 'Confirmed' : 'Unavailable';
          NotificationService.showLocalNotification(
            (newOrder.id + newItem.product.id).hashCode,
            'Item Update',
            'Item "${newItem.product.name}" in Order #${newOrder.id} is now $statusStr.',
          );
        }
      }
    }
  }

  Future<void> _loadLocal(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_localKey(userId));
      if (s != null) {
        final List decoded = jsonDecode(s);
        state = decoded.map((j) => Order.fromJson(Map<String, dynamic>.from(j))).toList();
      } else {
        state = [];
      }
    } catch (_) {}
  }

  Future<void> _saveLocal(String userId, List<Order> orders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localKey(userId), jsonEncode(orders.map((o) => o.toJson()).toList()));
    } catch (_) {}
  }

  Future<Order> placeOrder({
    required List<CartItem> items,
    required double totalAmount,
    required String deliveryAddress,
    required String recipientName,
    required String recipientPhone,
  }) async {
    final id = 'ZC_ORD_${DateTime.now().millisecondsSinceEpoch}';
    final newOrder = Order(
      id: id,
      items: items,
      totalAmount: totalAmount,
      status: 'pending',
      createdAt: DateTime.now(),
      deliveryAddress: deliveryAddress,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
    );

    state = [newOrder, ...state];
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await _saveLocal(user.id, state);
    }
    ref.read(cartProvider.notifier).clear();

    try {
      await _api.post('/api/orders', data: {
        'id': id,
        'items': items.map((i) => {
          'product_id': i.product.id,
          'product_name': i.product.name,
          'product_price': i.product.price,
          'selected_color': i.selectedColor,
          'selected_size': i.selectedSize,
          'quantity': i.quantity,
          'image_url': i.product.images.isNotEmpty ? i.product.images.first : '',
          'is_confirmed': i.isConfirmed,
        }).toList(),
        'total_amount': totalAmount,
        'status': 'pending',
        'delivery_address': deliveryAddress,
        'recipient_name': recipientName,
        'recipient_phone': recipientPhone,
      });
    } on DioException catch (_) {
    }

    return newOrder;
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    state = state.map((o) => o.id == orderId
      ? Order(
          id: o.id, items: o.items, totalAmount: o.totalAmount,
          status: status, createdAt: o.createdAt,
          deliveryAddress: o.deliveryAddress,
          recipientName: o.recipientName,
          recipientPhone: o.recipientPhone,
        )
      : o).toList();
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await _saveLocal(user.id, state);
    }
    try {
      await _api.put('/api/orders/$orderId/status', data: {'status': status});
    } catch (_) {}
  }

  Future<void> refresh() => _load();

  Order _parseOrder(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final itemsList = rawItems is List ? rawItems : (rawItems is String ? jsonDecode(rawItems) as List : []);
    final cartItems = itemsList.map<CartItem>((item) {
      final m = Map<String, dynamic>.from(item as Map);
      final product = Product(
        id: m['product_id'] as String? ?? '',
        name: m['product_name'] as String? ?? 'Product',
        subtitle: '',
        description: '',
        price: (m['product_price'] as num?)?.toDouble() ?? 0.0,
        category: '',
        images: [m['image_url'] as String? ?? ''],
        colors: [m['selected_color'] as String? ?? ''],
        sizes: [m['selected_size'] as String? ?? ''],
      );
      return CartItem(
        product: product,
        selectedColor: m['selected_color'] as String? ?? '',
        selectedSize: m['selected_size'] as String? ?? '',
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
        isConfirmed: m['is_confirmed'] as bool? ?? true,
      );
    }).toList();

    return Order(
      id: json['id'] as String,
      items: cartItems,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      deliveryAddress: json['delivery_address'] as String? ?? '',
      recipientName: json['recipient_name'] as String? ?? '',
      recipientPhone: json['recipient_phone'] as String? ?? '',
    );
  }
}

// ── Admin Orders Notifier ────────────────────────────────────────────────────

class AdminOrdersNotifier extends Notifier<List<Order>> {
  final ApiClient _api = ApiClient.instance;

  @override
  List<Order> build() {
    final user = ref.watch(currentUserProvider);
    if (user == null || user.email != 'admin@zannycollection.com') {
      return [];
    }
    Future.microtask(() => refresh());
    return [];
  }

  Future<void> refresh() async {
    try {
      final resp = await _api.get('/api/admin/orders');
      final raw = resp.data['orders'] as List? ?? [];
      state = raw.map((j) => _parseOrder(Map<String, dynamic>.from(j as Map))).toList();
    } catch (_) {}
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    state = state.map((o) => o.id == orderId
      ? Order(
          id: o.id, items: o.items, totalAmount: o.totalAmount,
          status: status, createdAt: o.createdAt,
          deliveryAddress: o.deliveryAddress,
          recipientName: o.recipientName,
          recipientPhone: o.recipientPhone,
        )
      : o).toList();

    try {
      await _api.put('/api/orders/$orderId/status', data: {'status': status});
    } catch (_) {}
    ref.read(ordersProvider.notifier).refresh();
  }

  Future<void> updateOrderItemsAndStatus(String orderId, String status, List<CartItem> items) async {
    state = state.map((o) => o.id == orderId
      ? Order(
          id: o.id, items: items, totalAmount: o.totalAmount,
          status: status, createdAt: o.createdAt,
          deliveryAddress: o.deliveryAddress,
          recipientName: o.recipientName,
          recipientPhone: o.recipientPhone,
        )
      : o).toList();

    try {
      final serializedItems = items.map((i) => {
        'product_id': i.product.id,
        'product_name': i.product.name,
        'product_price': i.product.price,
        'selected_color': i.selectedColor,
        'selected_size': i.selectedSize,
        'quantity': i.quantity,
        'image_url': i.product.images.isNotEmpty ? i.product.images.first : '',
        'is_confirmed': i.isConfirmed,
      }).toList();

      await _api.put('/api/orders/$orderId/status', data: {
        'status': status,
        'items': serializedItems,
      });
    } catch (_) {}
    ref.read(ordersProvider.notifier).refresh();
  }

  Order _parseOrder(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final itemsList = rawItems is List ? rawItems : (rawItems is String ? jsonDecode(rawItems) as List : []);
    final cartItems = itemsList.map<CartItem>((item) {
      final m = Map<String, dynamic>.from(item as Map);
      final product = Product(
        id: m['product_id'] as String? ?? '',
        name: m['product_name'] as String? ?? 'Product',
        subtitle: '',
        description: '',
        price: (m['product_price'] as num?)?.toDouble() ?? 0.0,
        category: '',
        images: [m['image_url'] as String? ?? ''],
        colors: [m['selected_color'] as String? ?? ''],
        sizes: [m['selected_size'] as String? ?? ''],
      );
      return CartItem(
        product: product,
        selectedColor: m['selected_color'] as String? ?? '',
        selectedSize: m['selected_size'] as String? ?? '',
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
        isConfirmed: m['is_confirmed'] as bool? ?? true,
      );
    }).toList();

    return Order(
      id: json['id'] as String,
      items: cartItems,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      deliveryAddress: json['delivery_address'] as String? ?? '',
      recipientName: json['recipient_name'] as String? ?? '',
      recipientPhone: json['recipient_phone'] as String? ?? '',
    );
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final ordersProvider = NotifierProvider<OrdersNotifier, List<Order>>(OrdersNotifier.new);

final adminOrdersProvider = NotifierProvider<AdminOrdersNotifier, List<Order>>(AdminOrdersNotifier.new);
