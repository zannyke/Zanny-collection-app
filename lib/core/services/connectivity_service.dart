import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityService {
  /// Resolves the Cloudflare API host to check if the user is connected to the internet.
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('zanny-collection-api.zannykenya254.workers.dev')
          .timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      try {
        // Fallback check to Google DNS
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 4));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (__) {
        return false;
      }
    }
  }
}

class ConnectivityNotifier extends StateNotifier<bool> {
  Timer? _timer;

  ConnectivityNotifier() : super(true) {
    checkConnection();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => checkConnection());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> checkConnection() async {
    final hasInternet = await ConnectivityService.hasInternetConnection();
    if (mounted) {
      if (hasInternet) {
        state = true;
      } else {
        // Debounce: check twice before setting to false to prevent transient sleep-wake glitches
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          final doubleCheck = await ConnectivityService.hasInternetConnection();
          if (!doubleCheck && mounted) {
            state = false;
          }
        }
      }
    }
  }

  void forceUpdateState(bool hasInternet) {
    if (mounted) {
      state = hasInternet;
    }
  }
}

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});
