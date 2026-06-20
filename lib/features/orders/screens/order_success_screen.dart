import 'dart:ui';
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
  late Animation<double> _glowOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _glowOpacityAnimation = Tween<double>(begin: 0.0, end: 0.18).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
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
    final order = widget.order;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Animated Glowing Checkmark
              AnimatedBuilder(
                animation: _checkController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Inner Glow
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentGold.withValues(alpha: _glowOpacityAnimation.value),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      // Scale Check Circle
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.accentGold, width: 2),
                            color: AppColors.background,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: AppColors.accentGold,
                            size: 44,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Headline
              FadeInSlide(
                delay: const Duration(milliseconds: 300),
                child: Text(
                  'ORDER PLACED',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeInSlide(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  'Thank you for your purchase. We are preparing your order.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: theme.colorScheme.secondary,
                    height: 1.5,
                  ),
                ),
              ),

              const Spacer(),

              // Glassmorphic Order Summary Info Card
              FadeInSlide(
                delay: const Duration(milliseconds: 600),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.colorScheme.outline, width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ORDER ID',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.secondary,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                order.id,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, thickness: 0.5),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TOTAL PAID',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.secondary,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                'KES ${order.totalAmount.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accentGold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, thickness: 0.5),
                          const SizedBox(height: 12),
                          Text(
                            'DELIVERING TO',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.secondary,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${order.recipientName}  |  ${order.recipientPhone}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.deliveryAddress,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Action Buttons
              FadeInSlide(
                delay: const Duration(milliseconds: 800),
                child: Column(
                  children: [
                    PremiumButton(
                      text: 'Track Order',
                      type: PremiumButtonType.primary,
                      onPressed: () {
                        context.go('/profile');
                        context.push('/orders');
                      },
                    ),
                    const SizedBox(height: 12),
                    PremiumButton(
                      text: 'Continue Shopping',
                      type: PremiumButtonType.secondary,
                      onPressed: () {
                        context.go('/');
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
