import 'user_model.dart';

/// Comment model representing a comment on a post
class CommentModel {
  final String id;
  final UserModel author;
  final String text;
  final DateTime createdAt;
  final int likes;

  CommentModel({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
    this.likes = 0,
  });
}
