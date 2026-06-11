import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class FaqsScreen extends StatelessWidget {
  const FaqsScreen({super.key});

  static const _faqs = [
    ('How long does delivery take?', 'Orders within Nairobi are delivered within 1–2 business days. Orders outside Nairobi take 2–5 business days depending on your location.'),
    ('What payment methods do you accept?', 'We accept M-Pesa, Visa, Mastercard, and cash on delivery for select locations.'),
    ('Can I return or exchange my order?', 'Yes! We offer a 14-day return and exchange policy. Items must be unworn, unwashed, and in original packaging.'),
    ('How do I know my size?', 'We provide a size guide on every product page. If you\'re between sizes, we recommend sizing up for a relaxed fit.'),
    ('Do you ship internationally?', 'Currently we ship within Kenya only. International shipping is coming soon.'),
    ('How do I track my order?', 'Once your order is shipped, you\'ll receive an SMS/email with a tracking number.'),
    ('What if my item arrives damaged?', 'Contact us immediately via WhatsApp or email with photos and we\'ll resolve it within 24 hours.'),
    ('Can I cancel my order?', 'Orders can be cancelled within 2 hours of placement. After that, we may have already begun processing.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('FAQs', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 3)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Text(
            'Frequently Asked\nQuestions',
            style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.2),
          ),
          const SizedBox(height: 24),
          ..._faqs.map((faq) => _FaqTile(question: faq.$1, answer: faq.$2)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 0.5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Still have questions?', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                Text('Our team is happy to help.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.push('/contact'),
                  child: Text('CONTACT US', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.4),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(_expanded ? Icons.remove : Icons.add, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(widget.answer, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
          ),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        const Divider(color: AppColors.border, height: 0),
      ],
    );
  }
}
