import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../shared/models/models.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/providers/product_provider.dart';
import '../../../shared/providers/user_activity_provider.dart';
import '../../../shared/providers/wishlist_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/animations.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  String? _selectedColor;
  String? _selectedSize;
  int _quantity = 1;
  bool _addedToCart = false;
  Product? _loadedProduct;
  late final PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color _getSwatchColor(String name) {
    final cleanName = name.toLowerCase();
    if (cleanName.contains('black')) return Colors.black;
    if (cleanName.contains('white')) return Colors.white;
    if (cleanName.contains('grey') || cleanName.contains('gray')) return Colors.grey;
    if (cleanName.contains('charcoal')) return const Color(0xFF333333);
    if (cleanName.contains('olive')) return const Color(0xFF556B2F);
    if (cleanName.contains('sage')) return const Color(0xFF8FBC8F);
    if (cleanName.contains('red')) return const Color(0xFF8B0000);
    if (cleanName.contains('blue') || cleanName.contains('navy')) return const Color(0xFF000080);
    if (cleanName.contains('cream') || cleanName.contains('off-white')) return const Color(0xFFFFFDD0);
    if (cleanName.contains('sand') || cleanName.contains('beige') || cleanName.contains('stone')) return const Color(0xFFE5D3B3);
    if (cleanName.contains('mocha') || cleanName.contains('brown')) return const Color(0xFF5C4033);
    return Colors.blueGrey;
  }

  void _buyNow(Product product) {
    if (product.sizes.isNotEmpty && _selectedSize == null) return;
    final finalQty = _quantity > product.stock ? product.stock : _quantity;
    if (finalQty <= 0) return;
    ref.read(cartProvider.notifier).addItem(
          product,
          _selectedColor ?? '',
          _selectedSize ?? '',
          finalQty,
        );
    context.push('/cart');
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Image.asset(
          'assets/images/logo_transparent.png',
          height: 38,
          width: 38,
        ),
        actions: [
          Consumer(builder: (ctx, ref, _) {
            final count = ref.watch(cartCountProvider);
            return Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  onPressed: () => ctx.push('/cart'),
                ),
                if (count > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(width: 4),
        ],
      ),
      body: productAsync.when(
        loading: () => Center(
          child: ZannyLoadingIndicator(size: 32, color: theme.colorScheme.primary),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: GoogleFonts.inter(color: theme.colorScheme.error),
          ),
        ),
        data: (product) {
          if (product == null) {
            return Center(
              child: Text(
                'Product not found.',
                style: GoogleFonts.inter(color: theme.colorScheme.secondary),
              ),
            );
          }

          // Safely initialize defaults on load
          if (_loadedProduct != product) {
            _loadedProduct = product;
            _selectedColor = product.colors.isNotEmpty ? product.colors.first : null;
            _selectedSize = null;
            _quantity = product.stock > 0 ? 1 : 0;
            _currentImageIndex = 0;
            Future.microtask(() {
              ref.read(userActivityProvider.notifier).recordProductView(product.id);
            });
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image container with premium rounded bottom corners
                Container(
                  height: 380,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFF3F4F6) : const Color(0xFF1F1F1F),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                          child: product.images.isNotEmpty
                              ? PageView.builder(
                                  controller: _pageController,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentImageIndex = index;
                                    });
                                  },
                                  itemCount: product.images.length,
                                  itemBuilder: (context, index) {
                                    return CachedNetworkImage(
                                      imageUrl: product.images[index],
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) => Center(
                                        child: ZannyLoadingIndicator(
                                          size: 24,
                                          color: theme.colorScheme.secondary,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Icon(
                                        Icons.image_outlined,
                                        color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                                        size: 64,
                                      ),
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.image_outlined,
                                  color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                                  size: 64,
                                ),
                        ),
                      ),

                      if (product.isNew)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'NEW',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                  color: theme.colorScheme.onPrimary),
                            ),
                          ),
                        ),
                      // Floating wishlist toggle button
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Consumer(
                          builder: (context, ref, _) {
                            final isWish = ref.watch(isWishlistedProvider(product.id));
                            final user = ref.watch(currentUserProvider);
                            return Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isLight ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                iconSize: 18,
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
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                if (product.images.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: product.images.length,
                        itemBuilder: (context, index) {
                          final isSelected = _currentImageIndex == index;
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              width: 60,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline.withValues(alpha: 0.5),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: CachedNetworkImage(
                                  imageUrl: product.images[index],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: theme.colorScheme.surface,
                                    child: const Center(
                                      child: ZannyLoadingIndicator(size: 16),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(Icons.image_outlined, size: 20),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.subtitle.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.name,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'KES ${product.price.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              if (product.isOnSale)
                                Text(
                                  'KES ${product.originalPrice!.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: theme.colorScheme.secondary.withValues(alpha: 0.6),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      Divider(color: theme.colorScheme.outline),
                      const SizedBox(height: 20),

                      // Option Grid: Sizes on Left, Colors on Right (aligned with reference image Style C)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sizes (Left Side)
                          if (product.sizes.isNotEmpty)
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SIZE',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: product.sizes.map((size) {
                                      final isSelected = _selectedSize == size;
                                      return TactileButton(
                                        onTap: () => setState(() => _selectedSize = size),
                                        child: Container(
                                          width: 38,
                                          height: 38,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isSelected
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme.outline,
                                              width: isSelected ? 1.5 : 0.5,
                                            ),
                                            color: isSelected
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.surface,
                                          ),
                                          child: Text(
                                            size,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? theme.colorScheme.onPrimary
                                                  : theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 6),
                                  TextButton(
                                    onPressed: () => _showSizeGuide(context),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Size Chart',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: theme.colorScheme.secondary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(width: 16),

                          // Colors (Right Side)
                          if (product.colors.isNotEmpty)
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'COLOURS',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: product.colors.map((color) {
                                      final isSelected = _selectedColor == color;
                                      final swatchColor = _getSwatchColor(color);
                                      return Tooltip(
                                        message: color,
                                        child: TactileButton(
                                          onTap: () => setState(() => _selectedColor = color),
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: swatchColor,
                                              border: Border.all(
                                                color: isSelected
                                                    ? theme.colorScheme.primary
                                                    : theme.colorScheme.outline,
                                                width: isSelected ? 2.0 : 0.5,
                                              ),
                                            ),
                                            child: isSelected
                                                ? Icon(
                                                    Icons.check_rounded,
                                                    color: swatchColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                                    size: 14,
                                                  )
                                                : null,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _selectedColor ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: theme.colorScheme.secondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Quantity
                      Text(
                        'QUANTITY',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _QuantityButton(
                            icon: Icons.remove,
                            onTap: () {
                              if (_quantity > 1) setState(() => _quantity--);
                            },
                          ),
                          Container(
                            width: 60,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.symmetric(
                                horizontal: BorderSide(color: theme.colorScheme.outline, width: 0.5),
                              ),
                            ),
                            child: Text(
                              '$_quantity',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          _QuantityButton(
                            icon: Icons.add,
                            onTap: () {
                              if (_quantity < product.stock) {
                                setState(() => _quantity++);
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      if (product.sizes.isNotEmpty && _selectedSize == null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Please select a size',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                      if (product.stock <= 0)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.3),
                              disabledBackgroundColor: theme.colorScheme.outline.withValues(alpha: 0.3),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              'OUT OF STOCK',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 1,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _addToCart(product),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text(
                                  _addedToCart ? 'ADDED ✓' : 'ADD TO CART',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    letterSpacing: 1,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _buyNow(product),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text(
                                  'BUY NOW',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 28),
                      Divider(color: theme.colorScheme.outline),
                      const SizedBox(height: 20),

                      // Description
                      Text(
                        'DESCRIPTION',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        product.description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: theme.colorScheme.secondary,
                          height: 1.7,
                        ),
                      ),

                      // "You May Also Like" Related Products
                      const SizedBox(height: 32),
                      Divider(color: theme.colorScheme.outline),
                      const SizedBox(height: 20),
                      Text(
                        'YOU MAY ALSO LIKE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Consumer(builder: (context, ref, _) {
                        final relatedAsync = ref.watch(recommendedProductsProvider((product.id, product.category)));
                        return relatedAsync.when(
                          loading: () => SizedBox(
                            height: 150,
                            child: Center(child: ZannyLoadingIndicator(size: 24, color: theme.colorScheme.primary)),
                          ),
                          error: (err, stack) => const SizedBox(),
                          data: (list) {
                            if (list.isEmpty) return const SizedBox();
                            return SizedBox(
                              height: 220,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: list.length,
                                itemBuilder: (context, index) {
                                  final item = list[index];
                                  return FadeInSlide(
                                    delay: Duration(milliseconds: index * 50),
                                    child: TactileButton(
                                      onTap: () {
                                        context.pushReplacement('/product/${item.id}');
                                      },
                                      child: Container(
                                        width: 140,
                                        margin: const EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surface,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: theme.colorScheme.outline, width: 0.5),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  color: isLight ? const Color(0xFFF3F4F6) : const Color(0xFF1F1F1F),
                                                  child: item.images.isNotEmpty
                                                      ? Padding(
                                                          padding: const EdgeInsets.all(8.0),
                                                          child: CachedNetworkImage(
                                                            imageUrl: item.images.first,
                                                            fit: BoxFit.contain,
                                                            placeholder: (context, url) => Center(
                                                              child: ZannyLoadingIndicator(
                                                                size: 16,
                                                                color: theme.colorScheme.secondary,
                                                              ),
                                                            ),
                                                            errorWidget: (context, url, error) => Icon(
                                                              Icons.image_outlined,
                                                              color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                                                              size: 20,
                                                            ),
                                                          ),
                                                        )
                                                      : Icon(
                                                          Icons.image_outlined,
                                                          color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                                                          size: 20,
                                                        ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(8),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.name,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                        color: theme.colorScheme.onSurface,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'KES ${item.price.toStringAsFixed(0)}',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w700,
                                                        color: theme.colorScheme.secondary,
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
                                },
                              ),
                            );
                          },
                        );
                      }),

                      const SizedBox(height: 32),
                      Divider(color: theme.colorScheme.outline),
                      const SizedBox(height: 20),

                      // Value props
                      const _InfoRow(Icons.local_shipping_outlined, 'Fast Delivery',
                          'Delivered to your door'),
                      const SizedBox(height: 12),
                      const _InfoRow(Icons.cached_outlined, 'Easy Returns',
                          '14-day hassle-free returns'),
                      const SizedBox(height: 12),
                      const _InfoRow(Icons.verified_outlined, 'Safe Hustle',
                          '100% authentic products'),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addToCart(Product product) {
    if (product.sizes.isNotEmpty && _selectedSize == null) return;
    final finalQty = _quantity > product.stock ? product.stock : _quantity;
    if (finalQty <= 0) return;
    ref.read(cartProvider.notifier).addItem(
          product,
          _selectedColor ?? '',
          _selectedSize ?? '',
          finalQty,
        );
    setState(() => _addedToCart = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _addedToCart = false);
    });
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${product.name} added to cart',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.colorScheme.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSizeGuide(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SIZE GUIDE',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: 20),
            Table(
              border: TableBorder.all(color: theme.colorScheme.outline, width: 0.5),
              children: [
                for (final row in [
                  ['Size', 'Chest (cm)', 'Waist (cm)', 'Hip (cm)'],
                  ['XS', '82–87', '68–73', '88–93'],
                  ['S', '88–93', '74–79', '94–99'],
                  ['M', '94–99', '80–85', '100–105'],
                  ['L', '100–105', '86–91', '106–111'],
                  ['XL', '106–111', '92–97', '112–117'],
                  ['XXL', '112–117', '98–103', '118–123'],
                ])
                  TableRow(
                    children: row
                        .map((cell) => Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                cell,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface),
                                textAlign: TextAlign.center,
                              ),
                            ))
                        .toList(),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TactileButton(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.outline, width: 0.5),
          color: theme.colorScheme.surface,
        ),
        child: Icon(icon, size: 18, color: theme.colorScheme.onSurface),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _InfoRow(this.icon, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurface),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface)),
            Text(subtitle,
                style: GoogleFonts.inter(
                    fontSize: 11, color: theme.colorScheme.secondary)),
          ],
        ),
      ],
    );
  }
}
