// This is a basic Flutter widget test for ZannyApp.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zanny_collection/main.dart';
import 'package:zanny_collection/core/services/connectivity_service.dart';
import 'package:zanny_collection/shared/models/models.dart';
import 'package:zanny_collection/shared/providers/product_provider.dart';
import 'package:zanny_collection/shared/providers/street_styles_provider.dart';

class FakeConnectivityNotifier extends ConnectivityNotifier {
  @override
  Future<void> checkConnection() async {
    state = true;
  }
}

class FakeProductsNotifier extends ProductsNotifier {
  @override
  List<Product> build() {
    return Product.defaultMockProducts;
  }
}

class FakeStreetStylesNotifier extends StreetStylesNotifier {
  @override
  List<StreetStyle> build() {
    return [];
  }
}

void main() {
  testWidgets('App smoke test - mounts successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityProvider.overrideWith((ref) => FakeConnectivityNotifier()),
          productsStateProvider.overrideWith(FakeProductsNotifier.new),
          streetStylesProvider.overrideWith(FakeStreetStylesNotifier.new),
        ],
        child: const ZannyApp(),
      ),
    );

    // Pump the animation and sequence timers to completion
    await tester.pump(const Duration(seconds: 5));

    // Verify that the app builds without crashing.
    expect(find.byType(ZannyApp), findsOneWidget);
  });
}
