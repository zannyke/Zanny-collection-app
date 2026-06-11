import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/wishlist_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/animations.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.watch(isSignedInProvider);

    if (!isSignedIn) {
      return _SignInPrompt();
    }

    final wishlistAsync = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('WISHLIST', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 3)),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => context.push('/cart'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: wishlistAsync.when(
        loading: () => const ProductGridShimmer(),
        error: (e, _) => _ErrorState(error: e.toString()),
        data: (products) => products.isEmpty
            ? _EmptyWishlist()
            : _WishlistGrid(products: products),
      ),
    );
  }
}

// ── Wishlist Product Grid ──────────────────────────────────────────────────────
class _WishlistGrid extends ConsumerWidget {
  final List<Product> products;
  const _WishlistGrid({required this.products});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text(
                  '${products.length} ${products.length == 1 ? 'item' : 'items'} saved',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _WishlistCard(product: products[index]),
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
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ── Single Wishlist Card ───────────────────────────────────────────────────────
class _WishlistCard extends ConsumerWidget {
  final Product product;
  const _WishlistCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FadeInSlide(
      child: TactileButton(
        onTap: () => context.push('/product/${product.id}'),
        child: Container(
          color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with remove button
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.images.first,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: ZannyLoadingIndicator(
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(Icons.image_outlined, color: AppColors.textMuted, size: 32),
                          ),
                        )
                      : Container(
                          color: AppColors.surfaceElevated,
                          child: const Center(
                            child: Icon(Icons.image_outlined, color: AppColors.textMuted, size: 32),
                          ),
                        ),
                  // Remove from wishlist button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => ref.read(wishlistProvider.notifier).toggle(product),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite, size: 16, color: AppColors.sale),
                      ),
                    ),
                  ),
                  // NEW badge
                  if (product.isNew)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        color: AppColors.textPrimary,
                        child: Text('NEW',
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800,
                                letterSpacing: 1, color: AppColors.background)),
                      ),
                    ),
                ],
              ),
            ),
            // Product info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('KES ${product.price.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      if (product.isOnSale) ...[
                        const SizedBox(width: 6),
                        Text('KES ${product.originalPrice!.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted,
                                decoration: TextDecoration.lineThrough)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Quick add to cart
                  GestureDetector(
                    onTap: () => context.push('/product/${product.id}'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 0.5)),
                      child: Text(
                        'SELECT SIZE',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.textSecondary),
                      ),
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

// ── Empty State ────────────────────────────────────────────────────────────────
class _EmptyWishlist extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
              child: const Icon(Icons.favorite_outline, size: 36, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Text('Your wishlist is empty',
                style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text('Save pieces you love and find them easily later.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 28),
            PremiumButton(
              text: 'START SHOPPING',
              onPressed: () => context.go('/collections'),
              type: PremiumButtonType.primary,
              width: 200,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sign In Prompt ─────────────────────────────────────────────────────────────
class _SignInPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('WISHLIST', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 3)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text('Sign in to view your wishlist',
                  style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Save your favourite pieces across devices.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 28),
              PremiumButton(
                text: 'SIGN IN',
                onPressed: () => context.push('/login'),
                type: PremiumButtonType.primary,
                width: 200,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/register'),
                child: Text('Create an account',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('Something went wrong', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextButton(onPressed: () => context.pop(), child: const Text('Go Back')),
        ],
      ),
    );
  }
}
