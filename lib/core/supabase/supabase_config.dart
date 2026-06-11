import 'package:supabase_flutter/supabase_flutter.dart';

/// Central access point for the Supabase client
class SupabaseConfig {
  SupabaseConfig._();

  // ── Replace these with your real Supabase project values ──
  // Go to: https://supabase.com → Project Settings → API
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT_ID.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );

  static bool get isConfigured =>
      supabaseUrl != 'https://YOUR_PROJECT_ID.supabase.co' &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY' &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;

  /// Initialize Supabase — call once in main()
  static Future<void> initialize() async {
    if (!isConfigured) {
      print('⚠️ Supabase URL or Anon Key is using placeholders. Running in mock/offline mode.');
      return;
    }
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
    } catch (e) {
      print('⚠️ Failed to initialize Supabase: $e. Running in mock/offline mode.');
    }
  }

  /// Quick access to the Supabase client
  static SupabaseClient get client => Supabase.instance.client;

  /// Quick access to the current user
  static User? get currentUser => client.auth.currentUser;

  /// Whether a user is signed in
  static bool get isSignedIn => currentUser != null;
}
