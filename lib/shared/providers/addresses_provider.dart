import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class AddressesNotifier extends Notifier<List<Address>> {
  static const _storageKey = 'cached_user_addresses';

  @override
  List<Address> build() {
    _loadAddresses();
    return [];
  }

  Future<void> _loadAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final List decoded = jsonDecode(jsonStr);
        state = decoded.map((item) => Address.fromJson(Map<String, dynamic>.from(item))).toList();
      }
    } catch (_) {}
  }

  Future<void> _saveAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = state.map((addr) => addr.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(encoded));
    } catch (_) {}
  }

  Future<void> addAddress(Address address) async {
    List<Address> list = List.from(state);
    if (address.isDefault) {
      list = list.map((a) => a.copyWith(isDefault: false)).toList();
    }
    // If it's the first address, make it default automatically
    final newAddress = address.copyWith(
      isDefault: list.isEmpty ? true : address.isDefault,
    );
    list.add(newAddress);
    state = list;
    await _saveAddresses();
  }

  Future<void> editAddress(Address address) async {
    List<Address> list = List.from(state);
    if (address.isDefault) {
      list = list.map((a) => a.id == address.id ? a : a.copyWith(isDefault: false)).toList();
    }
    final index = list.indexWhere((a) => a.id == address.id);
    if (index != -1) {
      list[index] = address;
      state = list;
      await _saveAddresses();
    }
  }

  Future<void> deleteAddress(String id) async {
    final deleted = state.firstWhere((a) => a.id == id);
    List<Address> list = state.where((a) => a.id != id).toList();
    // If we deleted the default address and list is not empty, make the first one default
    if (deleted.isDefault && list.isNotEmpty) {
      list[0] = list[0].copyWith(isDefault: true);
    }
    state = list;
    await _saveAddresses();
  }

  Future<void> setDefaultAddress(String id) async {
    state = state.map((a) => a.copyWith(isDefault: a.id == id)).toList();
    await _saveAddresses();
  }
}

final addressesProvider = NotifierProvider<AddressesNotifier, List<Address>>(AddressesNotifier.new);

final defaultAddressProvider = Provider<Address?>((ref) {
  final list = ref.watch(addressesProvider);
  if (list.isEmpty) return null;
  return list.firstWhere((a) => a.isDefault, orElse: () => list.first);
});
