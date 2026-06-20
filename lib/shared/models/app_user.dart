/// Application user model — replaces Supabase's User class.
/// Shared between auth_provider and all screens.
class AppUser {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String avatarUrl;
  final bool isAdmin;
  final String createdAt;

  const AppUser({
    required this.id,
    required this.email,
    this.fullName = '',
    this.phone = '',
    this.avatarUrl = '',
    this.isAdmin = false,
    this.createdAt = '',
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      isAdmin: json['is_admin'] == true || json['is_admin'] == 1,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'phone': phone,
    'avatar_url': avatarUrl,
    'is_admin': isAdmin,
    'created_at': createdAt,
  };

  AppUser copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) {
    return AppUser(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isAdmin: isAdmin,
      createdAt: createdAt,
    );
  }

  /// Display name falls back to email prefix if fullName is empty.
  String get displayName => fullName.isNotEmpty ? fullName : email.split('@').first;

  /// User metadata map compatible with existing screens that read userMetadata.
  Map<String, dynamic> get userMetadata => {
    'full_name': fullName,
    'phone': phone,
    'avatar_url': avatarUrl,
  };
}
