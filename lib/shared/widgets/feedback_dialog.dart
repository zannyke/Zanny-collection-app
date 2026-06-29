import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/orders_provider.dart';
import '../../core/theme/app_colors.dart';

class FeedbackDialog extends ConsumerStatefulWidget {
  final String orderId;
  final String? preselectedProductId;
  const FeedbackDialog({super.key, required this.orderId, this.preselectedProductId});

  @override
  ConsumerState<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<FeedbackDialog> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _selectedProductId;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final orders = ref.watch(ordersProvider);
    final order = orders.where((o) => o.id == widget.orderId).firstOrNull;
    final items = order?.items ?? [];

    // Set initial selection: use preselectedProductId if provided, else default to first item
    if (_selectedProductId == null && items.isNotEmpty) {
      _selectedProductId = widget.preselectedProductId ?? items.first.product.id;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outline, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                // Top header icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.rate_review_outlined,
                    color: AppColors.accentGold,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'RATE YOUR EXPERIENCE',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your feedback helps us maintain our premium collection and service quality.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Order ID: ${widget.orderId}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 16),

                if (items.length > 1) ...[
                  Text(
                    'SELECT PRODUCT TO REVIEW',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 64,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = item.product.id == _selectedProductId;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedProductId = item.product.id;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accentGold
                                    : theme.colorScheme.outline,
                                width: isSelected ? 2 : 0.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                item.product.images.isNotEmpty
                                    ? item.product.images.first
                                    : '',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (_selectedProductId != null && items.isNotEmpty) ...[
                  Builder(
                    builder: (context) {
                      final selItem = items.firstWhere(
                        (i) => i.product.id == _selectedProductId,
                        orElse: () => items.first,
                      );
                      return Text(
                        selItem.product.name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Star rating selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final isSelected = index < _rating;
                    return IconButton(
                      onPressed: () {
                        setState(() {
                          _rating = index + 1;
                        });
                      },
                      icon: Icon(
                        isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                        color: isSelected ? AppColors.accentGold : theme.colorScheme.secondary,
                        size: 36,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),

                // Comments input
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  maxLength: 1000,
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts on the quality, size, fit or delivery...',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.secondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.outline, width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.primary, width: 1),
                    ),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: theme.colorScheme.outline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'LATER',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                setState(() {
                                  _isSubmitting = true;
                                });
                                final success = await ref
                                    .read(ordersProvider.notifier)
                                    .submitFeedback(
                                      orderId: widget.orderId,
                                      rating: _rating,
                                      comment: _commentController.text.trim(),
                                      productId: _selectedProductId,
                                    );
                                if (context.mounted) {
                                  setState(() {
                                    _isSubmitting = false;
                                  });
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Feedback submitted. Thank you!'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                  Navigator.pop(context);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Text(
                                'SUBMIT',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: theme.colorScheme.secondary.withValues(alpha: 0.6),
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    ),
  ),
);
  }
}
