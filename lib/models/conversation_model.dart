class Conversation {
  final String id;
  final String name;
  final String? avatarUrl; // optional remote URL
  final String lastMessage;
  final DateTime timestamp;
  final bool isUnread;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.lastMessage,
    required this.timestamp,
    this.isUnread = false,
    this.unreadCount = 0,
  });

  Conversation copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? lastMessage,
    DateTime? timestamp,
    bool? isUnread,
    int? unreadCount,
  }) {
    return Conversation(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      timestamp: timestamp ?? this.timestamp,
      isUnread: isUnread ?? this.isUnread,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
