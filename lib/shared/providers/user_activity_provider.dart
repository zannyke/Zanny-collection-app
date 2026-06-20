import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'product_provider.dart';

class UserActivity {
  final List<String> searchedTerms;
  final List<String> viewedProductIds;

  const UserActivity({
    required this.searchedTerms,
    required this.viewedProductIds,
  });

  UserActivity copyWith({
    List<String>? searchedTerms,
    List<String>? viewedProductIds,
  }) {
    return UserActivity(
      searchedTerms: searchedTerms ?? this.searchedTerms,
      viewedProductIds: viewedProductIds ?? this.viewedProductIds,
    );
  }
}

class UserActivityNotifier extends Notifier<UserActivity> {
  static const _storageKey = 'cached_user_activity';

  @override
  UserActivity build() {
    _loadActivity();
    return const UserActivity(searchedTerms: [], viewedProductIds: []);
  }

  Future<void> _loadActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final decoded = jsonDecode(jsonStr);
        state = UserActivity(
          searchedTerms: List<String>.from(decoded['searched_terms'] ?? []),
          viewedProductIds: List<String>.from(decoded['viewed_product_ids'] ?? []),
        );
      }
    } catch (_) {}
  }

  Future<void> _saveActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'searched_terms': state.searchedTerms,
        'viewed_product_ids': state.viewedProductIds,
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> recordSearch(String query) async {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return;

    final updated = List<String>.from(state.searchedTerms)..remove(term);
    updated.insert(0, term); // Place newest at front
    if (updated.length > 10) updated.removeLast(); // Cap size

    state = state.copyWith(searchedTerms: updated);
    await _saveActivity();
  }

  Future<void> recordProductView(String productId) async {
    if (productId.isEmpty) return;

    final updated = List<String>.from(state.viewedProductIds)..remove(productId);
    updated.insert(0, productId); // Place newest at front
    if (updated.length > 20) updated.removeLast(); // Cap size

    state = state.copyWith(viewedProductIds: updated);
    await _saveActivity();
  }
}

final userActivityProvider = NotifierProvider<UserActivityNotifier, UserActivity>(UserActivityNotifier.new);

/// Provider to get smart personalized recommendations for a product
final recommendedProductsProvider = FutureProvider.family<List<Product>, (String currentProductId, String categorySlug)>((ref, args) async {
  final currentId = args.$1;
  final currentCat = args.$2;

  final activity = ref.watch(userActivityProvider);
  final repo = ref.read(productRepositoryProvider);

  // Load all active products (fetched via Cloudflare Worker API, local cache used if offline)
  final allProductsInCat = await repo.fetchByCategory(currentCat);
  final allProducts = await repo.fetchAll(); // Load all cached items or fallback list
  final activeCatalog = allProducts.isEmpty ? List<Product>.from(Product.defaultMockProducts) : allProducts;

  final recommended = <Product>[];

  // 1. Find products in activeCatalog that match previously searched terms
  if (activity.searchedTerms.isNotEmpty) {
    for (final product in activeCatalog) {
      if (product.id == currentId) continue;
      for (final term in activity.searchedTerms) {
        if (product.name.toLowerCase().contains(term) || product.description.toLowerCase().contains(term)) {
          if (!recommended.contains(product)) {
            recommended.add(product);
          }
        }
      }
    }
  }

  // 2. Find products in categories of viewed products
  if (activity.viewedProductIds.isNotEmpty) {
    final viewedCats = <String>{};
    for (final id in activity.viewedProductIds) {
      final match = activeCatalog.firstWhere((p) => p.id == id, orElse: () => const Product(id: '', name: '', subtitle: '', description: '', price: 0, images: [], colors: [], sizes: [], category: ''));
      if (match.category.isNotEmpty) {
        viewedCats.add(match.category);
      }
    }
    
    for (final product in activeCatalog) {
      if (product.id == currentId) continue;
      if (viewedCats.contains(product.category) && !recommended.contains(product)) {
        recommended.add(product);
      }
    }
  }

  // 3. Fill the remaining spots with same-category products
  for (final product in allProductsInCat) {
    if (product.id == currentId) continue;
    if (!recommended.contains(product)) {
      recommended.add(product);
    }
  }

  // Fallback: If recommended is empty, just fill from general mock catalog
  if (recommended.isEmpty) {
    recommended.addAll(activeCatalog.where((p) => p.id != currentId));
  }

  // Limit to 6 items and return
  return recommended.take(6).toList();
});
