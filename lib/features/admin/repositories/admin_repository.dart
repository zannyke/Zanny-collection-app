import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/cloudflare/api_client.dart';
import '../../../core/cloudflare/cloudflare_config.dart';
import '../../../shared/models/models.dart';

class AdminRepository {
  final ApiClient _api = ApiClient.instance;

  static const String _productsKey = 'cached_mock_products';

  static Future<void> _saveMockProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _mockAdminProducts.map((p) => p.toJson()).toList();
      await prefs.setString(_productsKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  static Future<void> loadMockProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_productsKey);
      if (jsonString != null) {
        final List decoded = jsonDecode(jsonString);
        final products = decoded
            .map((json) => Product.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        _mockAdminProducts.clear();
        _mockAdminProducts.addAll(products);
      } else {
        await _saveMockProducts();
      }
    } catch (_) {}
  }

  /// Fetch all products for the admin panel (includes active and inactive).
  Future<List<Product>> fetchAllProducts() async {
    try {
      final resp = await _api.get('/api/products', queryParameters: {'limit': '500'});
      final raw = resp.data['products'] as List? ?? [];
      return raw
          .map((j) => Product.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
    } catch (_) {
      await loadMockProducts();
      return _mockAdminProducts;
    }
  }

  /// Create a new product via Cloudflare Worker.
  Future<Product> insertProduct({
    required String name,
    required String subtitle,
    required String description,
    required double price,
    double? originalPrice,
    required List<String> images,
    required List<String> colors,
    required List<String> sizes,
    required String categorySlug,
    required int stock,
    bool isNew = false,
    bool isSale = false,
  }) async {
    try {
      final resp = await _api.post('/api/products', data: {
        'name': name,
        'subtitle': subtitle,
        'description': description,
        'price': price,
        'original_price': originalPrice,
        'images': images,
        'colors': colors,
        'sizes': sizes,
        'category_slug': categorySlug,
        'is_new': isNew,
        'is_sale': isSale,
        'is_active': true,
        'stock': stock,
      });
      return Product.fromJson(
          Map<String, dynamic>.from(resp.data['product'] as Map));
    } catch (_) {
      // Optimistic local fallback
      final newProduct = Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        subtitle: subtitle,
        description: description,
        price: price,
        originalPrice: originalPrice,
        images: images.isNotEmpty
            ? images
            : ['${CloudflareConfig.r2PublicUrl}/placeholder.jpg'],
        colors: colors,
        sizes: sizes,
        category: categorySlug,
        isNew: isNew,
        isSale: isSale,
        stock: stock,
      );
      _mockAdminProducts.insert(0, newProduct);
      await _saveMockProducts();
      return newProduct;
    }
  }

  /// Upload an image to Cloudflare R2 via multipart and return its public URL.
  Future<String> uploadProductImage(File file) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName = 'products/${DateTime.now().microsecondsSinceEpoch}.$fileExt';

      // Upload directly to R2 via Worker proxy endpoint
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        'key': fileName,
      });

      final resp = await _api.post('/api/upload', data: formData);
      final key = resp.data['key'] as String? ?? fileName;
      return '${CloudflareConfig.r2PublicUrl}/$key';
    } catch (_) {
      // Fallback placeholder from R2 public bucket
      return '${CloudflareConfig.r2PublicUrl}/placeholder.jpg';
    }
  }

  /// Toggle product active status (soft delete/hide).
  Future<void> toggleProductActiveStatus(String productId, bool isActive) async {
    try {
      await _api.put('/api/products/$productId', data: {'is_active': isActive});
    } catch (_) {
      final index = _mockAdminProducts.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final p = _mockAdminProducts[index];
        _mockAdminProducts[index] = Product(
          id: p.id, name: p.name, subtitle: p.subtitle,
          description: p.description, price: p.price,
          originalPrice: p.originalPrice, images: p.images,
          colors: p.colors, sizes: p.sizes, category: p.category,
          isNew: p.isNew, isSale: p.isSale, stock: p.stock,
        );
      }
    }
  }

  /// Delete product via Worker API.
  Future<void> deleteProduct(String productId) async {
    try {
      await _api.delete('/api/products/$productId');
      _mockAdminProducts.removeWhere((p) => p.id == productId);
    } catch (_) {
      _mockAdminProducts.removeWhere((p) => p.id == productId);
      await _saveMockProducts();
    }
  }

  static final List<Product> _mockAdminProducts =
      List.from(Product.defaultMockProducts);
}

// ── Providers ─────────────────────────────────────────────────────────────────

final adminRepositoryProvider =
    Provider<AdminRepository>((_) => AdminRepository());

final adminProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.fetchAllProducts();
});
