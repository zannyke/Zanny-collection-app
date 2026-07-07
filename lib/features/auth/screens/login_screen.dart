import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dio/dio.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/animations.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../features/info/screens/no_internet_screen.dart';
import '../../../shared/widgets/custom_feedback.dart';
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

if (!ref.watch(connectivityProvider)) {
      return const NoInternetScreen();
    }
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
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
                  style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 6),
              Text('Sign in to your Zanny account',
                  style: GoogleFonts.inter(fontSize: 14, color: theme.colorScheme.secondary)),
              const SizedBox(height: 32),

              // ── Error banner ─────────────────────────────────────────────────
              if (authState.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                    color: theme.colorScheme.error.withValues(alpha: 0.08),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(authState.error!,
                          style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.error))),
                    ],
                  ),
                ),

              // ── Email ────────────────────────────────────────────────────────
              const _FieldLabel('EMAIL'),
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
              const _FieldLabel('PASSWORD'),
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
                      color: theme.colorScheme.secondary, size: 20,
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
                      style: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.secondary)),
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
                  Expanded(child: Divider(color: theme.colorScheme.outline)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.secondary)),
                  ),
                  Expanded(child: Divider(color: theme.colorScheme.outline)),
                ],
              ),
              const SizedBox(height: 20),

              // ── Google Sign In ───────────────────────────────────────────────
              PremiumButton(
                text: 'CONTINUE WITH GOOGLE',
                onPressed: () async {
                  ref.read(authProvider.notifier).clearError();
                  try {
                    await ref.read(authProvider.notifier).signInWithGoogle();
                  } catch (_) {}
                },
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
                      style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.secondary)),
                  GestureDetector(
                    onTap: () {
                      ref.read(authProvider.notifier).clearError();
                      context.pushReplacement('/register');
                    },
                    child: Text('Create Account',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary, decoration: TextDecoration.underline)),
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

  void _showEmailVerificationSheet(String email) {
    ref.read(authProvider.notifier).clearError();
    final codeCtrl = TextEditingController();
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final authState = ref.watch(authProvider);
          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify Your Email',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "We have sent a 6-digit verification code to $email. Please enter it below to activate your account.",
                  style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.secondary),
                ),
                const SizedBox(height: 20),
                if (authState.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                      color: theme.colorScheme.error.withValues(alpha: 0.08),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: theme.colorScheme.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.error!,
                            style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    hintText: '6-digit Code',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 20),
                PremiumButton(
                  text: 'VERIFY EMAIL',
                  isLoading: authState.isLoading,
                  onPressed: () async {
                    ref.read(authProvider.notifier).clearError();
                    if (codeCtrl.text.trim().length != 6) {
                      ZannyFeedback.showError(context, 'Please enter the 6-digit code');
                      return;
                    }
                    final routerContext = context;
                    try {
                      await ref.read(authProvider.notifier).verifyEmail(
                            email: email,
                            code: codeCtrl.text.trim(),
                          );
                      if (sheetCtx.mounted) {
                        Navigator.pop(sheetCtx);
                      }
                      if (routerContext.mounted) {
                        ZannyFeedback.showSuccess(routerContext, 'Account verified successfully! Welcome.');
                        routerContext.go('/profile');
                      }
                    } catch (_) {}
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(authProvider.notifier).signInWithEmail(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        _showEmailVerificationSheet(_emailCtrl.text.trim());
      }
    } catch (_) {}
  }

  void _showForgotPassword() {
    ref.read(authProvider.notifier).clearError();
    final emailCtrl = TextEditingController(text: _emailCtrl.text);
    final codeCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final theme = Theme.of(context);
    int step = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final authState = ref.watch(authProvider);
          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step == 1 ? 'Reset Password' : 'Verify Code',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  step == 1
                      ? "Enter your email and we'll send a 6-digit verification code."
                      : "Enter the verification code sent to ${emailCtrl.text} and your new password.",
                  style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.secondary),
                ),
                const SizedBox(height: 20),
                if (authState.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                      color: theme.colorScheme.error.withValues(alpha: 0.08),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: theme.colorScheme.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.error!,
                            style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (step == 1)
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'your@email.com'),
                  )
                else ...[
                  TextField(
                    controller: codeCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      hintText: '6-digit Code',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'New Password (min. 6 characters)'),
                  ),
                ],
                const SizedBox(height: 20),
                PremiumButton(
                  text: step == 1 ? 'SEND CODE' : 'RESET PASSWORD',
                  isLoading: authState.isLoading,
                  onPressed: () async {
                    ref.read(authProvider.notifier).clearError();
                    if (step == 1) {
                      if (emailCtrl.text.trim().isEmpty) {
                        ZannyFeedback.showError(context, 'Please enter your email address');
                        return;
                      }
                      try {
                        await ref.read(authProvider.notifier).resetPassword(emailCtrl.text.trim());
                        setSheetState(() {
                          step = 2;
                        });
                      } catch (_) {}
                    } else {
                      if (codeCtrl.text.trim().length != 6) {
                        ZannyFeedback.showError(context, 'Please enter the 6-digit code');
                        return;
                      }
                      if (newPasswordCtrl.text.isEmpty) {
                        ZannyFeedback.showError(context, 'Please enter a new password');
                        return;
                      }
                      final routerContext = context;
                      try {
                        await ref.read(authProvider.notifier).confirmResetPassword(
                              email: emailCtrl.text.trim(),
                              code: codeCtrl.text.trim(),
                              newPassword: newPasswordCtrl.text,
                            );
                        if (sheetCtx.mounted) {
                          Navigator.pop(sheetCtx);
                        }
                        if (routerContext.mounted) {
                          ZannyFeedback.showSuccess(routerContext, 'Password updated successfully! Log in now.');
                        }
                      } catch (_) {}
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(text,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: theme.colorScheme.secondary));
  }
}
