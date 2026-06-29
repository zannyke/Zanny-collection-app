import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/product_provider.dart';
import '../../../core/theme/app_colors.dart';

class ProductReviewsScreen extends ConsumerWidget {
  final String productId;
  final String productName;

  const ProductReviewsScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reviewsAsync = ref.watch(productReviewsProvider(productId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'REVIEWS',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 24, right: 24),
            child: Text(
              productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
        ),
      ),
      body: reviewsAsync.when(
        data: (summary) {
          if (summary.total == 0) {
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
                    'NO REVIEWS YET',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to review this product after purchase.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(productReviewsProvider(productId).future),
            color: theme.colorScheme.primary,
            child: CustomScrollView(
              slivers: [
                // Summary block
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141414) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column: big rating
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  summary.average.toStringAsFixed(1),
                                  style: GoogleFonts.inter(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(5, (index) {
                                    final fill = summary.average - index;
                                    IconData icon = Icons.star_border_rounded;
                                    if (fill >= 1) {
                                      icon = Icons.star_rounded;
                                    } else if (fill >= 0.5) {
                                      icon = Icons.star_half_rounded;
                                    }
                                    return Icon(
                                      icon,
                                      color: AppColors.accentGold,
                                      size: 16,
                                    );
                                  }),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${summary.total} reviews',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Right column: bars distribution
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: List.generate(5, (index) {
                                final starNum = 5 - index;
                                final pct = summary.distribution[starNum] ?? 0.0;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      Text(
                                        '$starNum',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.star_rounded,
                                        color: AppColors.accentGold,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: pct / 100.0,
                                            minHeight: 6,
                                            backgroundColor: isDark
                                                ? const Color(0xFF2A2A2A)
                                                : const Color(0xFFE5E5E5),
                                            valueColor: const AlwaysStoppedAnimation(
                                              AppColors.accentGold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 28,
                                        child: Text(
                                          '${pct.toStringAsFixed(0)}%',
                                          textAlign: TextAlign.end,
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.secondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Reviews list header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      'ALL REVIEWS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),

                // Review items
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final r = summary.reviews[index];
                        final dateStr = _formatDate(r.createdAt);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF141414) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: isDark
                                        ? const Color(0xFF2A2A2A)
                                        : const Color(0xFFF1F5F9),
                                    backgroundImage: r.avatarUrl.isNotEmpty
                                        ? NetworkImage(r.avatarUrl)
                                        : null,
                                    child: r.avatarUrl.isEmpty
                                        ? Text(
                                            r.fullName.isNotEmpty
                                                ? r.fullName.substring(0, 1).toUpperCase()
                                                : 'A',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: theme.colorScheme.primary,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.fullName.isNotEmpty ? r.fullName : 'Anonymous',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Row(
                                              children: List.generate(5, (starIdx) {
                                                final filled = starIdx < r.rating;
                                                return Icon(
                                                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                                                  color: filled
                                                      ? AppColors.accentGold
                                                      : theme.colorScheme.secondary.withValues(alpha: 0.5),
                                                  size: 14,
                                                );
                                              }),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              dateStr,
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                color: theme.colorScheme.secondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
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
                            ],
                          ),
                        );
                      },
                      childCount: summary.reviews.length,
                    ),
                  ),
                ),
              ],
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
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}
