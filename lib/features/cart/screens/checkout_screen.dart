import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/addresses_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/providers/product_provider.dart';
import '../../../shared/providers/orders_provider.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/custom_feedback.dart';
import '../../../shared/widgets/shimmer_placeholder.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for address form
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  
  String _paymentMethod = 'cod'; // 'cod' or 'mpesa'
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _nameController.text = user.userMetadata['full_name'] as String? ?? '';
      _phoneController.text = user.userMetadata['phone'] as String? ?? '';
    }
    // Proactively refresh products in background to keep stock information live
    Future.microtask(() {
      ref.read(productsStateProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    final cartItems = ref.read(cartProvider);
    final total = ref.read(cartTotalProvider);
    const shipping = 250.0;
    final grandTotal = total + shipping;

    if (cartItems.isEmpty) {
      ZannyFeedback.showError(context, 'Your cart is empty');
      return;
    }

    // Double check live stock again right before placing order
    final latestProducts = ref.read(productsStateProvider);
    for (final item in cartItems) {
      final latest = latestProducts.where((p) => p.id == item.product.id).firstOrNull;
      final stock = latest?.stock ?? item.product.stock;
      if (stock <= 0) {
        ZannyFeedback.showError(context, '${item.product.name} is out of stock. Please remove it from your cart.');
        return;
      }
      if (stock < item.quantity) {
        ZannyFeedback.showError(context, 'Only $stock items of ${item.product.name} are left in stock. Please adjust your quantity.');
        return;
      }
    }

    final defaultAddress = ref.read(defaultAddressProvider);
    Address address;

    if (defaultAddress != null) {
      address = defaultAddress;
    } else {
      if (!_formKey.currentState!.validate()) {
        return;
      }
      address = Address(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        recipientName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        streetAddress: _addressController.text.trim(),
        city: _cityController.text.trim(),
        postalCode: '',
        isDefault: true,
      );
      // Save address locally/server-side
      await ref.read(addressesProvider.notifier).addAddress(address);
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final newOrder = await ref.read(ordersProvider.notifier).placeOrder(
        items: cartItems,
        totalAmount: grandTotal,
        deliveryAddress: '${address.streetAddress}, ${address.city}',
        recipientName: address.recipientName,
        recipientPhone: address.phone,
        paymentMethod: _paymentMethod,
      );
      
      if (mounted) {
        ZannyFeedback.showSuccess(context, 'Order placed successfully!');
        context.go('/order-success', extra: newOrder);
      }
    } catch (e) {
      if (mounted) {
        ZannyFeedback.showError(context, 'Failed to place order: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartItems = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    const shipping = 250.0;
    final grandTotal = total + shipping;
    final defaultAddress = ref.watch(defaultAddressProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.primary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'CHECKOUT CONFIRMATION',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                
                // Address Section
                _buildSectionTitle('SHIPPING DETAILS'),
                if (defaultAddress != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border.all(color: theme.colorScheme.outline, width: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              defaultAddress.recipientName,
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            TextButton(
                              onPressed: () => context.push('/saved-addresses'),
                              child: Text(
                                'Change',
                                style: GoogleFonts.inter(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          defaultAddress.phone,
                          style: GoogleFonts.inter(color: theme.colorScheme.secondary, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${defaultAddress.streetAddress}, ${defaultAddress.city}',
                          style: GoogleFonts.inter(color: theme.colorScheme.secondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border.all(color: theme.colorScheme.outline, width: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('RECIPIENT NAME'),
                          TextFormField(
                            controller: _nameController,
                            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Recipient name is required' : null,
                            decoration: _inputDecoration('e.g. John Doe'),
                          ),
                          const SizedBox(height: 12),
                          _buildFieldLabel('PHONE NUMBER'),
                          TextFormField(
                            controller: _phoneController,
                            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                            keyboardType: TextInputType.phone,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone number is required' : null,
                            decoration: _inputDecoration('e.g. +254 712 345678'),
                          ),
                          const SizedBox(height: 12),
                          _buildFieldLabel('STREET ADDRESS'),
                          TextFormField(
                            controller: _addressController,
                            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Street address is required' : null,
                            decoration: _inputDecoration('e.g. Apartment 4B, Ngong Road'),
                          ),
                          const SizedBox(height: 12),
                          _buildFieldLabel('CITY / TOWN'),
                          TextFormField(
                            controller: _cityController,
                            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'City/Town is required' : null,
                            decoration: _inputDecoration('e.g. Nairobi'),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Payment Options
                _buildSectionTitle('PAYMENT METHOD'),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border.all(color: theme.colorScheme.outline, width: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: Text(
                          'Cash on Delivery',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                        ),
                        subtitle: Text(
                          'Pay cash or mobile transfer after receiving package',
                          style: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.secondary),
                        ),
                        value: 'cod',
                        groupValue: _paymentMethod,
                        activeColor: theme.colorScheme.primary,
                        onChanged: (val) {
                          setState(() {
                            _paymentMethod = val!;
                          });
                        },
                      ),
                      Divider(color: theme.colorScheme.outline, height: 1),
                      RadioListTile<String>(
                        title: Text(
                          'M-Pesa (Mobile Money)',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                        ),
                        subtitle: Text(
                          'Pay via STK Push popup before delivery dispatch',
                          style: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.secondary),
                        ),
                        value: 'mpesa',
                        groupValue: _paymentMethod,
                        activeColor: theme.colorScheme.primary,
                        onChanged: (val) {
                          setState(() {
                            _paymentMethod = val!;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Order Review
                _buildSectionTitle('PURCHASE ITEMS'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border.all(color: theme.colorScheme.outline, width: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, __) => Divider(color: theme.colorScheme.outline, height: 1),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 50,
                              color: theme.colorScheme.surface,
                              child: item.product.images.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(item.product.images.first, fit: BoxFit.cover),
                                    )
                                  : const Icon(Icons.image_outlined),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Size: ${item.selectedSize}  |  Color: ${item.selectedColor}  |  Qty: ${item.quantity}',
                                    style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.secondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'KES ${item.subtotal.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Price Breakdown Summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border.all(color: theme.colorScheme.outline, width: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _SummaryRow('Subtotal', 'KES ${total.toStringAsFixed(0)}'),
                      const SizedBox(height: 8),
                      _SummaryRow('Shipping Fee', 'KES ${shipping.toStringAsFixed(0)}'),
                      const SizedBox(height: 12),
                      Divider(color: theme.colorScheme.outline),
                      const SizedBox(height: 12),
                      _SummaryRow('Grand Total', 'KES ${grandTotal.toStringAsFixed(0)}', bold: true),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Place Order Button
                PremiumButton(
                  onPressed: _isPlacingOrder ? null : _submitOrder,
                  text: _paymentMethod == 'cod' ? 'CONFIRM & PLACE ORDER' : 'PAY & PLACE ORDER',
                  type: PremiumButtonType.primary,
                  isLoading: _isPlacingOrder,
                ),
              ],
            ),
          ),
          if (_isPlacingOrder)
            Positioned.fill(
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.45),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border, width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const ShimmerPlaceholder(width: 24, height: 24, borderRadius: 12),
                            const SizedBox(width: 16),
                            Text(
                              'Placing your order...',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: theme.colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, left: 4.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: theme.colorScheme.secondary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.colorScheme.secondary.withValues(alpha: 0.5), fontSize: 12),
      filled: true,
      fillColor: theme.scaffoldBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.primary),
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
