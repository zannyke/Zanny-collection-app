import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/wishlist_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/shimmer_widgets.dart';

import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/zanny_app_bar.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const ZannyAppBar(
        title: 'Wishlist',
        showBack: true,
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
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text(
                  '${products.length} ${products.length == 1 ? 'item' : 'items'} saved',
                  style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.secondary),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                return FadeInSlide(
                  delay: Duration(milliseconds: 50 * index),
                  child: ProductCard(
                    product: product,
                    trailing: GestureDetector(
                      onTap: () => ref.read(wishlistProvider.notifier).toggle(product),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite, size: 16, color: AppColors.sale),
                      ),
                    ),
                  ),
                );
              },
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
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Theme.of(context).colorScheme.outline)),
              child: Icon(Icons.favorite_outline, size: 36, color: Theme.of(context).colorScheme.secondary),
            ),
            const SizedBox(height: 20),
            Text('Your wishlist is empty',
                style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text('Save pieces you love and find them easily later.',
                style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.secondary), textAlign: TextAlign.center),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const ZannyAppBar(
        title: 'Wishlist',
        showBack: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 48, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(height: 16),
              Text('Sign in to view your wishlist',
                  style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Save your favourite pieces across devices.',
                  style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.secondary), textAlign: TextAlign.center),
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
                    style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.secondary)),
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
          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(height: 12),
          Text('Something went wrong', style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.secondary)),
          const SizedBox(height: 8),
          TextButton(onPressed: () => context.pop(), child: const Text('Go Back')),
        ],
      ),
    );
  }
}
