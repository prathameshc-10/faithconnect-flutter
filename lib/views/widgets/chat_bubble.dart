import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final DateTime timestamp;
  final bool isSent;

  const ChatBubble({super.key, required this.text, required this.timestamp, required this.isSent});

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'now';
  }

  @override
  Widget build(BuildContext context) {
    final bg = isSent ? Colors.blue.shade600 : Colors.grey.shade200;
    final fg = isSent ? Colors.white : Colors.black87;
    final align = isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
      bottomLeft: Radius.circular(isSent ? 12 : 4),
      bottomRight: Radius.circular(isSent ? 4 : 12),
    );

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: EdgeInsets.only(
            left: isSent ? 40 : 8,
            right: isSent ? 8 : 40,
            top: 6,
            bottom: 6,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                text,
                style: TextStyle(color: fg, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                _formatTime(timestamp),
                style: TextStyle(color: fg.withOpacity(0.85), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
