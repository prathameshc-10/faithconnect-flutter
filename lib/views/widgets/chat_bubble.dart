import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final DateTime timestamp;
  final bool isSent;

  const ChatBubble({super.key, required this.text, required this.timestamp, required this.isSent});

  String _formatTime(DateTime t) {
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour.$minute';
  }

  @override
  Widget build(BuildContext context) {
    final bg = isSent ? Colors.grey[200] : Colors.grey[200];
    final fg = Colors.black87;
    final align = isSent ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: align,
      child: Padding(
        padding: EdgeInsets.only(
          left: isSent ? 40 : 8,
          right: isSent ? 8 : 40,
          top: 6,
          bottom: 6,
        ),
        child: Column(
          crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                text,
                style: TextStyle(color: fg, fontSize: 15),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _formatTime(timestamp),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
