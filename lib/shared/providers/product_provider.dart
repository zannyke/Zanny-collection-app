import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/cloudflare/api_client.dart';
import '../../core/cloudflare/cloudflare_config.dart';
import '../models/models.dart';

// ── Product Repository ────────────────────────────────────────────────────────

class ProductRepository {
  final ApiClient _api = ApiClient.instance;

  static const String _cacheKey = 'cf_cached_products';

  static Future<void> _saveLocal(List<Product> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(list.map((p) => p.toJson()).toList()));
    } catch (_) {}
  }

  static Future<List<Product>> _loadLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_cacheKey);
      if (s == null) return [];
      final List decoded = jsonDecode(s);
      return decoded.map((j) => Product.fromJson(Map<String, dynamic>.from(j))).toList();
    } catch (_) { return []; }
  }

  Future<List<Product>> fetchAll() async {
    try {
      final resp = await _api.get('/api/products');
      final list = _parseProducts(resp.data['products'] as List);
      await _saveLocal(list);
      return list;
    } catch (_) {
      return _loadLocal();
    }
  }

  Future<List<Product>> fetchByCategory(String slug, {String sort = 'default'}) async {
    try {
      final resp = await _api.get('/api/products', queryParameters: {
        'category': slug,
        'sort': sort,
      });
      return _parseProducts(resp.data['products'] as List);
    } on DioException catch (_) {
      final all = await _loadLocal();
      return _filterLocal(all, slug, sort);
    }
  }

  Future<Product?> fetchById(String id) async {
    try {
      final resp = await _api.get('/api/products/$id');
      return _parseProduct(resp.data['product'] as Map<String, dynamic>);
    } catch (_) {
      final all = await _loadLocal();
      return all.where((p) => p.id == id).firstOrNull;
    }
  }

  Future<List<Product>> search(String query) async {
    if (query.isEmpty) return [];
    try {
      final resp = await _api.get('/api/products', queryParameters: {'search': query});
      return _parseProducts(resp.data['products'] as List);
    } catch (_) {
      final all = await _loadLocal();
      final q = query.toLowerCase();
      return all.where((p) =>
        p.name.toLowerCase().contains(q) || p.description.toLowerCase().contains(q)
      ).toList();
    }
  }

  List<Product> _filterLocal(List<Product> all, String slug, String sort) {
    List<Product> list;
    if (slug == 'new-arrivals') {
      list = all.where((p) => p.isNew).toList();
    } else if (slug == 'sale') {
      list = all.where((p) => p.isSale).toList();
    } else {
      list = all.where((p) => p.category == slug).toList();
    }
    if (sort == 'price_asc') list.sort((a, b) => a.price.compareTo(b.price));
    if (sort == 'price_desc') list.sort((a, b) => b.price.compareTo(a.price));
    return list;
  }

  List<Product> _parseProducts(List raw) {
    return raw
      .map((j) => _parseProduct(Map<String, dynamic>.from(j as Map)))
      .toList();
  }

  Product _parseProduct(Map<String, dynamic> json) {
    // Normalise R2 image URLs
    final images = _parseList(json['images'])
        .map((url) => _resolveImageUrl(url))
        .toList();
    return Product.fromJson({ ...json, 'images': images });
  }

  String _resolveImageUrl(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http')) return url;
    // Relative path — prepend R2 public URL
    return '${CloudflareConfig.r2PublicUrl}/$url'.replaceAll('//', '/').replaceFirst(':/', '://');
  }

  List<String> _parseList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }
}

// ── Products Notifier ─────────────────────────────────────────────────────────

class ProductsNotifier extends Notifier<List<Product>> {
  final _repo = ProductRepository();

  @override
  List<Product> build() {
    _load();
    return []; // Return empty list while loading — real data arrives via _load()
  }

  Future<void> _load() async {
    try {
      final products = await _repo.fetchAll();
      state = products;
    } catch (_) {}
  }

  Future<void> refresh() => _load();

  Future<void> addProduct(Product product, {bool sendPush = false, String? pushBody}) async {
    final data = product.toJson();
    if (sendPush) {
      data['send_push'] = true;
      if (pushBody != null && pushBody.isNotEmpty) data['push_body'] = pushBody;
    }
    // Let DioException propagate — admin form's _submitForm catch shows the error
    await ApiClient.instance.post('/api/products', data: data);
    await _load();
  }

  Future<void> updateProduct(Product product, {bool sendPush = false, String? pushBody}) async {
    final data = product.toJson();
    if (sendPush) {
      data['send_push'] = true;
      if (pushBody != null && pushBody.isNotEmpty) data['push_body'] = pushBody;
    }
    // Let DioException propagate — admin form's _submitForm catch shows the error
    await ApiClient.instance.put('/api/products/${product.id}', data: data);
    await _load();
  }

