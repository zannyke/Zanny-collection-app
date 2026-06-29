import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/models.dart';
import '../repositories/admin_repository.dart';
import '../../../shared/providers/product_provider.dart';
import '../../../shared/widgets/shimmer_placeholder.dart';

class AdminAddProductScreen extends ConsumerStatefulWidget {
  final Product? product;
  const AdminAddProductScreen({super.key, this.product});

  @override
  ConsumerState<AdminAddProductScreen> createState() => _AdminAddProductScreenState();
}

class _AdminAddProductScreenState extends ConsumerState<AdminAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Text controllers
  final _nameController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _stockController = TextEditingController(text: '10');
  
  // Selected colors
  final Map<String, bool> _colorsMap = {
    'Black': false,
    'White': false,
    'Charcoal': false,
    'Heather Grey': false,
    'Stone Grey': false,
    'Off-White': false,
    'Cream': false,
    'Sand': false,
    'Beige': false,
    'Mocha': false,
    'Brown': false,
    'Olive': false,
    'Sage': false,
    'Navy': false,
    'Muted Red': false,
  };
  final List<String> _customColors = [];
  final _customColorController = TextEditingController();
  final _pushBodyController = TextEditingController();

  String? _selectedCategory;
  bool _isNew = false;
  bool _isSale = false;
  bool _isPreorder = false;
  bool _isLoading = false;
  bool _sendPushNotification = false;

  final List<String> _existingImageUrls = [];
  final List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  // Selected sizes
  final Map<String, bool> _sizesMap = {
    'XS': false,
    'S': false,
    'M': false,
    'L': false,
    'XL': false,
    'XXL': false,
    'One Size': false,
    '40': false,
    '41': false,
    '42': false,
    '43': false,
    '44': false,
    '45': false,
  };

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.name;
      _subtitleController.text = p.subtitle;
      _descriptionController.text = p.description;
      _priceController.text = p.price.toStringAsFixed(0);
      _originalPriceController.text = p.originalPrice?.toStringAsFixed(0) ?? '';
      _stockController.text = p.stock.toString();
      _selectedCategory = p.category;
      _isNew = p.isNew;
      _isSale = p.isSale;
      _isPreorder = p.isPreorder;
      
      for (final color in p.colors) {
        if (_colorsMap.containsKey(color)) {
          _colorsMap[color] = true;
        } else {
          _customColors.add(color);
        }
      }
      
      for (final size in p.sizes) {
        if (_sizesMap.containsKey(size)) {
          _sizesMap[size] = true;
        }
      }
      
      _existingImageUrls.addAll(p.images);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    _customColorController.dispose();
    _pushBodyController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final theme = Theme.of(context);
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1000,
        maxHeight: 1000,
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
    // Capture context-dependent objects before any await gaps
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    if (!_formKey.currentState!.validate()) return;
    
    final totalImageCount = _existingImageUrls.length + _selectedImages.length;
    if (totalImageCount == 0) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Please select or keep at least one product image'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Please choose a category'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    final selectedSizesList = _sizesMap.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedSizesList.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Please select at least one size'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    final selectedColorsList = _colorsMap.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    selectedColorsList.addAll(_customColors);

    if (selectedColorsList.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Please select or add at least one color'),
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
      final imageUrls = List<String>.from(_existingImageUrls);
      for (final file in _selectedImages) {
        final url = await repo.uploadProductImage(file);
        imageUrls.add(url);
      }
      
      final product = Product(
        id: widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        subtitle: _subtitleController.text.trim().isEmpty ? _selectedCategory! : _subtitleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        originalPrice: _originalPriceController.text.trim().isNotEmpty
            ? double.parse(_originalPriceController.text.trim())
            : null,
        images: imageUrls,
        colors: selectedColorsList,
        sizes: selectedSizesList,
        category: _selectedCategory!,
        stock: int.parse(_stockController.text.trim()),
        isNew: _isNew,
        isSale: _isSale,
        isPreorder: _isPreorder,
      );

      if (widget.product != null) {
        await ref.read(productsStateProvider.notifier).updateProduct(
          product,
          sendPush: _sendPushNotification,
          pushBody: _pushBodyController.text.trim().isNotEmpty ? _pushBodyController.text.trim() : null,
        );
      } else {
        await ref.read(productsStateProvider.notifier).addProduct(
          product,
          sendPush: _sendPushNotification,
          pushBody: _pushBodyController.text.trim().isNotEmpty ? _pushBodyController.text.trim() : null,
        );
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(widget.product != null ? 'Product updated successfully' : 'Product added successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      // Refresh productsStateProvider — admin dashboard and shop both watch this
      await ref.read(productsStateProvider.notifier).refresh();
      // Also invalidate family providers so category/new-arrivals screens reload
      ref.invalidate(categoryProductsProvider);
      ref.invalidate(newArrivalsProvider);
      ref.invalidate(relatedProductsProvider);
      if (mounted) router.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to save product: $e'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
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
          widget.product != null ? 'EDIT PRODUCT' : 'ADD NEW STOCK',
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
                  // Image Picker Box
                  (_existingImageUrls.isNotEmpty || _selectedImages.isNotEmpty)
                      ? SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _existingImageUrls.length + _selectedImages.length + 1,
                            itemBuilder: (context, index) {
                              final totalImagesCount = _existingImageUrls.length + _selectedImages.length;
                              if (index == totalImagesCount) {
                                return GestureDetector(
                                  onTap: _pickImages,
                                  child: Container(
                                    width: 100,
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

                              if (index < _existingImageUrls.length) {
                                // Existing network image
                                final url = _existingImageUrls[index];
                                return Stack(
                                  children: [
                                    Container(
                                      width: 100,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        image: DecorationImage(
                                          image: NetworkImage(url),
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
                                            _existingImageUrls.removeAt(index);
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
                              } else {
                                // Newly selected file image
                                final localIndex = index - _existingImageUrls.length;
                                final file = _selectedImages[localIndex];
                                return Stack(
                                  children: [
                                    Container(
                                      width: 100,
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
                                            _selectedImages.removeAt(localIndex);
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
                              }
                            },
                          ),
                        )
                      : GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.colorScheme.outline),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, color: theme.colorScheme.secondary.withValues(alpha: 0.6), size: 44),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to upload product photos',
                                  style: GoogleFonts.inter(
                                    color: theme.colorScheme.secondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  const SizedBox(height: 24),

                  // Basic details
                  _buildSectionTitle('PRODUCT NAME'),
                  _buildTextField(
                    controller: _nameController,
                    hintText: 'e.g. Premium Linen Shirt',
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Product name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildSectionTitle('SUBTITLE / MATERIAL'),
                  _buildTextField(
                    controller: _subtitleController,
                    hintText: 'e.g. 100% Organic Linen',
                  ),
                  const SizedBox(height: 16),

                  _buildSectionTitle('DESCRIPTION'),
                  _buildTextField(
                    controller: _descriptionController,
                    hintText: 'Provide detailed information about size, fit, and fabric care...',
                    maxLines: 4,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Description is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Pricing & Stock row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('PRICE (KES)'),
                            _buildTextField(
                              controller: _priceController,
                              hintText: 'e.g. 3500',
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Required';
                                if (double.tryParse(val.trim()) == null) return 'Must be a number';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('ORIGINAL PRICE (OPTIONAL)'),
                            _buildTextField(
                              controller: _originalPriceController,
                              hintText: 'e.g. 4500',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildSectionTitle('STOCK QUANTITY'),
                  _buildTextField(
                    controller: _stockController,
                    hintText: 'e.g. 15',
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Required';
                      if (int.tryParse(val.trim()) == null) return 'Must be an integer';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Category Dropdown
                  _buildSectionTitle('CATEGORY'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        hint: Text('Select category', style: TextStyle(color: theme.colorScheme.secondary.withValues(alpha: 0.5))),
                        dropdownColor: theme.colorScheme.surface,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.secondary),
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: const InputDecoration(border: InputBorder.none),
                        items: ProductCategory.all.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat.slug,
                            child: Text(cat.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Colors Selection
                  _buildSectionTitle('AVAILABLE COLORS'),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Wrap of color chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._colorsMap.keys.map((color) {
                              final isSelected = _colorsMap[color]!;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _colorsMap[color] = !isSelected;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    color,
                                    style: TextStyle(
                                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            }),
                            
                            // Custom colors chips
                            ..._customColors.map((color) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  border: Border.all(color: theme.colorScheme.primary),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      color,
                                      style: TextStyle(
                                        color: theme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _customColors.remove(color);
                                        });
                                      },
                                      child: Icon(
                                        Icons.cancel_rounded,
                                        size: 14,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Add Custom Color Input
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: TextField(
                                  controller: _customColorController,
                                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Add custom color (e.g. Lavender)',
                                    hintStyle: TextStyle(color: theme.colorScheme.secondary.withValues(alpha: 0.5), fontSize: 12),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    fillColor: theme.scaffoldBackgroundColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: theme.colorScheme.outline),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: theme.colorScheme.outline),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: theme.colorScheme.primary),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () {
                                  final text = _customColorController.text.trim();
                                  if (text.isNotEmpty) {
                                    if (!_colorsMap.containsKey(text) && !_customColors.contains(text)) {
                                      setState(() {
                                        _customColors.add(text);
                                        _customColorController.clear();
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Color already exists'),
                                          backgroundColor: theme.colorScheme.error,
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  minimumSize: const Size(50, 40),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Icon(Icons.add_rounded, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sizes Checkboxes
                  _buildSectionTitle('AVAILABLE SIZES'),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _sizesMap.length,
                      itemBuilder: (context, index) {
                        final size = _sizesMap.keys.elementAt(index);
                        final isSelected = _sizesMap[size]!;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _sizesMap[size] = !isSelected;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              size,
                              style: TextStyle(
                                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Status Badges Selection
                  _buildSectionTitle('PRODUCT STATUS OPTIONS'),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: Text('Mark as NEW', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13)),
                          value: _isNew,
                          activeColor: theme.colorScheme.primary,
                          checkColor: theme.colorScheme.onPrimary,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) {
                            setState(() {
                              _isNew = val ?? false;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: Text('Mark as SALE', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13)),
                          value: _isSale,
                          activeColor: theme.colorScheme.primary,
                          checkColor: theme.colorScheme.onPrimary,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) {
                            setState(() {
                              _isSale = val ?? false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    title: Text('Mark as PRE-ORDER (Bypasses stock checks)', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13)),
                    value: _isPreorder,
                    activeColor: theme.colorScheme.primary,
                    checkColor: theme.colorScheme.onPrimary,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setState(() {
                        _isPreorder = val ?? false;
                      });
                    },
                  ),
                  if (widget.product == null) ...[
                    const SizedBox(height: 20),
                    _buildSectionTitle('ADVERTISE PRODUCT'),
                    CheckboxListTile(
                      title: Text(
                        'Advertise this product by sending a push notification',
                        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                      ),
                      subtitle: Text(
                        'Sends a system-level alert to all registered users',
                        style: TextStyle(color: theme.colorScheme.secondary, fontSize: 11),
                      ),
                      value: _sendPushNotification,
                      activeColor: theme.colorScheme.primary,
                      checkColor: theme.colorScheme.onPrimary,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() {
                          _sendPushNotification = val ?? false;
                        });
                      },
                    ),
                    if (_sendPushNotification) ...[
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _pushBodyController,
                        hintText: 'Custom push body (Optional, defaults to new arrival template)',
                        maxLines: 2,
                      ),
                    ],
                  ],
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
                        'SAVE PRODUCT',
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
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.45),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border, width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const ShimmerPlaceholder(width: 24, height: 24, borderRadius: 12),
                            const SizedBox(width: 16),
                            Text(
                              widget.product == null ? 'Adding product...' : 'Updating product...',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
