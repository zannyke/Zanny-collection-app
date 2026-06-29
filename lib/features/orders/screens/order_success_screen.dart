import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/models/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/animations.dart';

class OrderSuccessScreen extends StatefulWidget {
  final Order order;
  const OrderSuccessScreen({super.key, required this.order});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: Curves.easeOutBack,
      ),
    );

    _checkController.forward();
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLight = !isDark;
    final order = widget.order;
    final now = DateTime.now();
    final formattedDate = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year.toString().substring(2)} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final scaffoldBg = isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF0F7FF);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Checked Icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0x1A1CB86E)
                        : const Color(0xFFDBEAFE),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? const Color(0x331CB86E)
                          : const Color(0xFF93C5FD),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: isDark
                        ? const Color(0xFF1CB86E)
                        : const Color(0xFF1D4ED8),
                    size: 38,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Title
              FadeInSlide(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Your order has been\nsuccessfully submitted',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Order detail card matching checkout_success screenshot
              FadeInSlide(
                delay: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFBFDBFE),
                      width: 0.5,
                    ),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(context, 'Order ID', order.id.replaceAll('ZC_ORD_', '')),
                      _buildDivider(context),
                      _buildInfoRow(context, 'Payment Method', order.totalAmount > 0 ? 'Cash on Delivery' : 'M-Pesa'),
                      _buildDivider(context),
                      _buildInfoRow(context, 'Date & Time', formattedDate),
                      _buildDivider(context),
                      _buildInfoRow(
                        context,
                        'Total',
                        'KES ${order.totalAmount.toStringAsFixed(0)}',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // "Go to my account" action button matching screen
              FadeInSlide(
                delay: const Duration(milliseconds: 600),
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/profile');
                    context.push('/orders');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : const Color(0xFF1D4ED8),
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(double.infinity, 56),
                    elevation: 0,
                  ),
                  child: Text(
                    'Go to my account',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              
              FadeInSlide(
                delay: const Duration(milliseconds: 700),
                child: TextButton(
                  onPressed: () => context.go('/'),
                  child: Text(
                    'Continue Shopping',
                    style: GoogleFonts.inter(
                      color: isLight ? const Color(0xFF2563EB) : Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {bool isTotal = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: isDark ? Colors.white38 : const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: isTotal 
                  ? (isDark ? AppColors.accentGold : const Color(0xFF1E3A8A)) 
                  : theme.colorScheme.onSurface,
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFBFDBFE),
      height: 1,
      thickness: 0.5,
    );
  }
}