  Future<void> deleteProduct(String id) async {
    // Optimistic removal
    final snapshot = List<Product>.from(state);
    state = state.where((p) => p.id != id).toList();
    try {
      await ApiClient.instance.delete('/api/products/$id');
      // Refresh from server after successful delete
      await _load();
    } catch (e) {
      // Revert optimistic removal on failure
      state = snapshot;
      rethrow;
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final productsStateProvider =
    NotifierProvider<ProductsNotifier, List<Product>>(ProductsNotifier.new);

final productRepositoryProvider = Provider<ProductRepository>((_) => ProductRepository());

final categoryProductsProvider =
    FutureProvider.family<List<Product>, (String slug, String sort)>((ref, args) async {
  final all = ref.watch(productsStateProvider);
  final slug = args.$1;
  final sort = args.$2;
  List<Product> list;
  if (slug == 'new-arrivals') {
    list = all.where((p) => p.isNew).toList();
  } else if (slug == 'sale') {
    list = all.where((p) => p.isSale).toList();
  } else {
    list = all.where((p) => p.category == slug).toList();
  }
  if (sort == 'price_asc') list.sort((a, b) => a.price.compareTo(b.price));
  if (sort == 'price_desc') list.sort((a, b) => b.price.compareTo(a.price));
  return list;
});

final newArrivalsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.watch(productsStateProvider).where((p) => p.isNew).toList();
});

final searchResultsProvider = FutureProvider.family<List<Product>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final q = query.toLowerCase();
  return ref.watch(productsStateProvider)
      .where((p) => p.name.toLowerCase().contains(q) || p.description.toLowerCase().contains(q))
      .toList();
});

final productDetailProvider = FutureProvider.family<Product?, String>((ref, id) async {
  final list = ref.watch(productsStateProvider);
  return list.where((p) => p.id == id).firstOrNull;
});

final relatedProductsProvider =
    FutureProvider.family<List<Product>, (String categorySlug, String excludeId)>((ref, args) async {
  return ref.watch(productsStateProvider)
      .where((p) => p.category == args.$1 && p.id != args.$2)
      .toList();
});

final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.watch(productsStateProvider);
});

final zannyOriginalsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.watch(productsStateProvider).where((p) =>
    p.name.toLowerCase().contains('zc') || p.name.toLowerCase().contains('zanny')
  ).toList();
});

class ProductReviewsSummary {
  final String productId;
  final double average;
  final int total;
  final Map<int, double> distribution;
  final List<ProductReview> reviews;

  ProductReviewsSummary({
    required this.productId,
    required this.average,
    required this.total,
    required this.distribution,
    required this.reviews,
  });

  factory ProductReviewsSummary.fromJson(Map<String, dynamic> json) {
    final distRaw = json['distribution'] as Map<String, dynamic>? ?? {};
    final dist = <int, double>{};
    distRaw.forEach((k, v) {
      final ratingStar = int.tryParse(k) ?? 0;
      final percentage = (v as num?)?.toDouble() ?? 0.0;
      if (ratingStar > 0) dist[ratingStar] = percentage;
    });

    final reviewsRaw = json['reviews'] as List? ?? [];
    final reviewsList = reviewsRaw
        .map((r) => ProductReview.fromJson(Map<String, dynamic>.from(r)))
        .toList();

    return ProductReviewsSummary(
      productId: json['productId']?.toString() ?? '',
      average: (json['average'] as num?)?.toDouble() ?? 0.0,
      total: json['total'] as int? ?? 0,
      distribution: dist,
      reviews: reviewsList,
    );
  }
}

class ProductReview {
  final String id;
  final int rating;
  final String comment;
  final String createdAt;
  final String fullName;
  final String avatarUrl;

  ProductReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.fullName,
    required this.avatarUrl,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: json['id']?.toString() ?? '',
      rating: json['rating'] as int? ?? 0,
      comment: json['comment']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'Anonymous',
      avatarUrl: json['avatar_url']?.toString() ?? '',
    );
  }
}

final productReviewsProvider = FutureProvider.family<ProductReviewsSummary, String>((ref, productId) async {
  final resp = await ApiClient.instance.get('/api/products/$productId/reviews');
  return ProductReviewsSummary.fromJson(Map<String, dynamic>.from(resp.data));
});

class AdminReview {
  final String id;
  final String orderId;
  final int rating;
  final String comment;
  final String createdAt;
  final String email;
  final String fullName;
  final String productName;
  final String productImage;

  AdminReview({
    required this.id,
    required this.orderId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.email,
    required this.fullName,
    required this.productName,
    required this.productImage,
  });

  factory AdminReview.fromJson(Map<String, dynamic> json) {
    return AdminReview(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      rating: json['rating'] as int? ?? 0,
      comment: json['comment']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'Anonymous',
      productName: json['product_name']?.toString() ?? '',
      productImage: json['product_image']?.toString() ?? '',
    );
  }
}

final adminReviewsProvider = FutureProvider<List<AdminReview>>((ref) async {
  final resp = await ApiClient.instance.get('/api/admin/reviews');
  final raw = resp.data['reviews'] as List? ?? [];
  return raw.map((j) => AdminReview.fromJson(Map<String, dynamic>.from(j))).toList();
});

final bannerImageProvider = StateNotifierProvider<BannerImageNotifier, String>((ref) {
  return BannerImageNotifier();
});

class BannerImageNotifier extends StateNotifier<String> {
  BannerImageNotifier() : super('https://images.unsplash.com/photo-1483985988355-763728e1935b?q=80&w=1000') {
    loadBanner();
  }

  Future<void> loadBanner() async {
    try {
      final response = await ApiClient.instance.get('/api/settings/homepage_banner_url');
      if (response.statusCode == 200 && response.data != null && response.data['value'] != null) {
        state = response.data['value'] as String;
      }
    } catch (_) {}
  }

  void updateBanner(String newUrl) {
    state = newUrl;
  }
}



