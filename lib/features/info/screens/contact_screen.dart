import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/animations.dart';

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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Get in Touch',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28, fontWeight: FontWeight.w700, color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "We'd love to hear from you. Fill in the form below\nor reach us directly.",
            style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.secondary, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Contact methods strip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline, width: 0.5),
              color: theme.colorScheme.surface,
            ),
            child: Column(
              children: [
                const _ContactRow(Icons.chat_bubble_outline, 'WhatsApp', '+254 103 809594'),
                Divider(color: theme.colorScheme.outline, height: 20),
                const _ContactRow(Icons.mail_outline, 'Email', 'zannykenya254@gmail.com'),
                Divider(color: theme.colorScheme.outline, height: 20),
                const _ContactRow(Icons.camera_alt_outlined, 'Instagram', '@zannycollection_'),
              ],
            ),
          ),
          const SizedBox(height: 28),

          const _FieldLabel('YOUR NAME'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Full name'),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),

          const _FieldLabel('EMAIL ADDRESS'),
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

          const _FieldLabel('SUBJECT'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _subjectCtrl,
            decoration: const InputDecoration(hintText: 'e.g. Order issue, Size inquiry...'),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),

          const _FieldLabel('MESSAGE'),
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

          PremiumButton(
            onPressed: _loading ? null : _submit,
            isLoading: _loading,
            text: 'SEND MESSAGE',
            type: PremiumButtonType.primary,
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
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: theme.colorScheme.secondary)),
          Text(value, style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.primary, fontWeight: FontWeight.w500)),
        ]),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: theme.colorScheme.secondary),
    );
  }
}

class _SentConfirmation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 500,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: theme.colorScheme.primary)),
            child: Icon(Icons.check, size: 32, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text('Message Sent!', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
          const SizedBox(height: 10),
          Text(
            "We'll get back to you within 24 hours.",
            style: GoogleFonts.inter(fontSize: 14, color: theme.colorScheme.secondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          PremiumButton(
            onPressed: () => context.pop(),
            text: 'BACK',
            type: PremiumButtonType.secondary,
            width: 180,
          ),
        ],
      ),
    );
  }
}
