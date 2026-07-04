import 'dart:async';
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
import 'package:video_player/video_player.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../../core/services/update_service.dart';
import '../../../core/cloudflare/api_client.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/feedback_dialog.dart';


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
      _checkPendingFeedback();
    });
  }

  Future<void> _checkPendingFeedback() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final api = ApiClient.instance;
      final resp = await api.get('/api/feedback/pending');
      if (resp.statusCode == 200 && resp.data != null && resp.data['pending'] == true) {
        final orderId = resp.data['order']['id'] as String;
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => FeedbackDialog(orderId: orderId),
          );
        }
      }
    } catch (_) {}
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
          const SliverToBoxAdapter(
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
class _HeroBanner extends ConsumerStatefulWidget {
  const _HeroBanner();

  @override
  ConsumerState<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends ConsumerState<_HeroBanner> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;
  final Map<String, VideoPlayerController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.mp4') || lower.contains('.mov') || lower.contains('.3gp') || lower.contains('.mkv');
  }

  void _initializeVideo(String url, List<String> slides) {
    if (_controllers.containsKey(url)) return;
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            if (slides.indexOf(url) == _currentPage) {
              _scheduleNextSlide(slides);
            }
          }
        })
        ..setLooping(true)
        ..setVolume(0.0) // Silent
        ..play();
      _controllers[url] = controller;
    } catch (e) {
      debugPrint('⚠️ Failed to initialize video player: $e');
    }
  }

  int? _timerTargetIndex;

  void _scheduleNextSlide(List<String> slides) {
    if (slides.length <= 1) {
      _timer?.cancel();
      _timerTargetIndex = null;
      return;
    }
    if (_timerTargetIndex == _currentPage && _timer?.isActive == true) {
      return;
    }
    _timer?.cancel();
    _timerTargetIndex = _currentPage;

    Duration slideDuration = const Duration(seconds: 5);
    final currentUrl = slides[_currentPage];
    if (_isVideo(currentUrl)) {
      final controller = _controllers[currentUrl];
      if (controller != null && controller.value.isInitialized) {
        final videoDuration = controller.value.duration;
        if (videoDuration.inSeconds > 0) {
          slideDuration = videoDuration;
          if (slideDuration.inSeconds > 30) {
            slideDuration = const Duration(seconds: 30);
          } else if (slideDuration.inSeconds < 3) {
            slideDuration = const Duration(seconds: 3);
          }
        }
      }
    }

    _timer = Timer(slideDuration, () {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      ).then((_) {
        _scheduleNextSlide(slides);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = ref.watch(bannerImageProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Pre-initialize video controllers for any video slides
    for (final url in slides) {
      if (_isVideo(url)) {
        _initializeVideo(url, slides);
      }
    }

    // Start or reset timer based on current slide count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleNextSlide(slides);
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        height: screenHeight * 0.65,
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
              // Sliding banner images / videos
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: slides.length,
                itemBuilder: (context, index) {
                  final url = slides[index];
                  if (_isVideo(url)) {
                    final controller = _controllers[url];
                    if (controller != null && controller.value.isInitialized) {
                      return SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: controller.value.size.width,
                            height: controller.value.size.height,
                            child: VideoPlayer(controller),
                          ),
                        ),
                      );
                    } else {
                      return Container(
                        color: AppColors.surfaceElevated,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                  }
                  return CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.surfaceElevated,
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.surfaceElevated,
                    ),
                  );
                },
              ),
              // Dark gradient overlay
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ),
              // NEW SEASON badge on the top right
              Positioned(
                top: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'NEW SEASON',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Centered Main Text & Shop Now Button
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40), // Push down slightly to balance top badge
                      Text(
                        'Premium Products\nfor Those on\nthe Way Up',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Builder(builder: (ctx) {
                        return GestureDetector(
                          onTap: () => ctx.go('/collections'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'SHOP NOW',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2.5,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded,
                                    color: Colors.black87, size: 16),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              // Slide dot indicators at the bottom center
              if (slides.length > 1)
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
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
                          placeholder: (context, url) => const ShimmerBox(
                            width: double.infinity,
                            height: double.infinity,
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
                        placeholder: (context, url) => const ShimmerBox(
                          width: double.infinity,
                          height: double.infinity,
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

