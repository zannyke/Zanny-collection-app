import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/models.dart';

import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/animations.dart';

class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'COLLECTIONS',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => context.push('/cart'),
          ),
          const SizedBox(width: 4),
        ],
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

class _BigCategoryCard extends StatelessWidget {
  final ProductCategory category;
  const _BigCategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return FadeInSlide(
      child: TactileButton(
        onTap: () => context.push('/collections/${category.slug}'),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: AppColors.surfaceElevated,
                child: category.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: category.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: ZannyLoadingIndicator(
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.image_outlined,
                              color: AppColors.textMuted, size: 32),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image_outlined,
                            color: AppColors.textMuted, size: 36),
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Explore →',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),);
  }
}
