import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/providers/product_provider.dart';
import '../../../shared/providers/street_styles_provider.dart';
import '../../../shared/widgets/product_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/shimmer_widgets.dart';


import '../../../core/services/update_service.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate(context: context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartCountProvider);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        leadingWidth: 60,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/images/logo_with_bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'ZANNY',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 6,
            color: theme.colorScheme.primary,
          ),
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
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        cartCount > 9 ? '9+' : '$cartCount',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
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
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
                  return FadeInSlide(
                    delay: Duration(milliseconds: 50 * index),
                    child: _CategoryCard(category: category),
                  );
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
          // New Arrivals
          const SliverToBoxAdapter(child: _NewArrivalsSection()),
          // Street Styles
          const SliverToBoxAdapter(child: _StreetStylesSection()),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        height: 380,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?q=80&w=1000',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.surfaceElevated,
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.surfaceElevated,
                ),
              ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.background.withValues(alpha: 0.1),
                      AppColors.background.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(6),
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
                        fontSize: 28,
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
        ),
      ),
    );
  }
}

// ── Category Card ──────────────────────────────────────────────────────────────
class _CategoryCard extends ConsumerWidget {
  final ProductCategory category;
  const _CategoryCard({required this.category});

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
            color: AppColors.surface,
            border: Border.all(color: AppColors.border, width: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Category image
                Container(
                  color: AppColors.surfaceElevated,
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
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
                          AppColors.background.withValues(alpha: 0.9),
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
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surface,
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

// ── New Arrivals Section ────────────────────────────────────────────────────────
class _NewArrivalsSection extends ConsumerWidget {
  const _NewArrivalsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(newArrivalsProvider);
    final theme = Theme.of(context);

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();

        // Shuffle the products list to show variety
        final shuffledProducts = List<Product>.from(products)..shuffle();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
              child: Row(
                children: [
                  Text(
                    'NEW ARRIVALS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Divider(color: theme.colorScheme.outline)),
                ],
              ),
            ),
            SizedBox(
              height: 280,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: shuffledProducts.length,
                itemBuilder: (context, index) {
                  final product = shuffledProducts[index];
                  return Container(
                    width: 170,
                    margin: const EdgeInsets.only(right: 12),
                    child: ProductCard(product: product),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const HorizontalProductShimmer(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Street Styles Section ───────────────────────────────────────────────────────
class _StreetStylesSection extends ConsumerWidget {
  const _StreetStylesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final styles = ref.watch(streetStylesProvider);
    final theme = Theme.of(context);

    if (styles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
          child: Row(
            children: [
              Text(
                'STREET STYLES',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Divider(color: theme.colorScheme.outline)),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: styles.length,
            itemBuilder: (context, index) {
              final item = styles[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outline, width: 0.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: item.images.isNotEmpty ? item.images.first : '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: theme.colorScheme.surface,
                          child: const Center(
                            child: ZannyLoadingIndicator(size: 20),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.colorScheme.surface,
                          child: const Icon(Icons.image_outlined),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.username,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, color: Colors.white70, size: 10),
                                const SizedBox(width: 4),
                                Text(
                                  item.location,
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

