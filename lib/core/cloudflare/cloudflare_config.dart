import 'package:flutter/services.dart';

/// Central configuration for the Cloudflare Worker API and R2 storage.
/// Reads from compile-time env vars or the bundled .env asset.
class CloudflareConfig {
  CloudflareConfig._();

  static String _workerUrl = '';
  static String _r2PublicUrl = '';

  static String get workerUrl => _workerUrl;
  static String get r2PublicUrl => _r2PublicUrl;

  static bool get isConfigured =>
      _workerUrl.isNotEmpty && !_workerUrl.contains('YOUR_WORKER_URL');

  /// Call once in main() before runApp().
  static Future<void> initialize() async {
    // 1. Compile-time env vars (injected by GitHub Actions)
    _workerUrl = const String.fromEnvironment('CF_WORKER_URL');
    _r2PublicUrl = const String.fromEnvironment('CF_R2_PUBLIC_URL');

    // 2. Fall back to .env asset
    if (!isConfigured) {
      try {
        final env = await rootBundle.loadString('.env');
        for (var line in env.split('\n')) {
          line = line.trim();
          if (line.isEmpty || line.startsWith('#')) continue;
          final idx = line.indexOf('=');
          if (idx < 0) continue;
          final key = line.substring(0, idx).trim();
          final value = line.substring(idx + 1).trim();
          if (key == 'CF_WORKER_URL') _workerUrl = value;
          if (key == 'CF_R2_PUBLIC_URL') _r2PublicUrl = value;
        }
      } catch (_) {}
    }

    if (!isConfigured) {
      _workerUrl = 'https://zanny-collection-api.zannykenya254.workers.dev';
    }
    if (_r2PublicUrl.isEmpty) {
      _r2PublicUrl = 'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev';
    }
  }
}
