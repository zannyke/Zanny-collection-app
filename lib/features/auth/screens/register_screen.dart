import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/animations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Create your account and start shopping',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),

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
                    fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.textSecondary),
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
                      color: AppColors.textSecondary,
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
                isLoading: _isLoading,
                type: PremiumButtonType.primary,
              ),
              const SizedBox(height: 16),

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
              const SizedBox(height: 16),

              PremiumButton(
                text: 'SIGN UP WITH GOOGLE',
                onPressed: () {},
                isLoading: _isLoading,
                type: PremiumButtonType.secondary,
                icon: Icons.g_mobiledata,
              ),
              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => context.pushReplacement('/login'),
                    child: Text(
                      'Sign In',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.textSecondary),
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

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoading = false);
      context.pop();
    }
  }
}
