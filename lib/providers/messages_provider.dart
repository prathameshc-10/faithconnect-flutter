import 'package:flutter/foundation.dart';
import '../models/conversation_model.dart';

class MessagesProvider extends ChangeNotifier {
  final List<Conversation> _all = [];
  String _query = '';

  MessagesProvider() {
    _loadMockData();
  }

  void _loadMockData() {
    final now = DateTime.now();
    _all.addAll([
      Conversation(
        id: '1',
        name: 'Sister Grace',
        lastMessage: "See you at the morning prayer 🙏",
        timestamp: now.subtract(const Duration(minutes: 5)),
        isUnread: true,
        unreadCount: 1,
      ),
      Conversation(
        id: '2',
        name: 'Pastor Emmanuel',
        lastMessage: 'Thanks for volunteering on Sunday.',
        timestamp: now.subtract(const Duration(hours: 2, minutes: 12)),
      ),
      Conversation(
        id: '3',
        name: 'Youth Group',
        lastMessage: 'Reminder: meeting on Friday!',
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
        isUnread: true,
        unreadCount: 3,
      ),
      Conversation(
        id: '4',
        name: 'Anna',
        lastMessage: 'Can you share the notes?',
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      Conversation(
        id: '5',
        name: 'Daniel',
        lastMessage: 'Beautiful sermon today.',
        timestamp: now.subtract(const Duration(minutes: 43)),
      ),
    ]);
  }

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

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void markRead(String id) {
    final idx = _all.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _all[idx] = _all[idx].copyWith(isUnread: false, unreadCount: 0);
      notifyListeners();
    }
  }

  void markUnread(String id) {
    final idx = _all.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _all[idx] = _all[idx].copyWith(isUnread: true, unreadCount: 1);
      notifyListeners();
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
