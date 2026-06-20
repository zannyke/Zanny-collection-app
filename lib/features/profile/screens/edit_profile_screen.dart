import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  String? _avatarUrl;
  bool _isLoading = false;

  final List<String> _avatarPresets = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200', // Chic
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200', // Classic
    'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?q=80&w=200', // Streetwear
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=200', // Fashion
    'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?q=80&w=200', // Modern
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200', // Muted
    'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=200', // Minimalist
    'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?q=80&w=200', // Vibrant
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.userMetadata['full_name'] ?? '');
    _phoneController = TextEditingController(text: user?.userMetadata['phone'] ?? '');
    _avatarUrl = user?.userMetadata['avatar_url'] ?? _avatarPresets[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final theme = Theme.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final finalAvatar = _avatarUrl ?? _avatarPresets[0];

      await ref.read(authProvider.notifier).updateProfile(
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            avatarUrl: finalAvatar,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.primary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'EDIT PROFILE',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile image display (only editable by selecting presets below)
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.surface,
                        border: Border.all(color: theme.colorScheme.outline, width: 0.5),
                      ),
                      child: ClipOval(
                        child: (_avatarUrl != null && _avatarUrl!.startsWith('http'))
                            ? Image.network(_avatarUrl!, fit: BoxFit.cover)
                            : const Icon(Icons.person_outline, size: 48, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick presets title
                  Text(
                    'CHOOSE FROM PRESETS',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Preset list
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemCount: _avatarPresets.length,
                      itemBuilder: (context, index) {
                        final preset = _avatarPresets[index];
                        final isSelected = _avatarUrl == preset;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _avatarUrl = preset;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.network(preset, fit: BoxFit.cover),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Profile details inputs in white cards
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outline, width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('FULL NAME'),
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty) ? 'Name is required' : null,
                          decoration: _inputDecoration('e.g. John Doe'),
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('PHONE NUMBER'),
                        TextFormField(
                          controller: _phoneController,
                          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                          keyboardType: TextInputType.phone,
                          decoration: _inputDecoration('e.g. +254 712 345678'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        disabledBackgroundColor: theme.colorScheme.outline,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'SAVE CHANGES',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: Center(
                  child: CircularProgressIndicator(color: theme.colorScheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: theme.colorScheme.secondary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.colorScheme.secondary.withValues(alpha: 0.5), fontSize: 13),
      filled: true,
      fillColor: theme.scaffoldBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: theme.colorScheme.primary),
      ),
    );
  }
}
