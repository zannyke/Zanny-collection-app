import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
        // Upload FCM token on app launch for signed-in users
        NotificationService.saveTokenForCurrentUser();
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

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: '962625906849-fboj1amh0k2d0pffb5m48d82kob347p7.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      final authDetails = await account.authentication;
      final idToken = authDetails.idToken;
      if (idToken == null) {
        throw Exception('Failed to retrieve Google ID Token.');
      }

      final resp = await _api.post('/api/auth/google', data: {
        'idToken': idToken,
      });

      final token = resp.data['token'] as String;
      final user = AppUser.fromJson(resp.data['user'] as Map<String, dynamic>);
      await ApiClient.saveToken(token);
      await _cacheUser(user);
      state = AuthState(user: user);
      await NotificationService.saveTokenForCurrentUser();
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Google sign in failed. Please try again.');
      rethrow;
    }
  }

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
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Sign in failed. Please try again.');
      rethrow;
    }
  }

  // ── Sign Up ──────────────────────────────────────────────────────────────

  Future<bool> signUpWithEmail({
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
      if (resp.data != null && resp.data['token'] == null) {
        state = state.copyWith(isLoading: false);
        return false; // Email verification required
      }
      final token = resp.data['token'] as String;
      final user = AppUser.fromJson(resp.data['user'] as Map<String, dynamic>);
      await ApiClient.saveToken(token);
      await _cacheUser(user);
      state = AuthState(user: user);
      await NotificationService.saveTokenForCurrentUser();
      return true; // Verified and signed in
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Registration failed. Please try again.');
      rethrow;
    }
  }

  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _api.post('/api/auth/verify-email', data: {
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
      });
      final token = resp.data['token'] as String;
      final user = AppUser.fromJson(resp.data['user'] as Map<String, dynamic>);
      await ApiClient.saveToken(token);
      await _cacheUser(user);
      state = AuthState(user: user);
      await NotificationService.saveTokenForCurrentUser();
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Email verification failed.');
      rethrow;
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

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post('/api/auth/forgot-password', data: {
        'email': email.trim().toLowerCase(),
      });
      state = state.copyWith(isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to request reset code.');
      rethrow;
    }
  }

  Future<void> confirmResetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post('/api/auth/reset-password', data: {
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
        'password': newPassword.trim(),
      });
      state = state.copyWith(isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to reset password.');
      rethrow;
    }
  }

  Future<void> deleteAccount(String currentPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.delete('/api/auth/profile', data: {
        'password': currentPassword,
      });
      await signOut();
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to delete account.');
      rethrow;
    }
  }

  String _extractError(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map && data.containsKey('error')) return data['error'] as String;
    } catch (_) {}
    if (e.response?.statusCode == 409) return 'Email already registered.';
    if (e.response?.statusCode == 401) return 'Invalid credentials.';
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
