/// User model representing a religious leader or user in the app
class UserModel {
  final String id;
  final String name;
  final String username;
  final String profileImageUrl;
  final bool isVerified;
  final String? description; // Optional description/bio
  final String? community; // Community (Hindu / Christian / Sikh etc.)
  final String? role; // Short description or role (e.g., "Temple Priest", "Pastor")

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.profileImageUrl,
    this.isVerified = false,
    this.description,
    this.community,
    this.role,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? profileImageUrl,
    bool? isVerified,
    String? description,
    String? community,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isVerified: isVerified ?? this.isVerified,
      description: description ?? this.description,
      community: community ?? this.community,
      role: role ?? this.role,
    );
  }
}
