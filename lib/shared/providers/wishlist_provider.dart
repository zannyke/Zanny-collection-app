import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/cloudflare/api_client.dart';
import '../models/models.dart';
import 'auth_provider.dart';

// ── Wishlist Notifier ─────────────────────────────────────────────────────────

class WishlistNotifier extends AsyncNotifier<List<Product>> {
  final ApiClient _api = ApiClient.instance;

  @override
  Future<List<Product>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return _fetchFromServer();
  }

  Future<List<Product>> _fetchFromServer() async {
    try {
      final resp = await _api.get('/api/wishlist');
      final raw = resp.data['products'] as List? ?? [];
      return raw.map((j) => Product.fromJson(Map<String, dynamic>.from(j as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> toggle(Product product) async {
    final current = state.valueOrNull ?? [];
    final isWishlisted = current.any((p) => p.id == product.id);

    if (isWishlisted) {
      // Optimistic remove
      state = AsyncData(current.where((p) => p.id != product.id).toList());
      try {
        await _api.delete('/api/wishlist/${product.id}');
      } on DioException catch (_) {
        // Rollback on failure
        state = AsyncData([...current]);
      }
    } else {
      // Optimistic add
      state = AsyncData([...current, product]);
      try {
        await _api.post('/api/wishlist', data: {'product_id': product.id});
      } on DioException catch (_) {
        // Rollback on failure
        state = AsyncData(current);
      }
    }
  }

  bool isWishlisted(String productId) {
    return state.valueOrNull?.any((p) => p.id == productId) ?? false;
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final wishlistProvider = AsyncNotifierProvider<WishlistNotifier, List<Product>>(
  WishlistNotifier.new,
);

final wishlistCountProvider = Provider<int>((ref) {
  return ref.watch(wishlistProvider).valueOrNull?.length ?? 0;
});

final isWishlistedProvider = Provider.family<bool, String>((ref, productId) {
  final wishlist = ref.watch(wishlistProvider).valueOrNull ?? [];
  return wishlist.any((p) => p.id == productId);
});
