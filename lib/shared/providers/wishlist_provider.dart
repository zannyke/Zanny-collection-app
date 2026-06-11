import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_config.dart';
import '../models/models.dart';
import 'auth_provider.dart';
import 'product_provider.dart';

// ── Wishlist Notifier ─────────────────────────────────────────────────────────

class WishlistNotifier extends AsyncNotifier<List<Product>> {
  SupabaseClient get _client => SupabaseConfig.client;

  static final List<Product> _mockWishlist = [];

  @override
  Future<List<Product>> build() async {
    if (!SupabaseConfig.isConfigured) {
      return List.from(_mockWishlist);
    }
    final userId = ref.watch(currentUserProvider)?.id;
    if (userId == null) return [];
    try {
      return await _fetchWishlist(userId);
    } catch (e) {
      print('⚠️ Supabase error in wishlist build: $e. Falling back to local wishlist.');
      return List.from(_mockWishlist);
    }
  }

  Future<List<Product>> _fetchWishlist(String userId) async {
    final data = await _client
        .from('wishlists')
        .select('product_id, products(*)')
        .eq('user_id', userId);

    final repo = ref.read(productRepositoryProvider);
    return (data as List)
        .where((row) => row['products'] != null)
        .map((row) => Product.fromJson(
              Map<String, dynamic>.from(row['products'] as Map)
                ..['images'] = _parseList(row['products']['images'])
                ..['colors'] = _parseList(row['products']['colors'])
                ..['sizes']  = _parseList(row['products']['sizes']),
            ))
        .toList();
  }

  List<String> _parseList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }

  /// Toggle wishlist — add if not present, remove if present
  Future<void> toggle(Product product) async {
    final current = state.valueOrNull ?? [];
    final isWishlisted = current.any((p) => p.id == product.id);

    if (!SupabaseConfig.isConfigured) {
      if (isWishlisted) {
        _mockWishlist.removeWhere((p) => p.id == product.id);
      } else {
        _mockWishlist.add(product);
      }
      state = AsyncData(List.from(_mockWishlist));
      return;
    }

    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) return;

    if (isWishlisted) {
      // Optimistic remove
      state = AsyncData(current.where((p) => p.id != product.id).toList());
      try {
        await _client
            .from('wishlists')
            .delete()
            .eq('user_id', userId)
            .eq('product_id', product.id);
      } catch (e) {
        print('⚠️ Supabase error in wishlist toggle delete: $e');
      }
    } else {
      // Optimistic add
      state = AsyncData([...current, product]);
      try {
        await _client.from('wishlists').upsert({
          'user_id': userId,
          'product_id': product.id,
        });
      } catch (e) {
        print('⚠️ Supabase error in wishlist toggle upsert: $e');
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
