import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/animations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Navigate away on successful login
    ref.listen(authProvider, (previous, next) {
      if (next.isSignedIn) {
        context.pop();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: Text('SIGN IN', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 3)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Heading ──────────────────────────────────────────────────────
              Text('Welcome Back',
                  style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text('Sign in to your Zanny account',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 32),

              // ── Error banner ─────────────────────────────────────────────────
              if (authState.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.error.withOpacity(0.5)),
                    color: AppColors.error.withOpacity(0.08),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(authState.error!,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.error))),
                    ],
                  ),
                ),

              // ── Email ────────────────────────────────────────────────────────
              _FieldLabel('EMAIL'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'your@email.com'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Password ─────────────────────────────────────────────────────
              _FieldLabel('PASSWORD'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary, size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPassword,
                  child: Text('Forgot Password?',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(height: 20),

              // ── Sign In Button ───────────────────────────────────────────────
              PremiumButton(
                text: 'SIGN IN',
                onPressed: _submit,
                isLoading: authState.isLoading,
                type: PremiumButtonType.primary,
              ),
              const SizedBox(height: 20),

              // ── Divider ──────────────────────────────────────────────────────
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 20),

              // ── Google Sign In ───────────────────────────────────────────────
              PremiumButton(
                text: 'CONTINUE WITH GOOGLE',
                onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
                isLoading: authState.isLoading,
                type: PremiumButtonType.secondary,
                icon: Icons.g_mobiledata,
              ),
              const SizedBox(height: 36),

              // ── Register link ────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ",
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => context.pushReplacement('/register'),
                    child: Text('Create Account',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).signInWithEmail(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );
  }

  void _showForgotPassword() {
    final emailCtrl = TextEditingController(text: _emailCtrl.text);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reset Password', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text("Enter your email and we'll send a reset link.",
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'your@email.com'),
            ),
            const SizedBox(height: 20),
            PremiumButton(
              text: 'SEND RESET LINK',
              onPressed: () {
                ref.read(authProvider.notifier).resetPassword(emailCtrl.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reset link sent! Check your email.'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.textSecondary));
}
