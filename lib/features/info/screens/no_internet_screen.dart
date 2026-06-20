import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/animations.dart';

class NoInternetScreen extends ConsumerStatefulWidget {
  const NoInternetScreen({super.key});

  @override
  ConsumerState<NoInternetScreen> createState() => _NoInternetScreenState();
}

enum DiagnosticStatus { pending, checking, success, failed }

class DiagnosticStep {
  final String label;
  DiagnosticStatus status;

  DiagnosticStep({
    required this.label,
    this.status = DiagnosticStatus.pending,
  });
}

class _NoInternetScreenState extends ConsumerState<NoInternetScreen> {
  bool _checking = false;
  late List<DiagnosticStep> _steps;

  @override
  void initState() {
    super.initState();
    _initSteps();
  }

  void _initSteps() {
    _steps = [
      DiagnosticStep(label: 'Checking cellular & Wi-Fi interfaces'),
      DiagnosticStep(label: 'Resolving domain name mapping'),
      DiagnosticStep(label: 'Verifying Zanny server connectivity'),
    ];
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _checking = true;
      _steps[0].status = DiagnosticStatus.checking;
      _steps[1].status = DiagnosticStatus.pending;
      _steps[2].status = DiagnosticStatus.pending;
    });

    // Step 1: Check general network interfaces
    await Future.delayed(const Duration(milliseconds: 600));
    bool step1Passed = false;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      step1Passed = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      step1Passed = false;
    }

    if (!mounted) return;
    setState(() {
      _steps[0].status = step1Passed ? DiagnosticStatus.success : DiagnosticStatus.failed;
    });

    if (!step1Passed) {
      setState(() {
        _checking = false;
      });
      return;
    }

    // Step 2: Check DNS Resolution
    setState(() {
      _steps[1].status = DiagnosticStatus.checking;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    bool step2Passed = false;
    try {
      final result = await InternetAddress.lookup('zanny-collection-api.zannykenya254.workers.dev')
          .timeout(const Duration(seconds: 3));
      step2Passed = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      step2Passed = false;
    }

    if (!mounted) return;
    setState(() {
      _steps[1].status = step2Passed ? DiagnosticStatus.success : DiagnosticStatus.failed;
    });

    if (!step2Passed) {
      setState(() {
        _checking = false;
      });
      return;
    }

    // Step 3: API handshake
    setState(() {
      _steps[2].status = DiagnosticStatus.checking;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Trigger connectivity notifier check
    await ref.read(connectivityProvider.notifier).checkConnection();
    final finalInternet = ref.read(connectivityProvider);

    if (!mounted) return;
    setState(() {
      _steps[2].status = finalInternet ? DiagnosticStatus.success : DiagnosticStatus.failed;
      _checking = false;
    });
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
              // Pulsing Offline Icon
              const PulsingOfflineIcon(),
              const SizedBox(height: 40),
              
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
              const SizedBox(height: 32),

              // Diagnostics Panel
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(color: theme.colorScheme.outline, width: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DIAGNOSTICS CHECKLIST',
                      style: GoogleFonts.inter(
                        color: theme.colorScheme.secondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._steps.map((step) => _buildDiagnosticRow(context, step)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Retry Button
              PremiumButton(
                onPressed: _checking ? null : _runDiagnostics,
                text: 'RETRY CONNECTION',
                isLoading: _checking,
                type: PremiumButtonType.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosticRow(BuildContext context, DiagnosticStep step) {
    final theme = Theme.of(context);
    Widget statusWidget;
    Color textColor = theme.colorScheme.secondary;
    
    switch (step.status) {
      case DiagnosticStatus.pending:
        statusWidget = Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.outline, width: 1.0),
          ),
        );
        textColor = theme.colorScheme.secondary.withValues(alpha: 0.6);
        break;
      case DiagnosticStatus.checking:
        statusWidget = SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        );
        textColor = theme.colorScheme.onSurface;
        break;
      case DiagnosticStatus.success:
        statusWidget = Icon(
          Icons.check_circle_rounded,
          color: theme.colorScheme.primary,
          size: 16,
        );
        textColor = theme.colorScheme.onSurface;
        break;
      case DiagnosticStatus.failed:
        statusWidget = const Icon(
          Icons.cancel_rounded,
          color: AppColors.error,
          size: 16,
        );
        textColor = AppColors.error;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          statusWidget,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step.label,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PulsingOfflineIcon extends StatefulWidget {
  const PulsingOfflineIcon({super.key});

  @override
  State<PulsingOfflineIcon> createState() => _PulsingOfflineIconState();
}

class _PulsingOfflineIconState extends State<PulsingOfflineIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 8.0, end: 24.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
                blurRadius: _glowAnimation.value,
                spreadRadius: _glowAnimation.value / 4,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.wifi_off_rounded,
              color: theme.colorScheme.primary,
              size: 40,
            ),
          ),
        );
      },
    );
  }
}
