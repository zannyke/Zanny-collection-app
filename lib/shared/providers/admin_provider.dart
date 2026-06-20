import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple admin credentials for demo purposes.
/// In production these should be securely stored and managed.
class AdminCredentials {
  final String email;
  final String password;

  const AdminCredentials({required this.email, required this.password});
}

/// Provider exposing the admin credentials.
/// Replace the values with real credentials as needed.
final adminCredentialsProvider = Provider<AdminCredentials>((ref) {
  return const AdminCredentials(
    email: 'admin@zannycollection.com',
    password: 'zanny2026',
  );
});

/// Helper provider to check if the current user is admin.
/// Usage: `ref.watch(isAdminProvider(user?.email))`.
final isAdminProvider = Provider.family<bool, String?>((ref, email) {
  final admin = ref.watch(adminCredentialsProvider);
  return email != null && email.toLowerCase() == admin.email.toLowerCase();
});
