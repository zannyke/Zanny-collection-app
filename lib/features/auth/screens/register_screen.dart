import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/custom_feedback.dart';
import '../../../core/services/notification_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Navigate away on successful signup
    ref.listen(authProvider, (previous, next) {
      if (next.isSignedIn && !(previous?.isSignedIn ?? false)) {
        NotificationService.showLocalNotification(
          101,
          'Welcome to Zanny Collection! ✨',
          'Explore premium streetwear and style tailored for you.',
        );
        context.pop();
      }
    });

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'CREATE ACCOUNT',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                'Join Zanny',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Create your account and start shopping',
                style: GoogleFonts.inter(fontSize: 14, color: theme.colorScheme.secondary),
              ),
              const SizedBox(height: 24),

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
                      Expanded(
                        child: Text(
                          authState.error!,
                          style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),

              // Name row
              Row(
                children: [
                  Expanded(child: _field('FIRST NAME', _firstNameCtrl, 'First name')),
                  const SizedBox(width: 12),
                  Expanded(child: _field('LAST NAME', _lastNameCtrl, 'Last name')),
                ],
              ),
              const SizedBox(height: 16),
              _field('EMAIL', _emailCtrl, 'your@email.com',
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),

              // Password
              Text(
                'PASSWORD',
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: theme.colorScheme.secondary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Min. 8 characters',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: theme.colorScheme.secondary,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 8) return 'Minimum 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _field('CONFIRM PASSWORD', _confirmPasswordCtrl, 'Repeat password',
                  obscure: true, validator: (v) {
                if (v != _passwordCtrl.text) return 'Passwords do not match';
                return null;
              }),
              const SizedBox(height: 28),

              PremiumButton(
                text: 'CREATE ACCOUNT',
                onPressed: _submit,
                isLoading: authState.isLoading,
                type: PremiumButtonType.primary,
              ),
              const SizedBox(height: 16),

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
              const SizedBox(height: 16),

              PremiumButton(
                text: 'SIGN UP WITH GOOGLE',
                onPressed: () => ZannyFeedback.showError(
                  context,
                  'Google sign-in coming soon. Please use email & password.',
                ),
                isLoading: false,
                type: PremiumButtonType.secondary,
                icon: Icons.g_mobiledata,
              ),
              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ',
                      style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.secondary)),
                  GestureDetector(
                    onTap: () => context.pushReplacement('/login'),
                    child: Text(
                      'Sign In',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w700, color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline),
                    ),
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

  Widget _field(
    String label,
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: theme.colorScheme.secondary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hint),
          validator: validator ??
              (v) {
                if (v == null || v.isEmpty) return 'Required';
                return null;
              },
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).signUpWithEmail(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          fullName: '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
        );
  }
}
