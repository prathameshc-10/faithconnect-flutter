import 'user_model.dart';

/// Post model representing a post in the feed
class PostModel {
  final String id;
  final UserModel author;
  final String content;
  final String? videoUrl;
  final String? imageUrl;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final int shares;
  final int views;

  PostModel({
    required this.id,
    required this.author,
    required this.content,
    this.videoUrl,
    this.imageUrl,
    required this.createdAt,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.views,
  });
}
