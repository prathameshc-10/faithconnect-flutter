import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Service for Firebase Storage operations
/// Handles profile image uploads
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload profile image for a user
  /// Returns the download URL of the uploaded image
  Future<String> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$userId.jpg');
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Delete profile image for a user
  Future<void> deleteProfileImage(String userId) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$userId.jpg');
      await ref.delete();
    } catch (e) {
      // Ignore if file doesn't exist
    }
  }

  /// Upload post image
  /// Returns the download URL of the uploaded image
  Future<String> uploadPostImage({
    required String postId,
    required File imageFile,
  }) async {
    try {
      final ref = _storage.ref().child('posts').child('images').child('$postId.jpg');
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload post image: $e');
    }
  }

  /// Upload post/reel video
  /// Returns the download URL of the uploaded video
  Future<String> uploadVideo({
    required String contentId,
    required File videoFile,
    bool isReel = false,
  }) async {
    try {
      final folder = isReel ? 'reels' : 'posts';
      final ref = _storage.ref().child(folder).child('videos').child('$contentId.mp4');
      await ref.putFile(videoFile);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }
}
