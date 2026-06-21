import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/cart_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/custom_feedback.dart';


class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'YOUR CART (${items.fold(0, (s, i) => s + i.quantity)})',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ),
      body: items.isEmpty
          ? _EmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (context, _) =>
                        Divider(color: Theme.of(context).colorScheme.outline),
                    itemBuilder: (context, index) =>
                        _CartItemTile(item: items[index]),
                  ),
                ),
                _OrderSummary(total: total),
              ],
            ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 88,
            height: 108,
            color: Theme.of(context).colorScheme.surface,
            child: item.product.images.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.product.images.first,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: ZannyLoadingIndicator(
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Icon(Icons.image_outlined,
                          color: Theme.of(context).colorScheme.secondary, size: 24),
                    ),
                  )
                : Center(
                    child: Icon(Icons.image_outlined,
                        color: Theme.of(context).colorScheme.secondary, size: 24),
                  ),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.selectedColor} / ${item.selectedSize}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Quantity control
                    _SmallQtyButton(
                      icon: Icons.remove,
                      onTap: () => ref
                          .read(cartProvider.notifier)
                          .updateQuantity(item.key, item.quantity - 1),
                    ),
                    Container(
                      width: 36,
                      height: 32,
                      alignment: Alignment.center,
                      child: Text(
                        '${item.quantity}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _SmallQtyButton(
                      icon: Icons.add,
                      onTap: () => ref
                          .read(cartProvider.notifier)
                          .updateQuantity(item.key, item.quantity + 1),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 18, color: Theme.of(context).colorScheme.secondary),
                      onPressed: () => ref
                          .read(cartProvider.notifier)
                          .removeItem(item.key),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Price
          Text(
            'KES ${item.subtotal.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallQtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallQtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TactileButton(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline, width: 0.5),
        ),
        child: Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}

class _OrderSummary extends ConsumerWidget {
  final double total;
  const _OrderSummary({required this.total});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const shipping = 250.0;
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outline, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ORDER SUMMARY',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryRow('Subtotal', 'KES ${total.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _SummaryRow('Shipping', 'KES ${shipping.toStringAsFixed(0)}'),
          const SizedBox(height: 12),
          Divider(color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          _SummaryRow(
            'Total',
            'KES ${(total + shipping).toStringAsFixed(0)}',
            bold: true,
          ),
          const SizedBox(height: 16),
          PremiumButton(
            onPressed: () {
              if (user == null) {
                ZannyFeedback.showError(context, 'Please sign in to complete checkout');
                context.push('/login');
                return;
              }
              context.push('/checkout');
            },
            text: 'PROCEED TO CHECKOUT',
            type: PremiumButtonType.primary,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _SummaryRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.inter(
      fontSize: bold ? 15 : 13,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: bold ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.secondary,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style.copyWith(color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined,
              size: 64, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some premium pieces to get started',
            style: GoogleFonts.inter(
                fontSize: 13, color: Theme.of(context).colorScheme.secondary),
          ),
          const SizedBox(height: 24),
          PremiumButton(
            onPressed: () => context.go('/collections'),
            text: 'SHOP NOW',
            type: PremiumButtonType.primary,
            width: 200,
          ),
        ],
      ),
    );
  }
}
