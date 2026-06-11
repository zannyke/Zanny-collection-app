import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/providers/product_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Image.asset(
          'assets/images/logo_with_bg.png',
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
                      decoration: const BoxDecoration(
                        color: AppColors.textPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: const TextStyle(
                              color: AppColors.background,
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
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
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.textPrimary),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: GoogleFonts.inter(color: AppColors.error),
          ),
        ),
        data: (product) {
          if (product == null) {
            return Center(
              child: Text(
                'Product not found.',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            );
          }

          // Safely initialize defaults on load
          if (_loadedProduct != product) {
            _loadedProduct = product;
            _selectedColor = product.colors.isNotEmpty ? product.colors.first : null;
            _selectedSize = null;
            _quantity = 1;
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                Container(
                  height: 380,
                  width: double.infinity,
                  color: AppColors.surfaceElevated,
                  child: Stack(
                    children: [
                      Center(
                        child: product.images.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: product.images.first,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.image_outlined,
                                  color: AppColors.textMuted,
                                  size: 64,
                                ),
                              )
                            : const Icon(
                                Icons.image_outlined,
                                color: AppColors.textMuted,
                                size: 64,
                              ),
                      ),
                      if (product.isNew)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            color: AppColors.textPrimary,
                            child: Text(
                              'NEW',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: AppColors.background,
                              ),
                            ),
                          ),
                        ),
                    ],
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
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.name,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
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
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (product.isOnSale)
                                Text(
                                  'KES ${product.originalPrice!.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 20),

                      // Color Selector
                      if (product.colors.isNotEmpty) ...[
                        Text(
                          'COLOUR: ${_selectedColor ?? ''}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          children: product.colors.map((color) {
                            final isSelected = _selectedColor == color;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedColor = color),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.textPrimary
                                        : AppColors.border,
                                    width: isSelected ? 1.5 : 0.5,
                                  ),
                                  color: isSelected
                                      ? AppColors.textPrimary
                                      : AppColors.surface,
                                ),
                                child: Text(
                                  color,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.background
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Size Selector
                      if (product.sizes.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SIZE',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showSizeGuide(context),
                              child: Text(
                                'Size Guide',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: product.sizes.map((size) {
                            final isSelected = _selectedSize == size;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedSize = size),
                              child: Container(
                                width: 48,
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.textPrimary
                                        : AppColors.border,
                                    width: isSelected ? 1.5 : 0.5,
                                  ),
                                  color: isSelected
                                      ? AppColors.textPrimary
                                      : AppColors.surface,
                                ),
                                child: Text(
                                  size,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.background
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Quantity
                      Text(
                        'QUANTITY',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: AppColors.textSecondary,
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
                            decoration: const BoxDecoration(
                              border: Border.symmetric(
                                horizontal: BorderSide(color: AppColors.border, width: 0.5),
                              ),
                            ),
                            child: Text(
                              '$_quantity',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          _QuantityButton(
                            icon: Icons.add,
                            onTap: () => setState(() => _quantity++),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Add to Cart button
                      if (product.sizes.isNotEmpty && _selectedSize == null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Please select a size',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                        ),

                      ElevatedButton(
                        onPressed: () => _addToCart(product),
                        child: Text(
                          _addedToCart ? 'ADDED TO CART ✓' : 'ADD TO CART',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      OutlinedButton(
                        onPressed: () => context.push('/cart'),
                        child: Text(
                          'VIEW CART',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 20),

                      // Description
                      Text(
                        'DESCRIPTION',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        product.description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.7,
                        ),
                      ),

                      // "You May Also Like" Related Products
                      const SizedBox(height: 32),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 20),
                      Text(
                        'YOU MAY ALSO LIKE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Consumer(builder: (context, ref, _) {
                        final relatedAsync = ref.watch(relatedProductsProvider((product.category, product.id)));
                        return relatedAsync.when(
                          loading: () => const SizedBox(
                            height: 150,
                            child: Center(child: CircularProgressIndicator(color: AppColors.textPrimary)),
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
                                  return GestureDetector(
                                    onTap: () {
                                      // Navigate to related product page (pushReplacement to keep stack neat)
                                      context.pushReplacement('/product/${item.id}');
                                    },
                                    child: Container(
                                      width: 140,
                                      margin: const EdgeInsets.only(right: 12),
                                      color: AppColors.surface,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              color: AppColors.surfaceElevated,
                                              child: item.images.isNotEmpty
                                                  ? CachedNetworkImage(
                                                      imageUrl: item.images.first,
                                                      fit: BoxFit.cover,
                                                      placeholder: (context, url) => const Center(
                                                        child: SizedBox(
                                                          width: 16,
                                                          height: 16,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: AppColors.textSecondary,
                                                          ),
                                                        ),
                                                      ),
                                                      errorWidget: (context, url, error) => const Icon(
                                                        Icons.image_outlined,
                                                        color: AppColors.textMuted,
                                                        size: 20,
                                                      ),
                                                    )
                                                  : const Center(
                                                      child: Icon(
                                                        Icons.image_outlined,
                                                        color: AppColors.textMuted,
                                                        size: 20,
                                                      ),
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
                                                    color: AppColors.textPrimary,
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
                                                    color: AppColors.textSecondary,
                                                  ),
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
                            );
                          },
                        );
                      }),

                      const SizedBox(height: 32),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 20),

                      // Value props
                      _InfoRow(Icons.local_shipping_outlined, 'Fast Delivery',
                          'Delivered to your door'),
                      const SizedBox(height: 12),
                      _InfoRow(Icons.cached_outlined, 'Easy Returns',
                          '14-day hassle-free returns'),
                      const SizedBox(height: 12),
                      _InfoRow(Icons.verified_outlined, 'Safe Hustle',
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
    ref.read(cartProvider.notifier).addItem(
          product,
          _selectedColor ?? '',
          _selectedSize ?? '',
          _quantity,
        );
    setState(() => _addedToCart = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _addedToCart = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSizeGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
                    letterSpacing: 2)),
            const SizedBox(height: 20),
            Table(
              border: TableBorder.all(color: AppColors.border, width: 0.5),
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
                                style: GoogleFonts.inter(fontSize: 12),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 0.5),
          color: AppColors.surface,
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
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
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textPrimary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            Text(subtitle,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }
}
