/// User model representing a religious leader or user in the app
class UserModel {
  final String id;
  final String name;
  final String username;
  final String profileImageUrl;
  final bool isVerified;
  final String? description; // Optional description/bio

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.profileImageUrl,
    this.isVerified = false,
    this.description,
  });
}
