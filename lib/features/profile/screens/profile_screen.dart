import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/wishlist_provider.dart';
import '../../../shared/providers/cart_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/update_service.dart';
import '../../../shared/widgets/shimmer_placeholder.dart';
import '../../../shared/widgets/custom_feedback.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isSignedIn = authState.isSignedIn;
    final user = authState.user;
    final wishlistCount = ref.watch(wishlistCountProvider);

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Header ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              color: theme.colorScheme.surface,
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 76, height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.outline, width: 0.5),
                      color: theme.colorScheme.surface,
                    ),
                    child: user?.userMetadata['avatar_url'] != null
                        ? ClipOval(child: Image.network(user!.userMetadata['avatar_url'] as String, fit: BoxFit.cover))
                        : Icon(Icons.person_outline, size: 32, color: theme.colorScheme.secondary),
                  ),
                  const SizedBox(height: 12),

                  if (isSignedIn) ...[
                    Text(
                      user?.userMetadata['full_name'] ?? 'Zanny Member',
                      style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.secondary),
                    ),
                    const SizedBox(height: 20),
                    // Quick stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatChip(Icons.favorite_outline, '$wishlistCount', 'Saved'),
                        const SizedBox(width: 28),
                        _StatChip(Icons.shopping_bag_outlined, '${ref.watch(cartCountProvider)}', 'In Cart'),
                      ],
                    ),
                  ] else ...[
                    Text('Guest User',
                        style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.push('/login'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.colorScheme.primary),
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text('SIGN IN', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: theme.colorScheme.primary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => context.push('/register'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                            child: Text('REGISTER', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Admin Menu ───────────────────────────────────────────────────
            if (isSignedIn && user?.email == 'admin@zannycollection.com') ...[
              const _SectionHeader('ADMINISTRATION'),
              _buildGroupCard(context, [
                _MenuItem(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Admin Panel',
                  onTap: () => context.push('/admin'),
                ),
              ]),
            ],

            // ── Account Menu ─────────────────────────────────────────────────
            if (isSignedIn) ...[
              const _SectionHeader('ACCOUNT'),
              _buildGroupCard(context, [
                _MenuItem(icon: Icons.shopping_bag_outlined, label: 'My Orders', onTap: () => context.push('/orders')),
                _MenuItem(
                  icon: Icons.favorite_outline, 
                  label: 'Wishlist', 
                  trailingText: wishlistCount > 0 ? '$wishlistCount items' : null,
                  onTap: () => context.push('/wishlist')
                ),
                _MenuItem(icon: Icons.location_on_outlined, label: 'Saved Addresses', onTap: () => context.push('/saved-addresses')),
                _MenuItem(icon: Icons.person_outline, label: 'Edit Profile', onTap: () => context.push('/edit-profile')),
              ]),
            ],

            // ── Preferences / Settings ───────────────────────────────────────
            const _SectionHeader('PREFERENCES'),
            _buildGroupCard(context, [
              const _ThemeSelectorTile(),
            ]),

            // ── Customer Care ────────────────────────────────────────────────
            const _SectionHeader('CUSTOMER CARE'),
            _buildGroupCard(context, [
              _MenuItem(icon: Icons.help_outline, label: 'FAQs', onTap: () => context.push('/faqs')),
              _MenuItem(icon: Icons.local_shipping_outlined, label: 'Shipping & Returns', onTap: () => context.push('/shipping')),
              _MenuItem(icon: Icons.dry_cleaning_outlined, label: 'Care Guide', onTap: () => context.push('/care-guide')),
              _MenuItem(icon: Icons.mail_outline, label: 'Contact Us', onTap: () => context.push('/contact')),
            ]),

            // ── About Zanny ──────────────────────────────────────────────────
            const _SectionHeader('ABOUT'),
            _buildGroupCard(context, [
              _MenuItem(icon: Icons.auto_awesome_outlined, label: 'World of Zanny', onTap: () => context.push('/world-of-zanny')),
              _MenuItem(
                icon: Icons.language_outlined,
                label: 'Visit Website',
                onTap: () => _launchURL('https://zannycollection.com'),
              ),
              _MenuItem(
                icon: Icons.camera_alt_outlined,
                label: 'Follow on Instagram',
                onTap: () => _launchURL('https://www.instagram.com/zannycollection_/'),
              ),
            ]),

            // ── Legal ────────────────────────────────────────────────────────
            const _SectionHeader('LEGAL'),
            _buildGroupCard(context, [
              _MenuItem(icon: Icons.description_outlined, label: 'Terms of Service', onTap: () => context.push('/terms')),
              _MenuItem(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () => context.push('/privacy')),
              _MenuItem(icon: Icons.cookie_outlined, label: 'Cookie Policy', onTap: () => context.push('/cookie')),
            ]),

            // ── App Version & Updates ──────────────────────────────────
            const _SectionHeader('APP UPDATES'),
            _UpdateHistoryCard(),

            if (isSignedIn) ...[
              const _SectionHeader('DANGER ZONE'),
              _buildGroupCard(context, [
                _MenuItem(
                  icon: Icons.delete_forever_outlined,
                  label: 'Delete Account',
                  textColor: AppColors.error,
                  iconColor: AppColors.error,
                  onTap: () => _confirmAccountDeletion(context, ref),
                ),
              ]),
            ],

            const SizedBox(height: 32),

            // Version footer
            Center(
              child: Text(
                'Zanny Collection v${UpdateService.currentVersion}',
                style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.secondary),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, List<Widget> children) {
    final theme = Theme.of(context);
    final itemsWithDividers = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      itemsWithDividers.add(children[i]);
      if (i < children.length - 1) {
        itemsWithDividers.add(
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
        child: Column(
          children: itemsWithDividers,
        ),
      ),
    );
  }

  void _confirmAccountDeletion(BuildContext context, WidgetRef ref) {
    final passwordCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final authState = ref.watch(authProvider);
            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              title: Text(
                'Delete Account',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WARNING: Permanent deletion. This will delete all your data and logout. Enter your password to confirm:',
                    style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.secondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  if (authState.error != null) ...[
                    Text(
                      authState.error!,
                      style: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.error, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Enter your password',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: authState.isLoading ? null : () => Navigator.pop(dialogCtx),
                  child: Text('Cancel', style: GoogleFonts.inter(color: theme.colorScheme.secondary)),
                ),
                TextButton(
                  onPressed: authState.isLoading
                      ? null
                      : () async {
                          ref.read(authProvider.notifier).clearError();
                          if (passwordCtrl.text.trim().isEmpty) {
                            ZannyFeedback.showError(context, 'Password is required');
                            return;
                          }
                          try {
                            await ref.read(authProvider.notifier).deleteAccount(passwordCtrl.text.trim());
                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                            }
                            if (context.mounted) {
                              ZannyFeedback.showSuccess(context, 'Your account has been deleted.');
                              context.go('/login');
                            }
                          } catch (_) {
                            setDialogState(() {});
                          }
                        },
                  child: authState.isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                          'DELETE PERMANENTLY',
                          style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            );
          },
        );
      },
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
      builder: (dialogCtx) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Text('Sign Out', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
          content: Text('Are you sure you want to sign out?',
              style: GoogleFonts.inter(fontSize: 14, color: theme.colorScheme.secondary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx),
                child: Text('Cancel', style: GoogleFonts.inter(color: theme.colorScheme.secondary))),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                ref.read(authProvider.notifier).signOut();
              },
              child: Text('Sign Out', style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
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
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.secondary)),
      ],
    );
  }
}

