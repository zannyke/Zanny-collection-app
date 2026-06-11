import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/animations.dart';

class WorldOfZannyScreen extends StatelessWidget {
  const WorldOfZannyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('WORLD OF ZANNY', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 2.5)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image area
            Container(
              height: 280,
              width: double.infinity,
              color: AppColors.surfaceElevated,
              child: CachedNetworkImage(
                imageUrl: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?q=80&w=800',
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: ZannyLoadingIndicator(
                    size: 28,
                    color: AppColors.textSecondary,
                  ),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.image_outlined, color: AppColors.textMuted, size: 48),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The World of\nZanny',
                    style: GoogleFonts.playfairDisplay(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.2),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Zanny Collection was born from a simple belief: that premium fashion '
                    'should be accessible to everyone on their way up. Founded in Kenya, '
                    'we curate and create pieces that blend international streetwear '
                    'aesthetics with the hustle and pride of African youth culture.',
                    style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary, height: 1.8),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'OUR PHILOSOPHY',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Every piece in the Zanny Collection is carefully selected or designed '
                    'to make you feel confident, comfortable, and undeniably stylish. '
                    'We believe clothes are more than fabric — they\'re a statement of where '
                    'you\'re going.',
                    style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary, height: 1.8),
                  ),
                  const SizedBox(height: 32),
                  // Stats row
                  Row(
                    children: [
                      _Stat('5K+', 'Happy Customers'),
                      const SizedBox(width: 1),
                      _Stat('200+', 'Products'),
                      const SizedBox(width: 1),
                      _Stat('100%', 'Authentic'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'THE HUSTLE IS REAL',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'At Zanny, we understand the grind. That\'s why we offer fast delivery, '
                    'easy returns, and prices that make sense. Because when you\'re hustling, '
                    'you shouldn\'t have to compromise on how you look.',
                    style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary, height: 1.8),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        color: AppColors.surface,
        child: Column(
          children: [
            Text(value, style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, letterSpacing: 0.5), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
