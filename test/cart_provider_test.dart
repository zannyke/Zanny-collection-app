import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zanny_collection/shared/models/models.dart';
import 'package:zanny_collection/shared/providers/cart_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mockProduct = Product(
    id: 'test_id',
    name: 'Test Heavyweight Hoodie',
    subtitle: 'New Drop',
    description: 'A mock product for unit testing',
    price: 3500.0,
    images: ['https://example.com/image.jpg'],
    colors: ['Black'],
    sizes: ['L'],
    category: 'hoodies',
  );

  group('CartNotifier Cache & State Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('Loads empty cart initially when cache is empty', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cart = container.read(cartProvider);
      expect(cart, isEmpty);
    });

    test('Loads persisted cart items from cache on startup', () async {
      const cachedItem = CartItem(
        product: mockProduct,
        selectedColor: 'Black',
        selectedSize: 'L',
        quantity: 2,
      );

      SharedPreferences.setMockInitialValues({
        'cart_items': json.encode([cachedItem.toJson()]),
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Read to trigger lazy initialization
      container.read(cartProvider);

      // Wait for the asynchronous _loadFromCache to complete
      await Future.delayed(const Duration(milliseconds: 50));

      final cart = container.read(cartProvider);
      expect(cart, isNotEmpty);
      expect(cart.first.product.id, 'test_id');
      expect(cart.first.quantity, 2);
    });

    test('addItem saves state to cache', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(mockProduct, 'Black', 'L', 3);

      // Verify state was updated
      var cart = container.read(cartProvider);
      expect(cart.length, 1);
      expect(cart.first.quantity, 3);

      // Verify saved to SharedPreferences cache
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('cart_items');
      expect(jsonString, isNotNull);

      final decoded = json.decode(jsonString!) as List;
      expect(decoded.length, 1);
      expect(decoded.first['quantity'], 3);
    });

    test('updateQuantity modifies state and saves to cache', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(mockProduct, 'Black', 'L', 2);

      final itemKey = '${mockProduct.id}_Black_L';
      notifier.updateQuantity(itemKey, 5);

      var cart = container.read(cartProvider);
      expect(cart.first.quantity, 5);

      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('cart_items');
      final decoded = json.decode(jsonString!) as List;
      expect(decoded.first['quantity'], 5);
    });

    test('removeItem updates state and saves to cache', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(mockProduct, 'Black', 'L', 1);

      final itemKey = '${mockProduct.id}_Black_L';
      notifier.removeItem(itemKey);

      var cart = container.read(cartProvider);
      expect(cart, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('cart_items');
      final decoded = json.decode(jsonString!) as List;
      expect(decoded, isEmpty);
    });

    test('clear resets state and empties cache', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(mockProduct, 'Black', 'L', 1);
      notifier.clear();

      var cart = container.read(cartProvider);
      expect(cart, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('cart_items');
      final decoded = json.decode(jsonString!) as List;
      expect(decoded, isEmpty);
    });
  });
}
