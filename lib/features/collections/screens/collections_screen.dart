import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/product_provider.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../../shared/widgets/zanny_app_bar.dart';

class CollectionsScreen extends ConsumerStatefulWidget {
  const CollectionsScreen({super.key});

  @override
  ConsumerState<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends ConsumerState<CollectionsScreen> {
  String _selectedCategory = 'all'; // 'all' or category slug
  String _sortBy = 'Featured';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _sortApiValue {
    switch (_sortBy) {
      case 'Price: Low to High':
        return 'price_asc';
      case 'Price: High to Low':
        return 'price_desc';
      case 'Newest':
        return 'newest';
      default:
        return 'created_at';
    }
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(productsStateProvider);
    final theme = Theme.of(context);

    // Filter products
    List<Product> products = List.from(allProducts);
    if (_selectedCategory != 'all') {
      if (_selectedCategory == 'new-arrivals') {
        products = products.where((p) => p.isNew).toList();
      } else if (_selectedCategory == 'sale') {
        products = products.where((p) => p.isSale || p.isOnSale).toList();
      } else {
        products = products.where((p) => p.category == _selectedCategory).toList();
      }
    }

    // Search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      products = products
          .where((p) =>
              p.name.toLowerCase().contains(query) ||
              p.description.toLowerCase().contains(query))
          .toList();
    }

    // Sort products
    if (_sortApiValue == 'price_asc') {
      products.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortApiValue == 'price_desc') {
      products.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortApiValue == 'newest') {
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    // Categories list (Prepend "All Products")
    final categories = [
      const ProductCategory(
        slug: 'all',
        name: 'All Products',
        description: 'Browse everything in the shop',
        imageUrl: '',
      ),
      ...ProductCategory.all,
    ];

    // Filter recommended products (highly rated or featured)
    final recommendedProducts = allProducts.where((p) => p.isNew || p.isSale || p.avgRating >= 4.0).take(6).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ZannyAppBar(
        title: 'SHOP',
      ),
      body: Column(
        children: [
          // Search & Sort bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search the collection...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      fillColor: theme.colorScheme.surface,
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showSortSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sort, size: 16, color: theme.colorScheme.secondary),
                        const SizedBox(width: 6),
                        Text(
                          _sortBy,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Category Chips
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _selectedCategory == cat.slug;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(
                      cat.name.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = cat.slug;
                        });
                      }
                    },
                    selectedColor: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.surface,
                    checkmarkColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        width: 0.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Main mixed feed Grid
          Expanded(
            child: allProducts.isEmpty
                ? const ProductGridShimmer()
                : products.isEmpty
                    ? Center(
                        child: Text(
                          'No products found matching your search.',
                          style: GoogleFonts.inter(color: theme.colorScheme.secondary),
                        ),
                      )
                    : CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // Curated / Recommended banner/horizontal list (Only show on 'All' category and no search)
                          if (_selectedCategory == 'all' && _searchController.text.isEmpty)
                            SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                    child: Text(
                                      'RECOMMENDED FOR YOU',
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.5,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 220,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      itemCount: recommendedProducts.length,
                                      itemBuilder: (context, idx) {
                                        final prod = recommendedProducts[idx];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: SizedBox(
                                            width: 140,
                                            child: ProductCard(product: prod),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Divider(height: 24),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                    child: Text(
                                      'EXPLORE ALL PRODUCTS',
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.5,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Mixed Product Grid
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => FadeInSlide(
                                  delay: Duration(milliseconds: 30 * index),
                                  child: ProductCard(product: products[index]),
                                ),
                                childCount: products.length,
                              ),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.65,
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 3,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              'SORT BY',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          Divider(color: Theme.of(context).colorScheme.outline),
          for (final option in ['Featured', 'Price: Low to High', 'Price: High to Low', 'Newest'])
            ListTile(
              title: Text(option, style: GoogleFonts.inter(fontSize: 14)),
              trailing: _sortBy == option
                  ? const Icon(Icons.check, size: 18)
                  : null,
              onTap: () {
                setState(() => _sortBy = option);
                Navigator.pop(context);
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
