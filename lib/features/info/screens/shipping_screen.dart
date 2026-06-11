import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class ShippingScreen extends StatelessWidget {
  const ShippingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('SHIPPING & RETURNS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shipping &\nReturns',
                      style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.2)),
                  const SizedBox(height: 8),
                  Text('Everything you need to know about delivery and returns.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _ShippingSection(
                    title: 'DELIVERY TIMES',
                    icon: Icons.schedule_outlined,
                    rows: [
                      ('Nairobi CBD & suburbs', '1–2 business days'),
                      ('Other Nairobi areas', '2–3 business days'),
                      ('Major towns (outside NBI)', '2–5 business days'),
                      ('Remote areas', '5–7 business days'),
                    ],
                  ),
                  _ShippingSection(
                    title: 'DELIVERY FEES',
                    icon: Icons.local_shipping_outlined,
                    rows: [
                      ('Nairobi delivery', 'KES 200–300'),
                      ('Outside Nairobi', 'KES 400–600'),
                      ('Free delivery threshold', 'Orders above KES 5,000'),
                    ],
                  ),
                  _ShippingSection(
                    title: 'RETURN POLICY',
                    icon: Icons.keyboard_return_outlined,
                    rows: [
                      ('Return window', '14 days from delivery'),
                      ('Condition', 'Unworn, original packaging, tags attached'),
                      ('Sale items', 'Final sale — not returnable'),
                    ],
                  ),
                  _ShippingSection(
                    title: 'HOW TO RETURN',
                    icon: Icons.assignment_return_outlined,
                    rows: [
                      ('Step 1', 'Contact us via WhatsApp or email'),
                      ('Step 2', 'Get your return authorisation number'),
                      ('Step 3', 'Package item securely with all tags'),
                      ('Step 4', 'Drop off or arrange collection'),
                      ('Step 5', 'Refund in 5–7 business days'),
                    ],
                  ),

                  const SizedBox(height: 8),
                  // CTA
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 0.5), color: AppColors.surface),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Have a question about your order?',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Text('Our team is ready to help.',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.push('/contact'),
                          child: Text('CONTACT SUPPORT',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
                        ),
                      ],
                    ),
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

class _ShippingSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<(String, String)> rows;

  const _ShippingSection({required this.title, required this.icon, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 0.5)),
          child: Column(
            children: rows.mapIndexed((index, row) => Column(
              children: [
                if (index > 0) const Divider(color: AppColors.border, height: 0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2,
                        child: Text(row.$1, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary))),
                      Expanded(flex: 3,
                        child: Text(row.$2, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
                    ],
                  ),
                ),
              ],
            )).toList(),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

// Helper extension
extension _IndexedMap<T> on List<T> {
  List<R> mapIndexed<R>(R Function(int index, T item) f) {
    return asMap().entries.map((e) => f(e.key, e.value)).toList();
  }
}
