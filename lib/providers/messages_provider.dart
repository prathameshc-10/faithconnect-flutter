import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/foundation.dart';
import '../models/conversation_model.dart';
import '../services/firestore_service.dart';

class MessagesProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final List<Conversation> _all = [];
  String _query = '';
  bool _isLoading = false;
  String? _userId;

  List<Conversation> get conversations {
    if (_query.isEmpty) return List.unmodifiable(_all);
    final q = _query.toLowerCase();
    return List.unmodifiable(
      _all.where(
        (c) =>
            c.name.toLowerCase().contains(q) ||
            c.lastMessage.toLowerCase().contains(q),
      ),
    );
  }

  String get query => _query;
  bool get isLoading => _isLoading;

  /// Load conversations from Firestore
  Future<void> loadConversations(String userId) async {
    if (_userId == userId && _all.isNotEmpty) return;
    
    _userId = userId;
    _isLoading = true;
    notifyListeners();

    try {
      _firestoreService.getConversations(userId).listen(
        (conversationsData) async {
          _all.clear();
          
          for (final convData in conversationsData) {
            final participants = convData['participants'] as List<dynamic>? ?? [];
            final otherUserId = participants.firstWhere(
              (id) => id.toString() != userId,
              orElse: () => participants.isNotEmpty ? participants[0] : '',
            ).toString();

            if (otherUserId.isEmpty) continue;

            // Get other user's name (try leader first, then worshiper)
            String otherUserName = 'Unknown User';
            try {
              final leaderData = await _firestoreService.getLeaderData(otherUserId);
              if (leaderData != null) {
                otherUserName = leaderData['name'] as String? ?? otherUserName;
              } else {
                final worshiperData = await _firestoreService.getWorshiperData(otherUserId);
                if (worshiperData != null) {
                  otherUserName = worshiperData['name'] as String? ?? otherUserName;
                }
              }
            } catch (e) {
              debugPrint('Error loading user name: $e');
            }

            final lastMessageTime = convData['lastMessageTime'] as firestore.Timestamp?;
            final participantsList = participants.map((e) => e.toString()).toList();
            _all.add(Conversation(
              id: convData['id'] as String,
              name: otherUserName,
              lastMessage: convData['lastMessage'] as String? ?? '',
              timestamp: lastMessageTime?.toDate() ?? DateTime.now(),
              isUnread: false, // TODO: Implement unread tracking
              unreadCount: 0,
              participants: participantsList,
            ));
          }

          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Error loading conversations: $error');
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void setQuery(String q) {
    if (_query != q) {
      _query = q;
      notifyListeners();
    }
  }

  Future<void> markRead(String conversationId) async {
    if (_userId == null) return;
    
    try {
      await _firestoreService.markMessagesAsRead(
        conversationId: conversationId,
        userId: _userId!,
      );
      // Update local state
      final idx = _all.indexWhere((c) => c.id == conversationId);
      if (idx != -1) {
        _all[idx] = _all[idx].copyWith(isUnread: false, unreadCount: 0);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Conversation? getById(String id) {
    try {
      return _all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
