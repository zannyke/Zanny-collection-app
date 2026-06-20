import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/models/models.dart';
import '../../../shared/providers/product_provider.dart';

import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/zanny_app_bar.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const ZannyAppBar(
        title: 'Collections',
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = ProductCategory.all[index];
                  return _BigCategoryCard(category: category);
                },
                childCount: ProductCategory.all.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigCategoryCard extends ConsumerWidget {
  final ProductCategory category;
  const _BigCategoryCard({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsStateProvider);
    
    // Resolve dynamic category image from the latest product in this category
    String? coverImage;
    if (category.slug == 'sale') {
      final saleProduct = products.where((p) => p.isSale || p.isOnSale).firstOrNull;
      if (saleProduct != null && saleProduct.images.isNotEmpty) {
        coverImage = saleProduct.images.first;
      }
    } else if (category.slug == 'new-arrivals') {
      final newProduct = products.where((p) => p.isNew).firstOrNull;
      if (newProduct != null && newProduct.images.isNotEmpty) {
        coverImage = newProduct.images.first;
      }
    } else {
      final catProduct = products.where((p) => p.category == category.slug).firstOrNull;
      if (catProduct != null && catProduct.images.isNotEmpty) {
        coverImage = catProduct.images.first;
      }
    }

    final imageUrl = (coverImage != null && coverImage.isNotEmpty) ? coverImage : category.imageUrl;

    return FadeInSlide(
      child: TactileButton(
        onTap: () => context.push('/collections/${category.slug}'),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).colorScheme.outline, width: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: ZannyLoadingIndicator(
                                size: 20,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Icon(Icons.image_outlined,
                                  color: Theme.of(context).colorScheme.secondary, size: 32),
                            ),
                          )
                        : Center(
                            child: Icon(Icons.image_outlined,
                                color: Theme.of(context).colorScheme.secondary, size: 36),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Explore →',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
