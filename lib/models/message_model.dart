class Message {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isSent; // true if current user sent it

  Message({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isSent,
  });

  Message copyWith({String? id, String? text, DateTime? timestamp, bool? isSent}) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isSent: isSent ?? this.isSent,
    );
  }
}
