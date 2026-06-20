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
    return Product.defaultMockProducts; // Show mock while loading
  }

  Future<void> _load() async {
    try {
      final products = await _repo.fetchAll();
      if (products.isNotEmpty) state = products;
    } catch (_) {}
  }

  Future<void> refresh() => _load();

  Future<void> addProduct(Product product, {bool sendPush = false, String? pushBody}) async {
    try {
      final data = product.toJson();
      if (sendPush) {
        data['send_push'] = true;
        if (pushBody != null && pushBody.isNotEmpty) {
          data['push_body'] = pushBody;
        }
      }
      await ApiClient.instance.post('/api/products', data: data);
      await _load();
    } catch (_) {
      state = [product, ...state];
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await ApiClient.instance.put('/api/products/${product.id}', data: product.toJson());
      await _load();
    } catch (_) {
      state = state.map((p) => p.id == product.id ? product : p).toList();
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await ApiClient.instance.delete('/api/products/$id');
      state = state.where((p) => p.id != id).toList();
    } catch (_) {
      state = state.where((p) => p.id != id).toList();
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
  return list.where((p) => p.id == id).firstOrNull ??
      (list.isNotEmpty ? list.first : null);
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
