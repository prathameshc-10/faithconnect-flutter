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
        name: 'Rabbi Abraham Cohen',
        lastMessage: "Hey there! I have send a new...",
        timestamp: now.subtract(const Duration(minutes: 1)),
        isUnread: true,
        unreadCount: 1,
      ),
      Conversation(
        id: '2',
        name: 'Rabbi David Rosenberg',
        lastMessage: 'Thanks for your message. I appreciate...',
        timestamp: now.subtract(const Duration(minutes: 10)),
        isUnread: true,
        unreadCount: 2,
      ),
      Conversation(
        id: '3',
        name: 'Rabbi Aaron Kaplan',
        lastMessage: 'See you at the morning prayer 🙏',
        timestamp: DateTime(now.year, now.month, now.day - 1),
        isUnread: false,
        unreadCount: 0,
      ),
      Conversation(
        id: '4',
        name: 'Rabbi Samuel Katz',
        lastMessage: 'Can you share the notes?',
        timestamp: DateTime(2025, 9, 12),
        isUnread: false,
        unreadCount: 0,
      ),
      Conversation(
        id: '5',
        name: 'Rabbi Isaac Levi',
        lastMessage: 'Beautiful sermon today.',
        timestamp: DateTime(2025, 9, 10),
        isUnread: false,
        unreadCount: 0,
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
