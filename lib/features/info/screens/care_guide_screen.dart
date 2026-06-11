import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class CareGuideScreen extends StatelessWidget {
  const CareGuideScreen({super.key});

  static const _sections = [
    _CareData(
      Icons.local_laundry_service_outlined,
      'WASHING',
      [
        'Machine wash cold (30°C or below)',
        'Use a gentle cycle with mild detergent',
        'Turn garments inside out before washing',
        'Wash darks and lights separately',
        'Do not use bleach or harsh chemicals',
        'Hand wash delicate items',
      ],
    ),
    _CareData(
      Icons.air_outlined,
      'DRYING',
      [
        'Air dry flat to maintain shape and fit',
        'Avoid tumble drying (unless label says otherwise)',
        'Keep away from direct sunlight when drying',
        'Do not wring or twist — gently squeeze out water',
        'Hang hoodies and sweaters to avoid stretching',
      ],
    ),
    _CareData(
      Icons.iron_outlined,
      'IRONING',
      [
        'Iron on low to medium heat setting',
        'Use a pressing cloth over printed graphics',
        'Never iron directly on embroidery or logos',
        'A steam iron is preferred for best results',
        'Iron inside-out for printed tees',
      ],
    ),
    _CareData(
      Icons.inventory_2_outlined,
      'STORAGE',
      [
        'Store folded in a cool, dry, and dark place',
        'Hang heavier items (hoodies, sweaters) to prevent creasing',
        'Use cedar balls or sachets to naturally repel moths',
        'Avoid plastic bags for long-term storage — use fabric bags',
        'Keep shoes in their boxes with tissue stuffing',
      ],
    ),
    _CareData(
      Icons.dry_cleaning_outlined,
      'SPECIAL CARE',
      [
        'Shoes: wipe with a clean damp cloth after each wear',
        'Accessories: store separately to avoid scratches',
        'Innerwear: always wash before first wear',
        'White garments: wash separately to prevent colour transfer',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('CARE GUIDE', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 3)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero banner
            Container(
              height: 180,
              width: double.infinity,
              color: AppColors.surface,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.background.withOpacity(0.3), AppColors.background.withOpacity(0.9)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Care Guide',
                          style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Keep your Zanny pieces premium for longer.',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: _sections.map((section) => _CareSectionWidget(data: section)).toList(),
              ),
            ),

            // Bottom CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border, width: 0.5),
                  color: AppColors.surface,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.help_outline, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Still unsure?', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          Text('Contact our support team for specific care advice.',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => context.push('/contact'),
                      child: Text('Chat →', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CareData {
  final IconData icon;
  final String title;
  final List<String> tips;
  const _CareData(this.icon, this.title, this.tips);
}

class _CareSectionWidget extends StatefulWidget {
  final _CareData data;
  const _CareSectionWidget({required this.data});
  @override
  State<_CareSectionWidget> createState() => _CareSectionWidgetState();
}

class _CareSectionWidgetState extends State<_CareSectionWidget> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Icon(widget.data.icon, size: 18, color: AppColors.textPrimary),
                const SizedBox(width: 12),
                Text(
                  widget.data.title,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.textPrimary),
                ),
                const Spacer(),
                Icon(_expanded ? Icons.remove : Icons.add, size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.data.tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, size: 4, color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(tip, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ),
        const Divider(color: AppColors.border, height: 0),
      ],
    );
  }
}
