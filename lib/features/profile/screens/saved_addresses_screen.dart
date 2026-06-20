import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/addresses_provider.dart';

class SavedAddressesScreen extends ConsumerWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.primary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'SAVED ADDRESSES',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: addresses.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final addr = addresses[index];
                return _AddressCard(address: addr);
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () => _showAddressForm(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'ADD NEW ADDRESS',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on_outlined, size: 64, color: theme.colorScheme.secondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No Saved Addresses',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a delivery address now for a faster checkout experience later.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: theme.colorScheme.secondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddressForm(BuildContext context, WidgetRef ref, {Address? editAddr}) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AddressFormSheet(address: editAddr),
    );
  }
}

class _AddressCard extends ConsumerWidget {
  final Address address;
  const _AddressCard({required this.address});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: address.isDefault ? theme.colorScheme.primary : theme.colorScheme.outline,
          width: address.isDefault ? 1.5 : 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  address.recipientName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'DEFAULT',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              address.streetAddress,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${address.city} ${address.postalCode.isNotEmpty ? address.postalCode : ""}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              address.phone,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: theme.colorScheme.outline, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!address.isDefault)
                  TextButton(
                    onPressed: () => ref.read(addressesProvider.notifier).setDefaultAddress(address.id),
                    child: Text(
                      'Set Default',
                      style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: theme.colorScheme.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (context) => _AddressFormSheet(address: address),
                    );
                  },
                  child: Text(
                    'Edit',
                    style: TextStyle(color: theme.colorScheme.secondary, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => _confirmDelete(context, ref, address.id),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Delete Address', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: theme.colorScheme.secondary)),
          ),
          TextButton(
            onPressed: () {
              ref.read(addressesProvider.notifier).deleteAddress(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _AddressFormSheet extends ConsumerStatefulWidget {
  final Address? address;
  const _AddressFormSheet({this.address});

  @override
  ConsumerState<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _streetController;
  late final TextEditingController _cityController;
  late final TextEditingController _zipController;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.address?.recipientName ?? '');
    _phoneController = TextEditingController(text: widget.address?.phone ?? '');
    _streetController = TextEditingController(text: widget.address?.streetAddress ?? '');
    _cityController = TextEditingController(text: widget.address?.city ?? '');
    _zipController = TextEditingController(text: widget.address?.postalCode ?? '');
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.address?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final newAddr = Address(
      id: id,
      recipientName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      streetAddress: _streetController.text.trim(),
      city: _cityController.text.trim(),
      postalCode: _zipController.text.trim(),
      isDefault: _isDefault,
    );

    if (widget.address != null) {
      await ref.read(addressesProvider.notifier).editAddress(newAddr);
    } else {
      await ref.read(addressesProvider.notifier).addAddress(newAddr);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.address != null ? 'EDIT ADDRESS' : 'ADD NEW ADDRESS',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              
              _buildFieldLabel('RECIPIENT FULL NAME'),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                decoration: _inputDecoration('e.g. John Doe'),
              ),
              const SizedBox(height: 16),

              _buildFieldLabel('PHONE NUMBER'),
              TextFormField(
                controller: _phoneController,
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                keyboardType: TextInputType.phone,
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                decoration: _inputDecoration('e.g. +254 712 345678'),
              ),
              const SizedBox(height: 16),

              _buildFieldLabel('STREET ADDRESS / BUILDING / HOUSE NO.'),
              TextFormField(
                controller: _streetController,
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                decoration: _inputDecoration('e.g. Room 12, Woodcreek Apts, Ngong Rd'),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('CITY / TOWN'),
                        TextFormField(
                          controller: _cityController,
                          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                          validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                          decoration: _inputDecoration('e.g. Nairobi'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('POSTAL CODE (OPTIONAL)'),
                        TextFormField(
                          controller: _zipController,
                          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                          decoration: _inputDecoration('e.g. 00100'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: theme.colorScheme.primary,
                checkColor: theme.colorScheme.onPrimary,
                title: Text(
                  'Set as default delivery address',
                  style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.onSurface),
                ),
                value: _isDefault,
                onChanged: (val) {
                  setState(() {
                    _isDefault = val ?? false;
                  });
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.address != null ? 'SAVE CHANGES' : 'SAVE ADDRESS',
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
    );
  }

  Widget _buildFieldLabel(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9,
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
