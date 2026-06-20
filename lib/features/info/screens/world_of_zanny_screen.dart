import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/providers/product_provider.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/animations.dart';

class WorldOfZannyScreen extends ConsumerWidget {
  const WorldOfZannyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'WORLD OF ZANNY',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
            color: theme.colorScheme.primary,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image area
            Container(
              height: 280,
              width: double.infinity,
              color: theme.colorScheme.surface,
              child: CachedNetworkImage(
                imageUrl: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?q=80&w=800',
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: ZannyLoadingIndicator(
                    size: 28,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Icon(Icons.image_outlined, color: theme.colorScheme.secondary, size: 48),
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
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Zanny Collection was born from a simple belief: that premium fashion '
                    'should be accessible to everyone on their way up. Founded in Kenya, '
                    'we curate and create pieces that blend international streetwear '
                    'aesthetics with the hustle and pride of African youth culture.',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: theme.colorScheme.secondary,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'OUR PHILOSOPHY',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Every piece in the Zanny Collection is carefully selected or designed '
                    'to make you feel confident, comfortable, and undeniably stylish. '
                    'We believe clothes are more than fabric — they\'re a statement of where '
                    'you\'re going.',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: theme.colorScheme.secondary,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Stats row
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(16),
                      color: theme.colorScheme.surface,
                    ),
                    child: Row(
                      children: [
                        const _Stat('5K+', 'Happy Customers'),
                        Container(width: 0.5, height: 40, color: theme.colorScheme.outline),
                        const _Stat('200+', 'Products'),
                        Container(width: 0.5, height: 40, color: theme.colorScheme.outline),
                        const _Stat('100%', 'Authentic'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'THE HUSTLE IS REAL',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'At Zanny, we understand the grind. That\'s why we offer fast delivery, '
                    'easy returns, and prices that make sense. Because when you\'re hustling, '
                    'you shouldn\'t have to compromise on how you look.',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: theme.colorScheme.secondary,
                      height: 1.8,
                    ),
                  ),
                ],
              ),
            ),
            const _ZannyOriginalsSection(),
            const SizedBox(height: 20),
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
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: theme.colorScheme.secondary,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ZannyOriginalsSection extends ConsumerWidget {
  const _ZannyOriginalsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final originalsAsync = ref.watch(zannyOriginalsProvider);
    final theme = Theme.of(context);

    return originalsAsync.when(
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Text(
                    'ZANNY ORIGINALS',
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
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
      loading: () => const SizedBox(
        height: 150,
        child: Center(child: ZannyLoadingIndicator(size: 24)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
