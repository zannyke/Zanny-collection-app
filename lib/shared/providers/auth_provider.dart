import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/cloudflare/api_client.dart';
import '../../core/services/notification_service.dart';
import '../models/app_user.dart';

// ── Auth State ────────────────────────────────────────────────────────────────

class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isSignedIn => user != null;
}

// ── Auth Notifier ─────────────────────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  static const _userCacheKey = 'cf_cached_user';

  @override
  AuthState build() {
    _loadFromCache();
    return const AuthState();
  }

  ApiClient get _api => ApiClient.instance;

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_userCacheKey);
      final token = await ApiClient.getToken();
      if (json != null && token != null) {
        final user = AppUser.fromJson(jsonDecode(json));
        state = AuthState(user: user);
        // Refresh profile from server in background
        _refreshProfile();
      }
    } catch (_) {}
  }

  Future<void> _refreshProfile() async {
    try {
      final resp = await _api.get('/api/auth/profile');
      if (resp.statusCode == 200) {
        final user = AppUser.fromJson(resp.data['user'] as Map<String, dynamic>);
        state = AuthState(user: user);
        await _cacheUser(user);
      }
    } catch (_) {}
  }

  Future<void> _cacheUser(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userCacheKey, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userCacheKey);
      await ApiClient.clearToken();
    } catch (_) {}
  }

  // ── Sign In ──────────────────────────────────────────────────────────────

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _api.post('/api/auth/signin', data: {
        'email': email.trim().toLowerCase(),
        'password': password,
      });
      final token = resp.data['token'] as String;
      final user = AppUser.fromJson(resp.data['user'] as Map<String, dynamic>);
      await ApiClient.saveToken(token);
      await _cacheUser(user);
      state = AuthState(user: user);
      // Save FCM token
      await NotificationService.saveTokenForCurrentUser();
    } on DioException catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Sign in failed. Please try again.');
    }
  }

  // ── Sign Up ──────────────────────────────────────────────────────────────

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _api.post('/api/auth/signup', data: {
        'email': email.trim().toLowerCase(),
        'password': password,
        'full_name': fullName,
      });
      final token = resp.data['token'] as String;
      final user = AppUser.fromJson(resp.data['user'] as Map<String, dynamic>);
      await ApiClient.saveToken(token);
      await _cacheUser(user);
      state = AuthState(user: user);
      await NotificationService.saveTokenForCurrentUser();
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Registration failed. Please try again.');
    }
  }

  // ── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _clearCache();
    state = const AuthState();
  }

  // ── Update Profile ───────────────────────────────────────────────────────

  Future<void> updateProfile({
    required String fullName,
    required String phone,
    required String avatarUrl,
  }) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    try {
      await _api.put('/api/auth/profile', data: {
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl,
      });
      final updated = currentUser.copyWith(
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      state = AuthState(user: updated);
      await _cacheUser(updated);
    } catch (_) {
      // Update locally even if server fails
      final updated = currentUser.copyWith(
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      state = AuthState(user: updated);
      await _cacheUser(updated);
    }
  }

  // ── Password Reset ───────────────────────────────────────────────────────

  Future<void> resetPassword(String email) async {
    // Placeholder — implement email reset flow with Cloudflare Email Workers
    // or a third-party email service (SendGrid, Resend, etc.)
  }

  String _extractError(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map && data.containsKey('error')) return data['error'] as String;
    } catch (_) {}
    if (e.response?.statusCode == 409) return 'Email already registered.';
    if (e.response?.statusCode == 401) return 'Invalid email or password.';
    return 'Network error. Please try again.';
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authProvider).user;
});

final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isSignedIn;
});
