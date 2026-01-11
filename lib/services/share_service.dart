import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

/// Service for sharing content using the native system share sheet
class ShareService {
  /// Share a post or reel
  /// 
  /// [text] - The content text to share
  /// [videoUrl] - Optional video URL to include in the share
  /// 
  /// Returns true if the share dialog was opened successfully, false otherwise
  Future<bool> sharePost({
    required String text,
    String? videoUrl,
  }) async {
    try {
      // Build the share message
      String shareMessage = text;
      
      // Add video URL if provided
      if (videoUrl != null && videoUrl.isNotEmpty) {
        shareMessage = '$text\n\nWatch here 👇\n$videoUrl';
      }
      
      // Open the native share sheet
      final result = await Share.share(shareMessage);
      
      // Return true if share dialog was opened (result.status indicates completion)
      // We consider it successful if the dialog opened, regardless of whether user actually shared
      return true;
    } catch (e) {
      // Log error and return false
      debugPrint('Error sharing post: $e');
      return false;
    }
  }
}
