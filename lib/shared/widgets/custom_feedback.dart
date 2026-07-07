import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class ZannyFeedback {
  ZannyFeedback._();

  static void showSuccess(BuildContext context, String message) {
    // Uses a premium light blue / blue accent shade as requested
    const blueAccent = Color(0xFF42A5F5); 
    _show(
      context,
      message: message,
      icon: Icons.check_circle_outline_rounded,
      themeColor: blueAccent,
      glowColor: blueAccent,
    );
  }

  static void showError(BuildContext context, String message) {
    String cleanMessage = message.trim();
    if (cleanMessage.startsWith('Exception: ')) {
      cleanMessage = cleanMessage.substring(11);
    }
    
    final lower = cleanMessage.toLowerCase();
    if (lower.contains('dioexception') || 
        lower.contains('socketexception') || 
        lower.contains('httpstatus') || 
        lower.contains('failed host lookup') || 
        lower.contains('connection refused') ||
        lower.contains('connecttimeout') ||
        lower.contains('xmlhttprequest') ||
        lower.contains('cloudflare') ||
        lower.contains('sqlite') ||
        lower.contains('database') ||
        lower.contains('unhandled exception') ||
        lower.contains('500') ||
        lower.contains('/api/') ||
        lower.contains('d1_') ||
        lower.contains('path_provider') ||
        lower.contains('error_outline')) {
      cleanMessage = 'We are having trouble connecting to our servers. Please check your internet connection and try again.';
    }

    _show(
      context,
      message: cleanMessage,
      icon: Icons.error_outline_rounded,
      themeColor: AppColors.error,
      glowColor: AppColors.error,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color themeColor,
    required Color glowColor,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Feedback',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) {
        return _ZannyFeedbackDialogBody(
          message: message,
          icon: icon,
          themeColor: themeColor,
          glowColor: glowColor,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final scale = Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
        );
        final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: anim1, curve: Curves.easeOut),
        );
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 6.0 * anim1.value,
            sigmaY: 6.0 * anim1.value,
          ),
          child: FadeTransition(
            opacity: opacity,
            child: ScaleTransition(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _ZannyFeedbackDialogBody extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color themeColor;
  final Color glowColor;

  const _ZannyFeedbackDialogBody({
    required this.message,
    required this.icon,
    required this.themeColor,
    required this.glowColor,
  });

  @override
  State<_ZannyFeedbackDialogBody> createState() => _ZannyFeedbackDialogBodyState();
}

class _ZannyFeedbackDialogBodyState extends State<_ZannyFeedbackDialogBody> with SingleTickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _iconScale = CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    );
    _iconController.forward();

    // Auto dismiss after 2.8 seconds
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dialogBg = isDark 
        ? const Color(0xFF141414).withValues(alpha: 0.95) 
        : Colors.white.withValues(alpha: 0.98);

    final dialogBorderColor = isDark 
        ? const Color(0xFF2A2A2A) 
        : Colors.grey.shade300;

    final textColor = isDark 
        ? Colors.white 
        : Colors.black87;

    final activeThemeColor = isDark ? Colors.white : Colors.black;
    final activeGlowColor = isDark ? Colors.white24 : Colors.black12;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 290,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: dialogBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: dialogBorderColor, 
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: activeGlowColor.withValues(alpha: 0.12),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated top icon
              ScaleTransition(
                scale: _iconScale,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: activeThemeColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: activeThemeColor.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    color: activeThemeColor,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Message
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 24),
              // OK button
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: activeThemeColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: activeThemeColor.withValues(alpha: 0.15), width: 1),
                  ),
                  child: Center(
                    child: Text(
                      'OK',
                      style: GoogleFonts.inter(
                        color: activeThemeColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
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
