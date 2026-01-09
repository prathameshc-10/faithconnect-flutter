import 'package:flutter/material.dart';
import '../../models/message_model.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String title;
  final bool isOnline;

  const ChatScreen({super.key, this.title = 'Leader', this.isOnline = true});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMockMessages();
  }

  void _loadMockMessages() {
    final now = DateTime.now();
    _messages.addAll([
      Message(id: 'm1', text: 'Hello! How are you?', timestamp: now.subtract(const Duration(minutes: 70)), isSent: false),
      Message(id: 'm2', text: 'I am well, thank you. The sermon was uplifting.', timestamp: now.subtract(const Duration(minutes: 65)), isSent: true),
      Message(id: 'm3', text: 'Praise God! 🙌', timestamp: now.subtract(const Duration(minutes: 12)), isSent: false),
      Message(id: 'm4', text: 'Are you joining the prayer meeting tomorrow?', timestamp: now.subtract(const Duration(minutes: 9)), isSent: true),
      Message(id: 'm5', text: 'Yes, I will be there.', timestamp: now.subtract(const Duration(minutes: 2)), isSent: false),
    ]);
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final msg = Message(id: DateTime.now().millisecondsSinceEpoch.toString(), text: text, timestamp: DateTime.now(), isSent: true);
    setState(() {
      _messages.add(msg);
    });
    _controller.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const CircleAvatar(radius: 18, backgroundColor: Colors.blueAccent, child: Icon(Icons.person, color: Colors.white, size: 18)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(widget.isOnline ? 'Online' : 'Offline', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final m = _messages[index];
                  return Align(
                    alignment: m.isSent ? Alignment.centerRight : Alignment.centerLeft,
                    child: ChatBubble(text: m.text, timestamp: m.timestamp, isSent: m.isSent),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Message',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      shape: const CircleBorder(),
                      color: Theme.of(context).colorScheme.primary,
                      child: IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}