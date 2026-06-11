import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/services/notification_service.dart';

// ── Auth State ────────────────────────────────────────────────────────────────

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({User? user, bool? isLoading, String? error, bool clearUser = false}) {
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
  SupabaseClient get _client => SupabaseConfig.client;

  @override
  AuthState build() {
    if (!SupabaseConfig.isConfigured) {
      return const AuthState();
    }
    // Listen to auth state changes
    try {
      _client.auth.onAuthStateChange.listen((data) {
        state = AuthState(user: data.session?.user);
      });
      return AuthState(user: _client.auth.currentUser);
    } catch (e) {
      print('⚠️ Supabase error in AuthNotifier build: $e');
      return const AuthState();
    }
  }

  /// Sign in with email + password
  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    if (!SupabaseConfig.isConfigured) {
      await Future.delayed(const Duration(seconds: 1));
      final mockUser = User(
        id: 'mock_user_email',
        appMetadata: const {},
        userMetadata: const {
          'full_name': 'Zanny Member',
          'avatar_url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200',
        },
        aud: 'authenticated',
        email: email,
        createdAt: DateTime.now().toIso8601String(),
      );
      state = AuthState(user: mockUser);
      return;
    }
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = AuthState(user: response.user);
      // Save FCM token for this user
      await NotificationService.saveTokenForUser(response.user?.id);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Sign in failed. Please try again.');
    }
  }

  /// Register with email + password
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    if (!SupabaseConfig.isConfigured) {
      await Future.delayed(const Duration(seconds: 1));
      final mockUser = User(
        id: 'mock_user_registered',
        appMetadata: const {},
        userMetadata: {
          'full_name': fullName,
          'avatar_url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200',
        },
        aud: 'authenticated',
        email: email,
        createdAt: DateTime.now().toIso8601String(),
      );
      state = AuthState(user: mockUser);
      return;
    }
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      state = AuthState(user: response.user);
      await NotificationService.saveTokenForUser(response.user?.id);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Registration failed. Please try again.');
    }
  }

  /// Sign in with Google OAuth
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    if (!SupabaseConfig.isConfigured) {
      await Future.delayed(const Duration(seconds: 1));
      final mockUser = User(
        id: 'mock_user_google',
        appMetadata: const {},
        userMetadata: const {
          'full_name': 'Google Hustler',
          'avatar_url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200',
        },
        aud: 'authenticated',
        email: 'hustler@google.com',
        createdAt: DateTime.now().toIso8601String(),
      );
      state = AuthState(user: mockUser);
      return;
    }
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.zannycollection://login-callback',
      );
      // Auth state listener will update state on success
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Google sign-in failed.');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    if (!SupabaseConfig.isConfigured) {
      await Future.delayed(const Duration(milliseconds: 500));
      state = const AuthState();
      return;
    }
    try {
      await _client.auth.signOut();
      state = const AuthState();
    } catch (_) {
      state = const AuthState();
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    if (!SupabaseConfig.isConfigured) {
      return;
    }
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.zannycollection://reset-callback',
      );
    } catch (e) {
      print('⚠️ Supabase error in resetPassword: $e');
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isSignedIn;
});
