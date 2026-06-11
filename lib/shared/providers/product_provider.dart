import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_config.dart';
import '../models/models.dart';

// ── Product Repository ────────────────────────────────────────────────────────

// ── Product Repository ────────────────────────────────────────────────────────

class ProductRepository {
  final SupabaseClient _client;
  ProductRepository(this._client);

  bool get _useMock => !SupabaseConfig.isConfigured;

  /// Fetch all products for a category slug
  Future<List<Product>> fetchByCategory(String slug, {String sort = 'created_at'}) async {
    if (_useMock) {
      return _getMockByCategory(slug, sort);
    }
    try {
      final baseQuery = _client
          .from('products')
          .select()
          .eq('category_slug', slug)
          .eq('is_active', true);

      PostgrestTransformBuilder<PostgrestList> query;
      // Apply sort
      switch (sort) {
        case 'price_asc':
          query = baseQuery.order('price', ascending: true);
        case 'price_desc':
          query = baseQuery.order('price', ascending: false);
        case 'newest':
          query = baseQuery.order('created_at', ascending: false);
        default:
          query = baseQuery.order('is_new', ascending: false);
      }

      final data = await query;
      return (data as List).map((json) => Product.fromJson(_parseJson(json))).toList();
    } catch (e) {
      print('⚠️ Supabase error in fetchByCategory, falling back to mock: $e');
      return _getMockByCategory(slug, sort);
    }
  }

  /// Fetch new arrivals
  Future<List<Product>> fetchNewArrivals({int limit = 8}) async {
    if (_useMock) {
      return _mockProducts.where((p) => p.isNew).take(limit).toList();
    }
    try {
      final data = await _client
          .from('products')
          .select()
          .eq('is_new', true)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(limit);
      return (data as List).map((json) => Product.fromJson(_parseJson(json))).toList();
    } catch (e) {
      print('⚠️ Supabase error in fetchNewArrivals, falling back to mock: $e');
      return _mockProducts.where((p) => p.isNew).take(limit).toList();
    }
  }

  /// Fetch sale products
  Future<List<Product>> fetchSale({int limit = 20}) async {
    if (_useMock) {
      return _mockProducts.where((p) => p.isSale).take(limit).toList();
    }
    try {
      final data = await _client
          .from('products')
          .select()
          .eq('is_sale', true)
          .eq('is_active', true)
          .order('price', ascending: true)
          .limit(limit);
      return (data as List).map((json) => Product.fromJson(_parseJson(json))).toList();
    } catch (e) {
      print('⚠️ Supabase error in fetchSale, falling back to mock: $e');
      return _mockProducts.where((p) => p.isSale).take(limit).toList();
    }
  }

  /// Fetch a single product by ID
  Future<Product?> fetchById(String id) async {
    if (_useMock) {
      return _mockProducts.firstWhere((p) => p.id == id, orElse: () => _mockProducts.first);
    }
    try {
      final data = await _client
          .from('products')
          .select()
          .eq('id', id)
          .eq('is_active', true)
          .maybeSingle();
      if (data == null) return null;
      return Product.fromJson(_parseJson(data));
    } catch (e) {
      print('⚠️ Supabase error in fetchById, falling back to mock: $e');
      return _mockProducts.firstWhere((p) => p.id == id, orElse: () => _mockProducts.first);
    }
  }

  /// Full-text search across products
  Future<List<Product>> search(String query) async {
    if (query.isEmpty) return [];
    if (_useMock) {
      final q = query.toLowerCase();
      return _mockProducts
          .where((p) => p.name.toLowerCase().contains(q) || p.description.toLowerCase().contains(q))
          .toList();
    }
    try {
      final data = await _client
          .from('products')
          .select()
          .eq('is_active', true)
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .limit(30);
      return (data as List).map((json) => Product.fromJson(_parseJson(json))).toList();
    } catch (e) {
      print('⚠️ Supabase error in search, falling back to mock: $e');
      final q = query.toLowerCase();
      return _mockProducts
          .where((p) => p.name.toLowerCase().contains(q) || p.description.toLowerCase().contains(q))
          .toList();
    }
  }

  /// Fetch related products (same category, exclude current)
  Future<List<Product>> fetchRelated(String categorySlug, String excludeId, {int limit = 6}) async {
    if (_useMock) {
      return _mockProducts
          .where((p) => p.category == categorySlug && p.id != excludeId)
          .take(limit)
          .toList();
    }
    try {
      final data = await _client
          .from('products')
          .select()
          .eq('category_slug', categorySlug)
          .eq('is_active', true)
          .neq('id', excludeId)
          .limit(limit);
      return (data as List).map((json) => Product.fromJson(_parseJson(json))).toList();
    } catch (e) {
      print('⚠️ Supabase error in fetchRelated, falling back to mock: $e');
      return _mockProducts
          .where((p) => p.category == categorySlug && p.id != excludeId)
          .take(limit)
          .toList();
    }
  }

