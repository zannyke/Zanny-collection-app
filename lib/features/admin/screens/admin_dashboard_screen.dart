import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../repositories/admin_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/cloudflare/api_client.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/product_provider.dart';
import '../../../shared/providers/street_styles_provider.dart';
import '../../../shared/providers/orders_provider.dart';
import '../../../shared/widgets/shimmer_placeholder.dart';
import '../../../shared/widgets/custom_feedback.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _advTitleController = TextEditingController();
  final TextEditingController _advBodyController = TextEditingController();
  final TextEditingController _advRouteController = TextEditingController(text: '/profile');
  int _currentTab = 0; // 0: Products, 1: Fashion Styles, 2: Orders, 3: Analytics, 4: Adverts
  bool _sendingAdvert = false;
  bool _updatingBanner = false;

  late final PageController _pageController;
  late final ScrollController _tabScrollController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentTab);
    _tabScrollController = ScrollController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabScrollController.dispose();
    _searchController.dispose();
    _advTitleController.dispose();
    _advBodyController.dispose();
    _advRouteController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentTab = index;
      _searchQuery = '';
      _searchController.clear();
    });
    if (_tabScrollController.hasClients) {
      final targetOffset = (index * 85.0).clamp(
        0.0,
        _tabScrollController.position.maxScrollExtent,
      );
      _tabScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget _buildTabPill(String title, int index, ThemeData theme) {
    final isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
            width: 0.8,
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsStateProvider);
    final styles = ref.watch(streetStylesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.primary, size: 20),
          onPressed: () => context.go('/profile'),
        ),
        title: Text(
          'ADMIN PANEL',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Scrollable Custom Tab Selector
          SingleChildScrollView(
            controller: _tabScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildTabPill('PRODUCTS', 0, theme),
                _buildTabPill('STYLES', 1, theme),
                _buildTabPill('ORDERS', 2, theme),
                _buildTabPill('ANALYTICS', 3, theme),
                _buildTabPill('ADVERTS', 4, theme),
                _buildTabPill('REVIEWS', 5, theme),
              ],
            ),
          ),
 
          // Premium Search Bar (for products)
          if (_currentTab == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  cursorColor: theme.colorScheme.primary,
                  decoration: InputDecoration(
                    hintText: 'Search products by name or category...',
                    hintStyle: TextStyle(color: theme.colorScheme.secondary.withValues(alpha: 0.5)),
                    prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.secondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: theme.colorScheme.secondary),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
            ),
 
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onTabChanged,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildProductsList(context, products, theme),
                _buildStylesList(context, styles, theme),
                _buildOrdersList(context, theme),
                _buildAnalyticsSection(context, theme),
                _buildAdvertsSection(context, theme),
                _buildReviewsSection(context, theme),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: (_currentTab == 0 || _currentTab == 1)
          ? FloatingActionButton.extended(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onPressed: () {
                if (_currentTab == 0) {
                  context.push('/admin/add-product');
                } else {
                  context.push('/admin/add-style');
                }
              },
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                _currentTab == 0 ? 'ADD PRODUCT' : 'ADD STYLE',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildProductsList(BuildContext context, List<Product> products, ThemeData theme) {
    final filteredProducts = products.where((p) {
      final query = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query);
    }).toList();

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, color: theme.colorScheme.secondary.withValues(alpha: 0.5), size: 48),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: GoogleFonts.inter(
                color: theme.colorScheme.secondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80, top: 8),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _AdminProductListItem(
          product: product,
          onDelete: () => _confirmDeleteProduct(context, product),
        );
      },
    );
  }

  Widget _buildStylesList(BuildContext context, List<StreetStyle> styles, ThemeData theme) {
    if (styles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, color: theme.colorScheme.secondary.withValues(alpha: 0.5), size: 48),
            const SizedBox(height: 16),
            Text(
              'No street styles uploaded yet',
              style: GoogleFonts.inter(
                color: theme.colorScheme.secondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80, top: 8),
      itemCount: styles.length,
      itemBuilder: (context, index) {
        final style = styles[index];
        return _AdminStyleListItem(
          style: style,
          onDelete: () => _confirmDeleteStyle(context, style.id),
        );
      },
    );
  }

  void _confirmDeleteProduct(BuildContext context, Product product) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outline),
        ),
        title: Text(
          'Delete Product',
          style: GoogleFonts.inter(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to permanently delete "${product.name}"? This action cannot be undone.',
          style: TextStyle(color: theme.colorScheme.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: theme.colorScheme.secondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(productsStateProvider.notifier).deleteProduct(product.id).then((_) {
                if (context.mounted) ZannyFeedback.showSuccess(context, 'Product deleted successfully');
              }).catchError((e) {
                if (context.mounted) ZannyFeedback.showError(context, 'Failed to delete product: $e');
              });
            },
            child: Text('Delete', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteStyle(BuildContext context, String id) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outline),
        ),
        title: Text(
          'Delete Street Style',
          style: GoogleFonts.inter(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to permanently delete this lookbook? This action cannot be undone.',
          style: TextStyle(color: theme.colorScheme.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: theme.colorScheme.secondary)),
          ),
          TextButton(
            onPressed: () {
              ref.read(streetStylesProvider.notifier).deleteStyle(id);
              Navigator.of(context).pop();
              ZannyFeedback.showSuccess(context, 'Street style deleted successfully');
            },
            child: Text('Delete', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, ThemeData theme) {
    final orders = ref.watch(adminOrdersProvider);
    final validOrders = orders.where((order) {
      final isTest = order.id.toLowerCase().contains('test');
      final isEmpty = order.items.isEmpty;
      return !isTest && !isEmpty;
    }).toList();

    if (validOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(adminOrdersProvider.notifier).refresh(),
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
                  'No orders yet',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(adminOrdersProvider.notifier).refresh(),
      color: theme.colorScheme.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80, top: 8),
        itemCount: validOrders.length,
        itemBuilder: (context, index) {
          final order = validOrders[index];
          return _AdminOrderCard(order: order);
        },
      ),
    );
  }

  Widget _buildAnalyticsSection(BuildContext context, ThemeData theme) {
    final allOrders = ref.watch(adminOrdersProvider);
    
    // Filter out invalid test/empty orders
    final validOrders = allOrders.where((order) {
      final isTest = order.id.toLowerCase().contains('test');
      final isEmpty = order.items.isEmpty;
      return !isTest && !isEmpty;
    }).toList();

    // 1. Calculate stats
    double totalRevenue = 0;
    int ordersToDeliver = 0;
    
    final now = DateTime.now();
    int todayOrdersCount = 0;
    double todayRevenue = 0;

    for (final order in validOrders) {
      totalRevenue += order.totalAmount;
      if (order.status == 'pending' || order.status == 'confirmed' || order.status == 'shipped' || order.status == 'delivering') {
        ordersToDeliver++;
      }
      
      final isToday = order.createdAt.year == now.year &&
                      order.createdAt.month == now.month &&
                      order.createdAt.day == now.day;
      if (isToday) {
        todayOrdersCount++;
        todayRevenue += order.totalAmount;
      }
    }

    // 2. Calculate best-selling products
    final Map<String, int> productSales = {};
    final Map<String, Product> productDetails = {};
    for (final order in validOrders) {
      for (final item in order.items) {
        final pid = item.product.id;
        productSales[pid] = (productSales[pid] ?? 0) + item.quantity;
        productDetails[pid] = item.product;
      }
    }

    final sortedSales = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final maxSalesVal = sortedSales.isNotEmpty ? sortedSales.first.value : 1;

    return RefreshIndicator(
      onRefresh: () => ref.read(adminOrdersProvider.notifier).refresh(),
      color: theme.colorScheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'PERFORMANCE SUMMARY',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 12),
          
          // Row of Stat Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Today\'s Orders',
                  todayOrdersCount.toString(),
                  'KES ${todayRevenue.toStringAsFixed(0)}',
                  Icons.today_rounded,
                  theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'To Deliver',
                  ordersToDeliver.toString(),
                  'Pending Delivery',
                  Icons.local_shipping_outlined,
                  theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildStatCard(
            'Total Revenue',
            'KES ${totalRevenue.toStringAsFixed(0)}',
            'From ${validOrders.length} valid orders',
            Icons.account_balance_wallet_outlined,
            theme,
            fullWidth: true,
          ),
          
          const SizedBox(height: 28),
          Text(
            'BEST SELLING PRODUCTS',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 12),

          if (sortedSales.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Center(
                child: Text(
                  'No sales data available yet',
                  style: GoogleFonts.inter(color: theme.colorScheme.secondary, fontSize: 13),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: math.min(sortedSales.length, 5),
                separatorBuilder: (_, __) => Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline),
                itemBuilder: (ctx, idx) {
                  final entry = sortedSales[idx];
                  final product = productDetails[entry.key]!;
                  final quantity = entry.value;
                  final relativeBarValue = quantity / maxSalesVal;

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: theme.colorScheme.outline.withValues(alpha: 0.3),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: product.images.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: product.images.first,
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
                                product.name,
                                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: relativeBarValue,
                                        minHeight: 4,
                                        backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '$quantity sold',
                                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    ThemeData theme, {
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: theme.colorScheme.secondary, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.playfairDisplay(fontSize: fullWidth ? 20 : 18, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.secondary),
              ),
            ],
          ),
          Icon(icon, color: theme.colorScheme.primary.withValues(alpha: 0.6), size: 24),
        ],
      ),
    );
  }

  Widget _buildAdvertsSection(BuildContext context, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BROADCAST CUSTOM ADVERT',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send an instant high-priority push notification broadcast to all registered devices and users.',
            style: GoogleFonts.inter(color: theme.colorScheme.secondary, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 24),
          
          // Form Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Campaign Title', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 6),
                TextField(
                  controller: _advTitleController,
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'e.g. New Streetwear Drop! 🚀',
                    hintStyle: TextStyle(color: theme.colorScheme.secondary.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: theme.colorScheme.outline.withValues(alpha: 0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 18),
                
                Text('Advert Message Body', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 6),
                TextField(
                  controller: _advBodyController,
                  maxLines: 4,
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'e.g. Premium graphic hoodies and cargo pants restocked in all sizes. Tap to shop the new season.',
                    hintStyle: TextStyle(color: theme.colorScheme.secondary.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: theme.colorScheme.outline.withValues(alpha: 0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 18),
                
                Text('Target Screen Route (Deep Link)', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 6),
                TextField(
                  controller: _advRouteController,
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'e.g. /profile, /orders, /product/123',
                    hintStyle: TextStyle(color: theme.colorScheme.secondary.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: theme.colorScheme.outline.withValues(alpha: 0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _sendingAdvert ? null : () => _sendCustomBroadcast(theme),
                    child: _sendingAdvert
                        ? const ShimmerPlaceholder(width: 20, height: 20, borderRadius: 10)
                        : Text('SEND BROADCAST', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildHomepageBannerSection(context, theme),
        ],
      ),
    );
  }

  Future<void> _changeBannerImage(BuildContext context, ThemeData theme) async {
    final messenger = ScaffoldMessenger.of(context);
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _updatingBanner = true;
    });

    try {
      final repo = ref.read(adminRepositoryProvider);
      final uploadedUrl = await repo.uploadProductImage(file);

      final api = ApiClient.instance;
      final response = await api.put(
        '/api/settings/homepage_banner_url',
        data: {'value': uploadedUrl},
      );

      if (response.statusCode == 200) {
        ref.read(bannerImageProvider.notifier).updateBanner(uploadedUrl);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Homepage banner updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        throw Exception(response.data?['error'] ?? 'Server error');
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update banner: $e'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingBanner = false;
        });
      }
    }
  }

  Widget _buildHomepageBannerSection(BuildContext context, ThemeData theme) {
    final bannerUrl = ref.watch(bannerImageProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOMEPAGE HERO BANNER',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload and configure the dynamic banner image displayed at the top of the homepage.',
          style: GoogleFonts.inter(color: theme.colorScheme.secondary, fontSize: 12.5, height: 1.4),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Banner Preview',
                style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: bannerUrl,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => Container(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                    errorWidget: (ctx, url, err) => Container(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      child: const Icon(Icons.broken_image_outlined, size: 36),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _updatingBanner ? null : () => _changeBannerImage(context, theme),
                  child: _updatingBanner
                      ? const ShimmerPlaceholder(width: 20, height: 20, borderRadius: 10)
                      : Text('CHANGE BANNER IMAGE', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(BuildContext context, ThemeData theme) {
    final reviewsAsync = ref.watch(adminReviewsProvider);
    final isDark = theme.brightness == Brightness.dark;

    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 64,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'NO REVIEWS SUBMITTED YET',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(adminReviewsProvider.future),
          color: theme.colorScheme.primary,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final r = reviews[index];
              final dateStr = _formatReviewDate(r.createdAt);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product image preview
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF3F4F6),
                            border: Border.all(color: theme.colorScheme.outline, width: 0.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: r.productImage.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: r.productImage,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => const Icon(Icons.image_outlined, size: 20),
                                  )
                                : const Icon(Icons.image_outlined, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.productName.isNotEmpty ? r.productName : 'Unknown Product',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Order ID: ${r.orderId}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: theme.colorScheme.outline, thickness: 0.5),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(5, (starIdx) {
                            final filled = starIdx < r.rating;
                            return Icon(
                              filled ? Icons.star_rounded : Icons.star_border_rounded,
                              color: filled ? AppColors.accentGold : theme.colorScheme.secondary.withValues(alpha: 0.5),
                              size: 16,
                            );
                          }),
                        ),
                        Text(
                          dateStr,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (r.comment.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        r.comment,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: theme.colorScheme.primary.withValues(alpha: 0.9),
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Divider(color: theme.colorScheme.outline, thickness: 0.5),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 14, color: theme.colorScheme.secondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${r.fullName} (${r.email})',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Failed to load reviews.',
          style: GoogleFonts.inter(color: AppColors.error),
        ),
      ),
    );
  }

  String _formatReviewDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _sendCustomBroadcast(ThemeData theme) async {
    final title = _advTitleController.text.trim();
    final body = _advBodyController.text.trim();
    final route = _advRouteController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ZannyFeedback.showError(context, 'Please fill out both Title and Message fields');
      return;
    }

    setState(() => _sendingAdvert = true);
    
    try {
      await ApiClient.instance.post('/api/advertise', data: {
        'title': title,
        'body': body,
        'route': route,
      });

      if (mounted) {
        setState(() => _sendingAdvert = false);
        _advTitleController.clear();
        _advBodyController.clear();
        
        ZannyFeedback.showSuccess(context, 'Advert broadcasted successfully to all users!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sendingAdvert = false);
        ZannyFeedback.showError(context, 'Failed to broadcast: $e');
      }
    }
  }
}

class _AdminProductListItem extends StatelessWidget {
  final Product product;
  final VoidCallback onDelete;

  const _AdminProductListItem({
    required this.product,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasStock = product.stock > 0;
    final isLowStock = product.stock <= 5;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Image
              SizedBox(
                width: 90,
                child: CachedNetworkImage(
                  imageUrl: product.images.isNotEmpty
                      ? product.images.first
                      : 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?q=80&w=600',
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: theme.colorScheme.outline,
                    child: Icon(Icons.image_not_supported_outlined, color: theme.colorScheme.secondary.withValues(alpha: 0.5)),
                  ),
                ),
              ),
              
              // Product Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                product.category.toUpperCase(),
                                style: TextStyle(
                                  color: theme.colorScheme.secondary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (product.isNew)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'NEW',
                                    style: TextStyle(
                                      color: theme.colorScheme.onPrimary,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 4),
                              if (product.isSale)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.sale,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'SALE',
                                    style: TextStyle(
                                      color: theme.colorScheme.onPrimary,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'KSH ${product.price.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isLowStock
                                  ? (hasStock ? AppColors.sale.withValues(alpha: 0.15) : theme.colorScheme.error.withValues(alpha: 0.15))
                                  : AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              hasStock ? 'Stock: ${product.stock}' : 'Out of Stock',
                              style: TextStyle(
                                color: isLowStock
                                    ? (hasStock ? AppColors.sale : theme.colorScheme.error)
                                    : AppColors.success,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: theme.colorScheme.outline),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Edit Button
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary, size: 20),
                      onPressed: () => context.push('/admin/add-product', extra: product),
                    ),
                    // Delete Button
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error, size: 20),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminStyleListItem extends StatelessWidget {
  final StreetStyle style;
  final VoidCallback onDelete;

  const _AdminStyleListItem({required this.style, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Style Image
              SizedBox(
                width: 90,
                child: CachedNetworkImage(
                  imageUrl: style.images.isNotEmpty ? style.images.first : '',
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: theme.colorScheme.outline,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        style.username,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 12, color: theme.colorScheme.secondary),
                          const SizedBox(width: 4),
                          Text(
                            style.location,
                            style: TextStyle(color: theme.colorScheme.secondary, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        style.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: theme.colorScheme.secondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: theme.colorScheme.outline)),
                ),
                child: Center(
                  child: IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error, size: 20),
                    onPressed: onDelete,
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

class _AdminOrderCard extends ConsumerStatefulWidget {
  final Order order;
  const _AdminOrderCard({required this.order});

  @override
  ConsumerState<_AdminOrderCard> createState() => _AdminOrderCardState();
}

class _AdminOrderCardState extends ConsumerState<_AdminOrderCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.order;
    final isLight = theme.brightness == Brightness.light;
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
                    ...order.items.map((item) {
                      final isConfirmed = item.isConfirmed;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                isConfirmed
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: isConfirmed
                                    ? AppColors.success
                                    : theme.colorScheme.secondary.withValues(alpha: 0.6),
                                size: 22,
                              ),
                              onPressed: () {
                                final updatedItems = order.items.map((i) {
                                  if (i.product.id == item.product.id &&
                                      i.selectedColor == item.selectedColor &&
                                      i.selectedSize == item.selectedSize) {
                                    return i.copyWith(isConfirmed: !i.isConfirmed);
                                  }
                                  return i;
                                }).toList();
                                ref.read(adminOrdersProvider.notifier).updateOrderItemsAndStatus(
                                  order.id,
                                  order.status,
                                  updatedItems,
                                );
                              },
                            ),
                            const SizedBox(width: 8),
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
                                      color: isConfirmed
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                      decoration: isConfirmed
                                          ? TextDecoration.none
                                          : TextDecoration.lineThrough,
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
                                color: isConfirmed
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                decoration: isConfirmed
                                    ? TextDecoration.none
                                    : TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    const Divider(height: 1, thickness: 0.5),
                    const SizedBox(height: 16),

                    // Admin Actions
                    Text(
                      'UPDATE ORDER STATUS',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (order.status == 'pending')
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Colors.blue),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => ref.read(adminOrdersProvider.notifier).updateOrderItemsAndStatus(order.id, 'confirmed', order.items),
                              child: Text(
                                'CONFIRM ORDER',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.blue),
                              ),
                            ),
                          ),
                        if (order.status == 'confirmed')
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Colors.purple),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => ref.read(adminOrdersProvider.notifier).updateOrderItemsAndStatus(order.id, 'shipped', order.items),
                              child: Text(
                                'INITIATE DELIVERY',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.purple),
                              ),
                            ),
                          ),
                        if (order.status == 'shipped' || order.status == 'delivering')
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: AppColors.success),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => ref.read(adminOrdersProvider.notifier).updateOrderItemsAndStatus(order.id, 'delivered', order.items),
                              child: Text(
                                'MARK DELIVERED',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success),
                              ),
                            ),
                          ),
                        if (order.status == 'delivered')
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'ORDER COMPLETED & DELIVERED',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success),
                              ),
                            ),
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
