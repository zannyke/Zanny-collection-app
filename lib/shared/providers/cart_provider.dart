import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/cloudflare/api_client.dart';
import '../models/models.dart';
import '../models/app_user.dart';
import 'auth_provider.dart';

// ────────────────────────────────────────────────
// Cart Provider
// ────────────────────────────────────────────────
class CartNotifier extends Notifier<List<CartItem>> {
  final ApiClient _api = ApiClient.instance;
  bool _isSyncing = false;
  Timer? _pollTimer;

  @override
  List<CartItem> build() {
    // Load persisted cart from local cache immediately on startup
    _loadFromCache();

    // Listen to changes in the current user state
    ref.listen<AppUser?>(currentUserProvider, (previous, next) {
      if (next != null) {
        // User logged in / loaded
        _startPolling();
        _mergeLocalCartWithServer();
      } else {
        // User logged out
        _stopPolling();
        // Do not clear the cart on logout to allow guest session cart persistence
      }
    });

    // Check if user is already logged in on initial build
    final initialUser = ref.read(currentUserProvider);
    if (initialUser != null) {
      _startPolling();
      Future.microtask(() => refreshFromServer());
    }

    ref.onDispose(() {
      _pollTimer?.cancel();
    });

    return [];
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      refreshFromServer();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> refreshFromServer() async {
    final user = ref.read(currentUserProvider);
    if (user == null || _isSyncing) return;

    try {
      _isSyncing = true;
      final resp = await _api.get('/api/cart');
      final raw = resp.data['items'] as List? ?? [];
      final serverItems = raw.map<CartItem>((item) {
        final m = Map<String, dynamic>.from(item as Map);
        final productMap = Map<String, dynamic>.from(m['product'] as Map);
        final product = Product.fromJson(productMap);
        return CartItem(
          product: product,
          selectedColor: m['selectedColor'] as String? ?? '',
          selectedSize: m['selectedSize'] as String? ?? '',
          quantity: (m['quantity'] as num?)?.toInt() ?? 1,
        );
      }).toList();

      if (!_areItemListsEqual(state, serverItems)) {
        state = serverItems;
        await _saveToCache();
      }
    } catch (e) {
      debugPrint('⚠️ Failed to fetch cart from server: $e');
    } finally {
      _isSyncing = false;
    }
  }

  bool _areItemListsEqual(List<CartItem> list1, List<CartItem> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      final item1 = list1[i];
      final item2 = list2[i];
      if (item1.product.id != item2.product.id ||
          item1.selectedColor != item2.selectedColor ||
          item1.selectedSize != item2.selectedSize ||
          item1.quantity != item2.quantity) {
        return false;
      }
    }
    return true;
  }

  Future<void> _syncToServer() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      _isSyncing = true;
      final payload = state.map((item) => {
        'product_id': item.product.id,
        'quantity': item.quantity,
        'selected_size': item.selectedSize,
        'selected_color': item.selectedColor,
      }).toList();

      await _api.post('/api/cart', data: {'items': payload});
    } catch (e) {
      debugPrint('⚠️ Failed to sync cart to server: $e');
    } finally {
      _isSyncing = false;
    }
  }

  void addItem(Product product, String color, String size, int qty) async {
    final key = '${product.id}_${color}_$size';
    final existing = state.indexWhere((i) => i.key == key);
    List<CartItem> updated;
    if (existing >= 0) {
      updated = List<CartItem>.from(state);
      updated[existing] = updated[existing].copyWith(
        quantity: updated[existing].quantity + qty,
      );
    } else {
      updated = [...state, CartItem(product: product, selectedColor: color, selectedSize: size, quantity: qty)];
    }
    state = updated;
    await _saveToCache();
    await _syncToServer();
  }

  void removeItem(String key) async {
    state = state.where((i) => i.key != key).toList();
    await _saveToCache();
    await _syncToServer();
  }

  void updateQuantity(String key, int qty) async {
    if (qty <= 0) {
      removeItem(key);
      return;
    }
    state = state.map((i) => i.key == key ? i.copyWith(quantity: qty) : i).toList();
    await _saveToCache();
    await _syncToServer();
  }

  void clear() async {
    state = [];
    await _saveToCache();
    await _syncToServer();
  }

  void clearLocal() {
    state = [];
    // No server sync; used for temporary clears if needed.
  }

  Future<void> _mergeLocalCartWithServer() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      _isSyncing = true;
      final resp = await _api.get('/api/cart');
      final raw = resp.data['items'] as List? ?? [];
      final serverItems = raw.map<CartItem>((item) {
        final m = Map<String, dynamic>.from(item as Map);
        final productMap = Map<String, dynamic>.from(m['product'] as Map);
        final product = Product.fromJson(productMap);
        return CartItem(
          product: product,
          selectedColor: m['selectedColor'] as String? ?? '',
          selectedSize: m['selectedSize'] as String? ?? '',
          quantity: (m['quantity'] as num?)?.toInt() ?? 1,
        );
      }).toList();

      final mergedItems = List<CartItem>.from(serverItems);
      for (final localItem in state) {
        final existingIdx = mergedItems.indexWhere((item) =>
            item.product.id == localItem.product.id &&
            item.selectedColor == localItem.selectedColor &&
            item.selectedSize == localItem.selectedSize);
        if (existingIdx >= 0) {
          mergedItems[existingIdx] = mergedItems[existingIdx].copyWith(
            quantity: mergedItems[existingIdx].quantity + localItem.quantity,
          );
        } else {
          mergedItems.add(localItem);
        }
      }

      state = mergedItems;
      await _saveToCache();

      final payload = state.map((item) => {
        'product_id': item.product.id,
        'quantity': item.quantity,
        'selected_size': item.selectedSize,
        'selected_color': item.selectedColor,
      }).toList();

      await _api.post('/api/cart', data: {'items': payload});
    } catch (e) {
      debugPrint('⚠️ Failed to merge cart: $e');
      refreshFromServer();
    } finally {
      _isSyncing = false;
    }
  }

  // Helper methods for persistence
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('cart_items');
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = json.decode(jsonString);
        final loaded = decoded.map<CartItem>((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        state = loaded;
      }
    } catch (e) {
      debugPrint('⚠️ Failed to decode cart cache: $e');
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(state.map((e) => e.toJson()).toList());
      await prefs.setString('cart_items', jsonString);
    } catch (e) {
      debugPrint('⚠️ Failed to save cart cache: $e');
    }
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, item) => sum + item.quantity);
});

final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).fold(0.0, (sum, item) => sum + item.subtotal);
});


