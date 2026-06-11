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
import '../../shared/widgets/bottom_nav_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
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
            path: '/search',
            pageBuilder: (context, state) => const NoTransitionPage(child: SearchScreen()),
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
