import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/street_styles_provider.dart';
import '../repositories/admin_repository.dart';

class AdminAddStyleScreen extends ConsumerStatefulWidget {
  const AdminAddStyleScreen({super.key});

  @override
  ConsumerState<AdminAddStyleScreen> createState() => _AdminAddStyleScreenState();
}

class _AdminAddStyleScreenState extends ConsumerState<AdminAddStyleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final theme = Theme.of(context);
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1000,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((img) => File(img.path)));
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting images: $e'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    final theme = Theme.of(context);
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one fashion lookbook image'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = ref.read(adminRepositoryProvider);
      final imageUrls = <String>[];
      for (final file in _selectedImages) {
        final url = await repo.uploadProductImage(file);
        imageUrls.add(url);
      }

      var username = _usernameController.text.trim();
      if (!username.startsWith('@')) {
        username = '@$username';
      }

      final style = StreetStyle(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        images: imageUrls,
        username: username,
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        createdAt: DateTime.now(),
      );

      await ref.read(streetStylesProvider.notifier).addStyle(style);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fashion lookbook added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload lookbook: $e'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.primary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'ADD STREET STYLE',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Image Picker Container
                  _selectedImages.isNotEmpty
                      ? SizedBox(
                          height: 150,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _selectedImages.length) {
                                return GestureDetector(
                                  onTap: _pickImages,
                                  child: Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: theme.colorScheme.outline),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_rounded, color: theme.colorScheme.primary, size: 28),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Add Photo',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final file = _selectedImages[index];
                              return Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: FileImage(file),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 16,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedImages.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        )
                      : GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.colorScheme.outline),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, color: theme.colorScheme.secondary.withValues(alpha: 0.6), size: 48),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to upload lookbook photos',
                                  style: GoogleFonts.inter(
                                    color: theme.colorScheme.secondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '(Select multiple photos)',
                                  style: TextStyle(
                                    color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  const SizedBox(height: 24),

                  _buildSectionTitle('USERNAME'),
                  _buildTextField(
                    controller: _usernameController,
                    hintText: 'e.g. zanny_hustler',
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Username is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildSectionTitle('LOCATION'),
                  _buildTextField(
                    controller: _locationController,
                    hintText: 'e.g. Nairobi, KE',
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Location is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildSectionTitle('STYLE DESCRIPTION'),
                  _buildTextField(
                    controller: _descriptionController,
                    hintText: 'Describe the outfits and aesthetic (e.g. heavy drapes and minimal fit)...',
                    maxLines: 4,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Description is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        disabledBackgroundColor: theme.colorScheme.outline,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'UPLOAD STYLE LOOKBOOK',
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
                color: Colors.black54,
                child: Center(
                  child: CircularProgressIndicator(color: theme.colorScheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: theme.colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
      cursorColor: theme.colorScheme.primary,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: theme.colorScheme.secondary.withValues(alpha: 0.5), fontSize: 13),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
