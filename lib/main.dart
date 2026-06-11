import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/supabase/supabase_config.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: const Color(0xFF0A0A0A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Initialize Firebase + FCM
  try {
    await Firebase.initializeApp();
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('⚠️ Firebase init failed (check google-services.json): $e');
  }

  runApp(
    const ProviderScope(
      child: ZannyApp(),
    ),
  );
}

class ZannyApp extends ConsumerWidget {
  const ZannyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Zanny Collection',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
