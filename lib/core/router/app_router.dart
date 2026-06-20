import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/collections/screens/collections_screen.dart';
import '../../features/collections/screens/category_screen.dart';
import '../../features/product/screens/product_detail_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/wishlist/screens/wishlist_screen.dart';
import '../../features/info/screens/world_of_zanny_screen.dart';
import '../../features/info/screens/faqs_screen.dart';
import '../../features/info/screens/shipping_screen.dart';
import '../../features/info/screens/contact_screen.dart';
import '../../features/info/screens/care_guide_screen.dart';
import '../../features/info/screens/fashion_screen.dart';
import '../../shared/widgets/bottom_nav_scaffold.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_add_product_screen.dart';
import '../../features/admin/screens/admin_add_style_screen.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/auth_provider.dart';
import '../../features/info/screens/legal_document_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/saved_addresses_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/orders/screens/order_success_screen.dart';

/// A global key that gives access to the Navigator outside the widget tree.
/// Used by [NotificationService] to navigate on notification tap.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: appNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [

      // ── Splash (initial screen) ───────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Shell: screens WITH bottom nav bar ──────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => BottomNavScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/collections',
            pageBuilder: (context, state) => const NoTransitionPage(child: CollectionsScreen()),
          ),
          GoRoute(
            path: '/fashion',
            pageBuilder: (context, state) => const NoTransitionPage(child: FashionScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),

      // ── Full-screen routes (no bottom nav) ──────────────────────────────────

      GoRoute(
        path: '/collections/:slug',
        builder: (context, state) => CategoryScreen(
          slug: state.pathParameters['slug']!,
        ),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) => ProductDetailScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/wishlist',
        builder: (context, state) => const WishlistScreen(),
      ),

      // ── Auth ─────────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Info pages ───────────────────────────────────────────────────────────
      GoRoute(
        path: '/world-of-zanny',
        builder: (context, state) => const WorldOfZannyScreen(),
      ),
      GoRoute(
        path: '/faqs',
        builder: (context, state) => const FaqsScreen(),
      ),
      GoRoute(
        path: '/shipping',
        builder: (context, state) => const ShippingScreen(),
      ),
      GoRoute(
        path: '/contact',
        builder: (context, state) => const ContactScreen(),
      ),
      GoRoute(
        path: '/care-guide',
        builder: (context, state) => const CareGuideScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
        redirect: (context, state) {
          final authState = ref.read(authProvider);
          if (!authState.isSignedIn || authState.user?.email != 'admin@zannycollection.com') {
            return '/';
          }
          return null;
        },
      ),
      GoRoute(
        path: '/admin/add-product',
        builder: (context, state) {
          final product = state.extra as Product?;
          return AdminAddProductScreen(product: product);
        },
        redirect: (context, state) {
          final authState = ref.read(authProvider);
          if (!authState.isSignedIn || authState.user?.email != 'admin@zannycollection.com') {
            return '/';
          }
          return null;
        },
      ),
      GoRoute(
        path: '/admin/add-style',
        builder: (context, state) => const AdminAddStyleScreen(),
        redirect: (context, state) {
          final authState = ref.read(authProvider);
          if (!authState.isSignedIn || authState.user?.email != 'admin@zannycollection.com') {
            return '/';
          }
          return null;
        },
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const LegalDocumentScreen(
          title: 'TERMS OF SERVICE',
          type: LegalDocumentType.termsOfService,
        ),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const LegalDocumentScreen(
          title: 'PRIVACY POLICY',
          type: LegalDocumentType.privacyPolicy,
        ),
      ),
      GoRoute(
        path: '/cookie',
        builder: (context, state) => const LegalDocumentScreen(
          title: 'COOKIE POLICY',
          type: LegalDocumentType.cookiePolicy,
        ),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/order-success',
        builder: (context, state) {
          final order = state.extra as Order;
          return OrderSuccessScreen(order: order);
        },
      ),
      GoRoute(
        path: '/saved-addresses',
        builder: (context, state) => const SavedAddressesScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            const Text('Page not found', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    ),
  );
});