class _UpdateHistoryCard extends StatefulWidget {
  @override
  State<_UpdateHistoryCard> createState() => _UpdateHistoryCardState();
}

class _UpdateHistoryCardState extends State<_UpdateHistoryCard> {
  bool _checking = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.system_update_rounded, color: AppColors.accentGold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Version ${UpdateService.currentVersion}',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
                    ),
                    Text(
                      'Check for available updates',
                      style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.secondary),
                    ),
                  ],
                ),
              ),
              _checking
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: ShimmerPlaceholder(width: 16, height: 16, borderRadius: 8),
                    )
                  : TextButton.icon(
                      onPressed: () async {
                        setState(() => _checking = true);
                        try {
                          await UpdateService.checkForUpdate(context: context, showFeedback: true);
                        } finally {
                          if (mounted) setState(() => _checking = false);
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: const Text('Check'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accentGold,
                        textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: AppColors.accentGold.withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(title,
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: theme.colorScheme.secondary)),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingText;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingText,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: iconColor ?? theme.colorScheme.secondary, size: 20),
      title: Text(label, style: GoogleFonts.inter(fontSize: 14, color: textColor ?? theme.textTheme.bodyLarge?.color)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText!,
              style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.secondary),
            ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: theme.colorScheme.secondary.withValues(alpha: 0.5), size: 18),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _ThemeSelectorTile extends ConsumerWidget {
  const _ThemeSelectorTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    IconData icon;
    String modeText;
    switch (themeMode) {
      case ThemeMode.light:
        icon = Icons.light_mode_outlined;
        modeText = 'Light';
        break;
      case ThemeMode.dark:
        icon = Icons.dark_mode_outlined;
        modeText = 'Dark';
        break;
      case ThemeMode.system:
        icon = Icons.settings_brightness_outlined;
        modeText = 'System Default';
        break;
    }

    return _MenuItem(
      icon: icon,
      label: 'Theme Mode',
      trailingText: modeText,
      onTap: () => _showThemeSelectionSheet(context, ref, themeMode),
    );
  }

  void _showThemeSelectionSheet(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                'Select Theme Mode',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildThemeOption(context, ref, 'Light Mode', ThemeMode.light, currentMode == ThemeMode.light),
            _buildThemeOption(context, ref, 'Dark Mode', ThemeMode.dark, currentMode == ThemeMode.dark),
            _buildThemeOption(context, ref, 'System Default', ThemeMode.system, currentMode == ThemeMode.system),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, WidgetRef ref, String title, ThemeMode mode, bool isSelected) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.accentGold) : null,
      onTap: () {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }
}
