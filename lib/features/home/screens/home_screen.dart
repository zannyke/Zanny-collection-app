import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/cart_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/animations.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo_with_bg.png',
          height: 38,
          width: 38,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            onPressed: () => context.go('/search'),
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () => context.push('/cart'),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.textPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        cartCount > 9 ? '9+' : '$cartCount',
                        style: const TextStyle(
                          color: AppColors.background,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Hero Banner
          SliverToBoxAdapter(
            child: _HeroBanner(),
          ),
          // Section title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
              child: Row(
                children: [
                  Text(
                    'SHOP BY CATEGORY',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
            ),
          ),
          // Category Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = ProductCategory.all[index];
                  return _CategoryCard(category: category);
                },
                childCount: ProductCategory.all.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
            ),
          ),
          // Value Props
          const SliverToBoxAdapter(child: _ValueProps()),
          // Footer space
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ── Hero Banner ────────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 420,
      decoration: const BoxDecoration(color: AppColors.surface),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withOpacity(0.2),
                  AppColors.background.withOpacity(0.85),
                ],
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textPrimary.withOpacity(0.5)),
                  ),
                  child: Text(
                    'NEW SEASON',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Premium\nProducts for\nThose on the\nWay Up',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 20),
                Builder(builder: (ctx) {
                  return GestureDetector(
                    onTap: () => ctx.go('/collections'),
                    child: Row(
                      children: [
                        Text(
                          'SHOP NOW',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward,
                            color: AppColors.textPrimary, size: 16),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category Card ──────────────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final ProductCategory category;
  const _CategoryCard({required this.category});

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
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Category image
              Container(
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
                            color: AppColors.textMuted, size: 32),
                      ),
              ),
              // Bottom gradient + label
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.background.withOpacity(0.9),
                      ],
                    ),
                  ),
                  child: Text(
                    category.name.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Value Props ────────────────────────────────────────────────────────────────
class _ValueProps extends StatelessWidget {
  const _ValueProps();

  @override
  Widget build(BuildContext context) {
    final props = [
      (Icons.local_shipping_outlined, 'FAST DELIVERY', 'Delivered to your door'),
      (Icons.cached_outlined, 'EASY RETURNS', '14-day hassle-free returns'),
      (Icons.verified_outlined, 'SAFE HUSTLE', '100% authentic products'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: props.map((p) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(p.$1, color: AppColors.textPrimary, size: 20),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.$2,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.$3,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}
