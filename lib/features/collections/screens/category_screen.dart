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


class CategoryScreen extends ConsumerStatefulWidget {
  final String slug;
  const CategoryScreen({super.key, required this.slug});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  String _sortBy = 'Featured';
  final _searchController = TextEditingController();

  ProductCategory get category =>
      ProductCategory.all.firstWhere((c) => c.slug == widget.slug,
          orElse: () => ProductCategory.all.first);

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
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(categoryProductsProvider((widget.slug, _sortApiValue)));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: ZannyAppBar(
        title: category.name,
        showBack: true,
      ),
      body: Column(
        children: [
          // Search + Sort bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showSortSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sort, size: 16, color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 6),
                        Text(
                          _sortBy,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Product Grid Content
          Expanded(
            child: productsAsync.when(
              loading: () => const ProductGridShimmer(),
              error: (err, stack) => Center(
                child: Text(
                  'Error loading products: $err',
                  style: GoogleFonts.inter(color: AppColors.error),
                ),
              ),
              data: (products) {
                final filteredProducts = _searchController.text.isEmpty
                    ? products
                    : products
                        .where((p) =>
                            p.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                            p.description.toLowerCase().contains(_searchController.text.toLowerCase()))
                        .toList();

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Text(
                      'No products found.',
                      style: GoogleFonts.inter(color: AppColors.textSecondary),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Results count
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text(
                        '${filteredProducts.length} Products',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Grid
                    Expanded(
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) => FadeInSlide(
                          delay: Duration(milliseconds: 50 * index),
                          child: ProductCard(product: filteredProducts[index]),
                        ),
                      ),
                    ),
                  ],
                );
              },
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
