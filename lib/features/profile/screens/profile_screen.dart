import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/wishlist_provider.dart';
import '../../../shared/providers/cart_provider.dart';
import 'package:url_launcher/url_launcher.dart';


class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isSignedIn = authState.isSignedIn;
    final user = authState.user;
    final wishlistCount = ref.watch(wishlistCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('PROFILE', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 3)),
        actions: [
          if (isSignedIn)
            IconButton(
              icon: const Icon(Icons.logout_outlined, size: 20),
              onPressed: () => _confirmSignOut(context, ref),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Profile Header ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              color: AppColors.surface,
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 0.5),
                      color: AppColors.surfaceElevated,
                    ),
                    child: user?.userMetadata?['avatar_url'] != null
                        ? ClipOval(child: Image.network(user!.userMetadata!['avatar_url'], fit: BoxFit.cover))
                        : const Icon(Icons.person_outline, size: 32, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),

                  if (isSignedIn) ...[
                    Text(
                      user?.userMetadata?['full_name'] ?? 'Zanny Member',
                      style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    // Quick stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatChip(Icons.favorite_outline, '$wishlistCount', 'Saved'),
                        const SizedBox(width: 20),
                        _StatChip(Icons.shopping_bag_outlined, '${ref.watch(cartCountProvider)}', 'In Cart'),
                      ],
                    ),
                  ] else ...[
                    Text('Guest User',
                        style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => context.push('/login'),
                            child: Text('SIGN IN', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.push('/register'),
                            child: Text('REGISTER', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Account Menu ─────────────────────────────────────────────────
            if (isSignedIn) ...[
              _SectionHeader('ACCOUNT'),
              _MenuItem(icon: Icons.shopping_bag_outlined, label: 'My Orders', badge: null, onTap: () {}),
              _MenuItem(icon: Icons.favorite_outline, label: 'Wishlist', badge: wishlistCount > 0 ? '$wishlistCount' : null,
                  onTap: () => context.push('/wishlist')),
              _MenuItem(icon: Icons.location_on_outlined, label: 'Saved Addresses', onTap: () {}),
              _MenuItem(icon: Icons.person_outline, label: 'Edit Profile', onTap: () {}),
              const SizedBox(height: 8),
            ],

            // ── Customer Care ────────────────────────────────────────────────
            _SectionHeader('CUSTOMER CARE'),
            _MenuItem(icon: Icons.help_outline, label: 'FAQs', onTap: () => context.push('/faqs')),
            _MenuItem(icon: Icons.local_shipping_outlined, label: 'Shipping & Returns', onTap: () => context.push('/shipping')),
            _MenuItem(icon: Icons.dry_cleaning_outlined, label: 'Care Guide', onTap: () => context.push('/care-guide')),
            _MenuItem(icon: Icons.mail_outline, label: 'Contact Us', onTap: () => context.push('/contact')),
            const SizedBox(height: 8),

            // ── About Zanny ──────────────────────────────────────────────────
            _SectionHeader('ABOUT'),
            _MenuItem(icon: Icons.auto_awesome_outlined, label: 'World of Zanny', onTap: () => context.push('/world-of-zanny')),
            _MenuItem(
              icon: Icons.language_outlined,
              label: 'Visit Website',
              onTap: () => _launchURL('https://zannycollection.com'),
            ),
            _MenuItem(
              icon: Icons.camera_alt_outlined,
              label: 'Follow on Instagram',
              onTap: () => _launchURL('https://www.instagram.com/zannycollection/'),
            ),
            const SizedBox(height: 8),

            // ── Legal ────────────────────────────────────────────────────────
            _SectionHeader('LEGAL'),
            _MenuItem(icon: Icons.description_outlined, label: 'Terms of Service', onTap: () {}),
            _MenuItem(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () {}),
            _MenuItem(icon: Icons.cookie_outlined, label: 'Cookie Policy', onTap: () {}),

            const SizedBox(height: 24),

            // App version
            Text('Zanny Collection v1.0.0',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch $urlString: $e');
    }
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text('Sign Out', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).signOut();
            },
            child: Text('Sign Out', style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatChip(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(title,
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.textMuted)),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, color: AppColors.textSecondary, size: 20),
      title: Text(label, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(badge!, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.background)),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
        ],
      ),
      onTap: onTap,
    );
  }
}
