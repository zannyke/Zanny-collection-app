import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// Bounces slightly when tapped to give a tactile feel
class TactileButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const TactileButton({super.key, required this.child, this.onTap});

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap != null) _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap != null) {
      _controller.reverse().then((_) {
        widget.onTap!();
      });
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

/// Fades in and slides up when built
class FadeInSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double offset;
  final Duration delay;

  const FadeInSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.offset = 24.0,
    this.delay = Duration.zero,
  });

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offset / 100),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

/// A premium loading indicator featuring a thin, luxury custom spinner
class ZannyLoadingIndicator extends StatefulWidget {
  final double size;
  final Color color;
  const ZannyLoadingIndicator({
    super.key,
    this.size = 24.0,
    this.color = AppColors.textPrimary,
  });

  @override
  State<ZannyLoadingIndicator> createState() => _ZannyLoadingIndicatorState();
}

class _ZannyLoadingIndicatorState extends State<ZannyLoadingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _PremiumSpinnerPainter(color: widget.color),
        ),
      ),
    );
  }
}

class _PremiumSpinnerPainter extends CustomPainter {
  final Color color;
  _PremiumSpinnerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final Paint activePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    canvas.drawCircle(center, radius - 1, paint);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1),
      -1.5,
      1.8,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum PremiumButtonType { primary, secondary, text }

/// A premium luxury button that scales down when pressed and shows our custom spinner when loading
class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final PremiumButtonType type;
  final IconData? icon;
  final Widget? leading;
  final double? width;
  final double height;

  const PremiumButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.type = PremiumButtonType.primary,
    this.icon,
    this.leading,
    this.width,
    this.height = 54.0,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    final theme = Theme.of(context);

    Color bg;
    Color fg;
    BorderSide border;

    switch (type) {
      case PremiumButtonType.primary:
        bg = isEnabled ? theme.colorScheme.primary : theme.colorScheme.outline;
        fg = isEnabled ? theme.colorScheme.onPrimary : theme.colorScheme.secondary;
        border = BorderSide.none;
        break;
      case PremiumButtonType.secondary:
        bg = Colors.transparent;
        fg = isEnabled ? theme.colorScheme.primary : theme.colorScheme.secondary;
        border = BorderSide(color: isEnabled ? theme.colorScheme.primary : theme.colorScheme.outline, width: 1.0);
        break;
      case PremiumButtonType.text:
        bg = Colors.transparent;
        fg = isEnabled ? theme.colorScheme.primary : theme.colorScheme.secondary;
        border = BorderSide.none;
        break;
    }

    Widget content;
    if (isLoading) {
      content = Center(
        child: ZannyLoadingIndicator(
          size: 20,
          color: type == PremiumButtonType.primary ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
        ),
      );
    } else {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 8),
          ] else if (icon != null) ...[
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
          ],
          Text(
            text.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: fg,
            ),
          ),
        ],
      );
    }

    return TactileButton(
      onTap: isEnabled ? onPressed : null,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: bg,
          border: border == BorderSide.none ? null : Border.fromBorderSide(border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: content,
      ),
    );
  }
}
