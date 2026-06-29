import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/custom_feedback.dart';

class NoInternetScreen extends ConsumerStatefulWidget {
  const NoInternetScreen({super.key});

  @override
  ConsumerState<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends ConsumerState<NoInternetScreen> {
  bool _checking = false;
  bool _success = false;

  Future<void> _runDiagnostics() async {
    if (_checking || _success) return;

    setState(() {
      _checking = true;
    });

    // Check actual internet connectivity
    final hasInternet = await ConnectivityService.hasInternetConnection();

    if (!mounted) return;

    if (hasInternet) {
      setState(() {
        _checking = false;
        _success = true;
      });
      // The AnimatedWifiIcon will play its green success animation
      // and call the completion callback, which transitions to the main app.
    } else {
      setState(() {
        _checking = false;
      });
      if (mounted) {
        ZannyFeedback.showError(
          context,
          'Connection required. Please check your internet settings and try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Custom animated WiFi icon
              AnimatedWifiIcon(
                isChecking: _checking,
                isSuccess: _success,
                onSuccessAnimationComplete: () {
                  ref.read(connectivityProvider.notifier).forceUpdateState(true);
                },
              ),
              const SizedBox(height: 48),

              Text(
                'CONNECTION REQUIRED',
                style: GoogleFonts.inter(
                  color: theme.colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Zanny Collection requires an active internet connection to sync products and process transactions. Please check your network connection.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: theme.colorScheme.secondary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 48),

              // Retry Button
              PremiumButton(
                onPressed: (_checking || _success) ? null : _runDiagnostics,
                text: _checking ? 'CHECKING...' : 'RETRY CONNECTION',
                isLoading: _checking,
                type: PremiumButtonType.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedWifiIcon extends StatefulWidget {
  final bool isChecking;
  final bool isSuccess;
  final VoidCallback? onSuccessAnimationComplete;

  const AnimatedWifiIcon({
    super.key,
    required this.isChecking,
    required this.isSuccess,
    this.onSuccessAnimationComplete,
  });

  @override
  State<AnimatedWifiIcon> createState() => _AnimatedWifiIconState();
}

class _AnimatedWifiIconState extends State<AnimatedWifiIcon> with TickerProviderStateMixin {
  late AnimationController _loopController;
  late AnimationController _successController;

  @override
  void initState() {
    super.initState();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _successController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onSuccessAnimationComplete?.call();
      }
    });

    _startLoop();
  }

  void _startLoop() {
    _loopController.duration = widget.isChecking
        ? const Duration(milliseconds: 1100)
        : const Duration(milliseconds: 2200);
    _loopController.repeat();
  }

  @override
  void didUpdateWidget(covariant AnimatedWifiIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSuccess && !oldWidget.isSuccess) {
      _loopController.stop();
      _successController.forward(from: 0.0);
    } else if (!widget.isSuccess) {
      if (widget.isChecking != oldWidget.isChecking) {
        _startLoop();
      }
    }
  }

  @override
  void dispose() {
    _loopController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const errorColor = AppColors.error;
    const successColor = AppColors.success;
    const checkingColor = Colors.blueAccent;
    final baseColor = theme.brightness == Brightness.light ? Colors.black12 : Colors.white12;
    final activeColor = theme.brightness == Brightness.light ? Colors.black87 : Colors.white;

    return AnimatedBuilder(
      animation: Listenable.merge([_loopController, _successController]),
      builder: (context, child) {
        double progress = 0.0;
        bool isError = false;
        double errorProgress = 0.0;
        Color containerBorderColor = baseColor;
        Color containerGlowColor = Colors.transparent;

        if (widget.isSuccess) {
          progress = _successController.value;
          containerBorderColor = Color.lerp(baseColor, successColor, _successController.value)!;
          containerGlowColor = successColor.withValues(alpha: 0.25 * _successController.value);
        } else {
          final loopVal = _loopController.value;
          if (widget.isChecking) {
            progress = loopVal;
            isError = false;
            containerBorderColor = Color.lerp(baseColor, checkingColor, (0.5 - (loopVal - 0.5).abs()) * 2)!;
            containerGlowColor = checkingColor.withValues(alpha: 0.15 * (0.5 - (loopVal - 0.5).abs()) * 2);
          } else {
            if (loopVal < 0.6) {
              progress = loopVal / 0.6;
              isError = false;
              containerBorderColor = baseColor;
              containerGlowColor = Colors.transparent;
            } else if (loopVal < 0.8) {
              progress = 1.0;
              isError = true;
              double t = (loopVal - 0.6) / 0.2;
              errorProgress = t;
              containerBorderColor = Color.lerp(baseColor, errorColor, t)!;
              containerGlowColor = errorColor.withValues(alpha: 0.25 * t);
            } else {
              progress = 1.0;
              isError = true;
              errorProgress = 1.0;
              double t = (loopVal - 0.8) / 0.2;
              containerBorderColor = Color.lerp(errorColor, baseColor, t)!;
              containerGlowColor = errorColor.withValues(alpha: 0.25 * (1.0 - t));
            }
          }
        }

        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surface,
            border: Border.all(
              color: containerBorderColor,
              width: 2.0,
            ),
            boxShadow: [
              if (containerGlowColor != Colors.transparent)
                BoxShadow(
                  color: containerGlowColor,
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
            ],
          ),
          child: Center(
            child: SizedBox(
              width: 60,
              height: 60,
              child: CustomPaint(
                painter: WifiPainter(
                  progress: progress,
                  isError: isError,
                  errorProgress: errorProgress,
                  isSuccess: widget.isSuccess,
                  baseColor: baseColor,
                  activeColor: widget.isChecking ? checkingColor : activeColor,
                  errorColor: errorColor,
                  successColor: successColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class WifiPainter extends CustomPainter {
  final double progress;
  final bool isError;
  final double errorProgress;
  final bool isSuccess;
  final Color baseColor;
  final Color activeColor;
  final Color errorColor;
  final Color successColor;

  WifiPainter({
    required this.progress,
    required this.isError,
    required this.errorProgress,
    required this.isSuccess,
    required this.baseColor,
    required this.activeColor,
    required this.errorColor,
    required this.successColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double pi = 3.1415926535897932;
    final center = Offset(size.width / 2, size.height - 15);
    final double maxRadius = size.width / 2 - 5;
    const double dotRadius = 6.0;

    final double r1 = dotRadius + (maxRadius - dotRadius) * 0.33;
    final double r2 = dotRadius + (maxRadius - dotRadius) * 0.66;
    final double r3 = maxRadius;

    final Paint wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final Paint dotPaint = Paint()..style = PaintingStyle.fill;

    Color currentColor(int waveIndex) {
      if (isSuccess) {
        bool visible = progress >= (waveIndex / 3.0);
        return visible ? successColor : baseColor;
      }
      if (isError) {
        return errorColor;
      }
      bool visible = progress >= (waveIndex / 3.0);
      return visible ? activeColor : baseColor;
    }

    dotPaint.color = currentColor(0);
    canvas.drawCircle(center, dotRadius, dotPaint);

    void drawWifiArc(double radius, Color color) {
      wavePaint.color = color;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, -135 * pi / 180, 90 * pi / 180, false, wavePaint);
    }

    drawWifiArc(r1, currentColor(1));
    drawWifiArc(r2, currentColor(2));
    drawWifiArc(r3, currentColor(3));

    if (isError && errorProgress > 0.0) {
      final Paint slashPaint = Paint()
        ..color = errorColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round;

      const double padding = 10.0;
      const Offset start = Offset(padding, padding);
      final Offset end = Offset(size.width - padding, size.height - padding - 10);

      final Offset currentEnd = Offset(
        start.dx + (end.dx - start.dx) * errorProgress,
        start.dy + (end.dy - start.dy) * errorProgress,
      );

      canvas.drawLine(start, currentEnd, slashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WifiPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isError != isError ||
        oldDelegate.errorProgress != errorProgress ||
        oldDelegate.isSuccess != isSuccess;
  }
}
