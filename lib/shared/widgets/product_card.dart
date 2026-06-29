import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../../core/theme/app_colors.dart';
import '../providers/wishlist_provider.dart';
import '../providers/auth_provider.dart';
import 'animations.dart';
import 'shimmer_widgets.dart';

class ProductCard extends ConsumerWidget {
  final Product product;
  final Widget? trailing; // Slot for buttons like wishlist toggle
  
  const ProductCard({
    super.key,
    required this.product,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return FadeInSlide(
      child: TactileButton(
        onTap: () => context.push('/product/${product.id}'),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outline, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: isLight ? Colors.black.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image area
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: theme.colorScheme.surface,
                        child: product.images.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: product.images.first,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const ShimmerBox(
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                                errorWidget: (context, url, error) => Center(
                                  child: Icon(Icons.image_outlined,
                                      color: theme.colorScheme.secondary, size: 28),
                                ),
                              )
                            : Center(
                                child: Icon(Icons.image_outlined,
                                    color: theme.colorScheme.secondary, size: 28),
                              ),
                      ),
                      
                      // Badges
                      if (product.isNew)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'NEW',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      if (product.isSale)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.sale,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'SALE',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        
                      // Trailing action slot (e.g. wishlist toggle)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: trailing ?? _DefaultWishlistButton(product: product),
                      ),
                    ],
                  ),
                ),
                
                // Product info
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'KES ${product.price.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (product.isOnSale) ...[
                            const SizedBox(width: 6),
                            Text(
                              'KES ${product.originalPrice!.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: theme.colorScheme.secondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Star rating row
                      if (product.reviewCount > 0) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            ...List.generate(5, (i) {
                              final filled = i < product.avgRating.floor();
                              final half = !filled && i < product.avgRating;
                              return Icon(
                                filled ? Icons.star : (half ? Icons.star_half : Icons.star_border),
                                size: 11,
                                color: filled || half ? const Color(0xFFFFC107) : theme.colorScheme.outline,
                              );
                            }),
                            const SizedBox(width: 4),
                            Text(
                              '(${product.reviewCount})',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
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

class _DefaultWishlistButton extends ConsumerWidget {
  final Product product;
  const _DefaultWishlistButton({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWish = ref.watch(isWishlistedProvider(product.id));
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isLight ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.7),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IconButton(
        iconSize: 16,
        padding: EdgeInsets.zero,
        icon: Icon(
          isWish ? Icons.favorite : Icons.favorite_border,
          color: isWish ? Colors.red : (isLight ? Colors.black87 : Colors.white70),
        ),
        onPressed: () {
          if (user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please sign in to save items to your wishlist')),
            );
            return;
          }
          ref.read(wishlistProvider.notifier).toggle(product);
        },
      ),
    );
  }
}
