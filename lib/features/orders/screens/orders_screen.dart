import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/orders_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/animations.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final theme = Theme.of(context);

    final activeOrders = orders.where((o) => o.status != 'delivered').toList();
    final completedOrders = orders.where((o) => o.status == 'delivered').toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.primary, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'MY ORDERS',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.secondary,
            labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5),
            tabs: const [
              Tab(text: 'ACTIVE'),
              Tab(text: 'HISTORY'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OrdersList(orders: activeOrders, emptyLabel: 'No active orders'),
            _OrdersList(orders: completedOrders, emptyLabel: 'No order history yet'),
          ],
        ),
      ),
    );
  }
}

class _OrdersList extends ConsumerWidget {
  final List<Order> orders;
  final String emptyLabel;
  const _OrdersList({required this.orders, required this.emptyLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(ordersProvider.notifier).refresh(),
        color: theme.colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 54, color: theme.colorScheme.secondary.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Text(
                  emptyLabel,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Once you make a purchase, your order status and history will appear here.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(ordersProvider.notifier).refresh(),
      color: theme.colorScheme.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return FadeInSlide(
            delay: Duration(milliseconds: index * 50),
            child: _OrderCard(order: order),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final order = widget.order;
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt);

    Color statusColor;
    switch (order.status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'confirmed':
        statusColor = Colors.blue;
        break;
      case 'shipped':
      case 'delivering':
        statusColor = Colors.purple;
        break;
      case 'delivered':
        statusColor = AppColors.success;
        break;
      default:
        statusColor = theme.colorScheme.secondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Order Summary Header
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            order.id,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            order.status.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${order.items.fold(0, (sum, i) => sum + i.quantity)} items',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'KES ${order.totalAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: theme.colorScheme.secondary.withValues(alpha: 0.6),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Expanded Details Block
            if (_isExpanded) ...[
              const Divider(height: 1, thickness: 0.5),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipient Delivery Address
                    Text(
                      'SHIPPING DETAILS',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${order.recipientName}  |  ${order.recipientPhone}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.deliveryAddress,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Order Items
                    Text(
                      'ITEMS PURCHASED',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: isLight ? const Color(0xFFF3F4F6) : const Color(0xFF1F1F1F),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: item.product.images.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: item.product.images.first,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(Icons.image_outlined, size: 16),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Size: ${item.selectedSize}  |  Color: ${item.selectedColor}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: theme.colorScheme.secondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Qty: ${item.quantity}  x  KES ${item.product.price.toStringAsFixed(0)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: theme.colorScheme.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'KES ${item.subtotal.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                    const Divider(height: 1, thickness: 0.5),
                    const SizedBox(height: 12),

                    // Pricing breakdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal', style: TextStyle(color: theme.colorScheme.secondary, fontSize: 13)),
                        Text('KES ${(order.totalAmount - 250).toStringAsFixed(0)}', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Shipping', style: TextStyle(color: theme.colorScheme.secondary, fontSize: 13)),
                        Text('KES 250', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Paid',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.onSurface),
                        ),
                        Text(
                          'KES ${order.totalAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14, color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