  List<Product> _getMockByCategory(String slug, String sort) {
    List<Product> list;
    if (slug == 'sale') {
      list = _mockProducts.where((p) => p.isSale).toList();
    } else if (slug == 'new-arrivals') {
      list = _mockProducts.where((p) => p.isNew).toList();
    } else {
      list = _mockProducts.where((p) => p.category == slug).toList();
    }

    // Apply sort
    if (sort == 'price_asc') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (sort == 'price_desc') {
      list.sort((a, b) => b.price.compareTo(a.price));
    }
    return list;
  }

  Map<String, dynamic> _parseJson(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);
    // Parse jsonb arrays back to Dart lists
    map['images'] = _parseList(map['images']);
    map['colors'] = _parseList(map['colors']);
    map['sizes']  = _parseList(map['sizes']);
    return map;
  }

  List<String> _parseList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  // ── Premium Mock Products Catalog ──────────────────────────────────────────
  static final List<Product> _mockProducts = [
    // New Arrivals / Tee
    const Product(
      id: 'new_1',
      name: 'Oversized ZC Heavyweight Hoodie',
      subtitle: 'New Season',
      description: 'The ultimate streetwear statement. Crafted from 450GSM organic loopback cotton, this hoodie features dropped shoulders, double-lined hood without drawcords, and custom silicone-injected chest branding.',
      price: 3800,
      originalPrice: 4500,
      images: ['https://images.unsplash.com/photo-1556821840-3a63f95609a7?q=80&w=600'],
      colors: ['Charcoal Black', 'Heather Grey', 'Olive Green'],
      sizes: ['S', 'M', 'L', 'XL', 'XXL'],
      category: 'hoodies',
      isNew: true,
      isSale: true,
    ),
    const Product(
      id: 'new_2',
      name: 'ZC Vibe Box Graphic Tee',
      subtitle: 'New Season',
      description: 'Ultra-premium vintage wash jersey tee. 240GSM combed cotton, oversized retro silhouette with high collar rib. High-density puff print graphic at the front.',
      price: 1800,
      originalPrice: null,
      images: ['https://images.unsplash.com/photo-1521572267360-ee0c2909d518?q=80&w=600'],
      colors: ['Vintage Black', 'Off-White', 'Muted Red'],
      sizes: ['S', 'M', 'L', 'XL'],
      category: 'shirts-t-shirts',
      isNew: true,
    ),
    const Product(
      id: 'new_3',
      name: 'ZC Utility Cargo Sweatpants',
      subtitle: 'New Season',
      description: 'Fleece-lined utility joggers with signature double-pockets at sides. Elastic waistband and cuffs with internal drawstring. Minimalist brand embroidery.',
      price: 2900,
      originalPrice: 3200,
      images: ['https://images.unsplash.com/photo-1551854838-212c50b4c184?q=80&w=600'],
      colors: ['Black', 'Sand', 'Stone Grey'],
      sizes: ['M', 'L', 'XL'],
      category: 'shorts-sweatpants',
      isNew: true,
      isSale: true,
    ),

    // Shirts & T-Shirts
    const Product(
      id: 'tee_1',
      name: 'ZC Signature Minimalist Tee',
      subtitle: 'Essential Collection',
      description: 'Our classic everyday heavyweight tee. Features a premium boxy fit, tight crewneck collar, and subtle tonal branding.',
      price: 1500,
      originalPrice: null,
      images: ['https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?q=80&w=600'],
      colors: ['Black', 'White', 'Beige', 'Navy'],
      sizes: ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
      category: 'shirts-t-shirts',
    ),
    const Product(
      id: 'tee_2',
      name: 'ZC Oversized Waffle Knit Shirt',
      subtitle: 'Summer Drops',
      description: 'Relaxed button-up shirt in premium waffle textured cotton. Perfect lightweight outer layer for warm afternoons.',
      price: 2400,
      originalPrice: 2800,
      images: ['https://images.unsplash.com/photo-1596755094514-f87e34085b2c?q=80&w=600'],
      colors: ['Cream', 'Olive', 'Charcoal'],
      sizes: ['S', 'M', 'L', 'XL'],
      category: 'shirts-t-shirts',
      isSale: true,
    ),

    // Hoodies
    const Product(
      id: 'hoodie_1',
      name: 'ZC Street Culture Pullover',
      subtitle: 'Streetwear Essentials',
      description: 'Heavy fleece core hoodie with kangaroo pocket and embroidered street crest. Relaxed boxy fit.',
      price: 3200,
      originalPrice: null,
      images: ['https://images.unsplash.com/photo-1543163521-1bf539c55dd2?q=80&w=600'],
      colors: ['Core Black', 'Cream White', 'Mocha'],
      sizes: ['S', 'M', 'L', 'XL', 'XXL'],
      category: 'hoodies',
    ),

    // Sweaters
    const Product(
      id: 'sweater_1',
      name: 'ZC Cable-Knit Chunky Sweater',
      subtitle: 'Premium Knits',
      description: 'Thick and warm cable-knit sweater made from premium wool blend. Clean minimalist ribbed hem.',
      price: 2800,
      originalPrice: 3500,
      images: ['https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?q=80&w=600'],
      colors: ['Off-White', 'Sage Green', 'Navy Blue'],
      sizes: ['S', 'M', 'L', 'XL'],
      category: 'sweaters',
      isSale: true,
    ),

    // Shorts & Sweatpants
    const Product(
      id: 'short_1',
      name: 'ZC Fleece Comfort Shorts',
      subtitle: 'Casual Lounge',
      description: 'Heavy fleece shorts with zipper pockets and embroidered Z logo. Designed for everyday premium comfort.',
      price: 1800,
      originalPrice: null,
      images: ['https://images.unsplash.com/photo-1591195853828-11db59a44f6b?q=80&w=600'],
      colors: ['Black', 'Heather Grey', 'Sage'],
      sizes: ['S', 'M', 'L', 'XL'],
      category: 'shorts-sweatpants',
    ),

    // Shoes
    const Product(
      id: 'shoe_1',
      name: 'ZC Urban Runner Sneaker',
      subtitle: 'Street Footwear',
      description: 'Premium calfskin leather sneakers with custom chunky lightweight sole and orthotic memory insole.',
      price: 4800,
      originalPrice: 6000,
      images: ['https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=600'],
      colors: ['Triple Black', 'Mono White', 'Vintage Cream'],
      sizes: ['40', '41', '42', '43', '44'],
      category: 'shoes',
      isSale: true,
    ),

    // Innerwear
    const Product(
      id: 'inner_1',
      name: 'ZC Bamboo Boxer Briefs (3-Pack)',
      subtitle: 'Essentials',
      description: 'Super-soft and breathable bamboo fiber boxer briefs. Seamless design with anti-roll waistband.',
      price: 1500,
      originalPrice: null,
      images: ['https://images.unsplash.com/photo-1562157873-818bc0726f68?q=80&w=600'],
      colors: ['Multi-pack (Black/Grey/Navy)'],
      sizes: ['M', 'L', 'XL'],
      category: 'innerwear',
    ),

    // Accessories
    const Product(
      id: 'acc_1',
      name: 'ZC Signature Trucker Cap',
      subtitle: 'Headwear',
      description: 'Curved visor trucker hat with high-density foam front panel, mesh back, and snapback adjustment.',
      price: 1200,
      originalPrice: null,
      images: ['https://images.unsplash.com/photo-1588850561407-ed78c282e89b?q=80&w=600'],
      colors: ['Black/White', 'All Black', 'Brown/Beige'],
      sizes: ['One Size'],
      category: 'accessories',
    ),
  ];
}

// ── Providers ─────────────────────────────────────────────────────────────────

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(SupabaseConfig.client);
});

/// Fetch products by category
final categoryProductsProvider = FutureProvider.family<List<Product>, (String slug, String sort)>((ref, args) async {
  final repo = ref.read(productRepositoryProvider);
  return repo.fetchByCategory(args.$1, sort: args.$2);
});

/// Fetch new arrivals
final newArrivalsProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.read(productRepositoryProvider);
  return repo.fetchNewArrivals();
});

/// Search results
final searchResultsProvider = FutureProvider.family<List<Product>, String>((ref, query) async {
  final repo = ref.read(productRepositoryProvider);
  return repo.search(query);
});

/// Single product
final productDetailProvider = FutureProvider.family<Product?, String>((ref, id) async {
  final repo = ref.read(productRepositoryProvider);
  return repo.fetchById(id);
});

/// Related products
final relatedProductsProvider = FutureProvider.family<List<Product>, (String categorySlug, String excludeId)>((ref, args) async {
  final repo = ref.read(productRepositoryProvider);
  return repo.fetchRelated(args.$1, args.$2);
});
