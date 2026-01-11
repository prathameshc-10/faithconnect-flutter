import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'user_model.dart';

/// Comment model representing a comment on a post
class CommentModel {
  final String id;
  final String userId;
  final String text;
  final DateTime createdAt;
  final UserModel? author; // Optional, loaded separately

  CommentModel({
    required this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
    this.author,
  });

  /// Create CommentModel from Firestore document
  factory CommentModel.fromFirestore(Map<String, dynamic> data, String id) {
    final timestamp = data['createdAt'] as firestore.Timestamp?;
    return CommentModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: timestamp?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert CommentModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'text': text,
      'createdAt': firestore.FieldValue.serverTimestamp(),
    };
  }
}
