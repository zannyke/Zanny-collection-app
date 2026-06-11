import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _sent = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'CONTACT US',
          style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _sent ? _SentConfirmation() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Get in Touch',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "We'd love to hear from you. Fill in the form below\nor reach us directly.",
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Contact methods strip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 0.5),
              color: AppColors.surface,
            ),
            child: Column(
              children: [
                _ContactRow(Icons.whatsapp, 'WhatsApp', '+254 700 000 000'),
                const Divider(color: AppColors.border, height: 20),
                _ContactRow(Icons.mail_outline, 'Email', 'hello@zannycollection.com'),
                const Divider(color: AppColors.border, height: 20),
                _ContactRow(Icons.camera_alt_outlined, 'Instagram', '@zannycollection'),
              ],
            ),
          ),
          const SizedBox(height: 28),

          _FieldLabel('YOUR NAME'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Full name'),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),

          _FieldLabel('EMAIL ADDRESS'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'your@email.com'),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),

          _FieldLabel('SUBJECT'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _subjectCtrl,
            decoration: const InputDecoration(hintText: 'e.g. Order issue, Size inquiry...'),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),

          _FieldLabel('MESSAGE'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _messageCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Tell us more about your enquiry...',
              alignLabelWithHint: true,
            ),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 28),

          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                  )
                : Text(
                    'SEND MESSAGE',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 2),
                  ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() { _loading = false; _sent = true; });
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ContactRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textPrimary),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: AppColors.textSecondary)),
          Text(value, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
        ]),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.textSecondary),
  );
}

class _SentConfirmation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.textPrimary)),
            child: const Icon(Icons.check, size: 32, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 24),
          Text('Message Sent!', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Text(
            "We'll get back to you within 24 hours.",
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 180,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              child: Text('BACK', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
            ),
          ),
        ],
      ),
    );
  }
}
