import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

// ────────────────────────────────────────────────
// Cart Provider
// ────────────────────────────────────────────────
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addItem(Product product, String color, String size, int qty) {
    final key = '${product.id}_${color}_$size';
    final existing = state.indexWhere((i) => i.key == key);
    if (existing >= 0) {
      final updated = List<CartItem>.from(state);
      updated[existing].quantity += qty;
      state = updated;
    } else {
      state = [...state, CartItem(product: product, selectedColor: color, selectedSize: size, quantity: qty)];
    }
  }

  void removeItem(String key) {
    state = state.where((i) => i.key != key).toList();
  }

  void updateQuantity(String key, int qty) {
    if (qty <= 0) {
      removeItem(key);
      return;
    }
    state = state.map((i) => i.key == key ? (i..quantity = qty) : i).toList();
  }

  void clear() => state = [];
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, item) => sum + item.quantity);
});

final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).fold(0.0, (sum, item) => sum + item.subtotal);
});

// ────────────────────────────────────────────────
// Wishlist Provider
// ────────────────────────────────────────────────
class WishlistNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String productId) {
    if (state.contains(productId)) {
      state = Set.from(state)..remove(productId);
    } else {
      state = Set.from(state)..add(productId);
    }
  }

  bool isWishlisted(String productId) => state.contains(productId);
}

final wishlistProvider = NotifierProvider<WishlistNotifier, Set<String>>(WishlistNotifier.new);
