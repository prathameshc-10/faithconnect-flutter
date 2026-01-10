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
}
