import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animation Controllers ──────────────────────────────────────────────────
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _glowController;

  // ── Animations ─────────────────────────────────────────────────────────────
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();

    // Logo: fade in + scale up
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoOpacity = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    );
    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // Glow pulse
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowOpacity = Tween<double>(begin: 0.0, end: 0.25).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Text: fade in + slide up
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textOpacity = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic));

    // Sequence: logo → text → navigate
    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    await _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    await _textController.forward();

    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) context.go('/');
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Logo with glow ───────────────────────────────────────────────
            ScaleTransition(
              scale: _logoScale,
              child: FadeTransition(
                opacity: _logoOpacity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow halo behind logo
                    AnimatedBuilder(
                      animation: _glowOpacity,
                      builder: (_, __) => Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(_glowOpacity.value),
                              blurRadius: 60,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // The actual logo
                    Image.asset(
                      'assets/images/logo_with_bg.png',
                      width: 130,
                      height: 130,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Brand name ───────────────────────────────────────────────────
            SlideTransition(
              position: _textSlide,
              child: FadeTransition(
                opacity: _textOpacity,
                child: Column(
                  children: [
                    // ZANNY
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFE8E8E8), Color(0xFFFFFFFF), Color(0xFFD0D0D0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: const Text(
                        'ZANNY',
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // COLLECTION
                    Text(
                      'C O L L E C T I O N',
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 5,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom tagline
      bottomNavigationBar: FadeTransition(
        opacity: _textOpacity,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Text(
              'Premium Products for Those on the Way Up',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 11,
                fontStyle: FontStyle.italic,
                letterSpacing: 1,
                color: Colors.white.withOpacity(0.35),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
