import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/messages_provider.dart';
import '../widgets/search_bar.dart';
import '../widgets/conversation_tile.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // Profile avatar on the right
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              child: const Icon(
                Icons.person,
                color: Colors.grey,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Consumer<MessagesProvider>(builder: (context, provider, _) {
            return MessagesSearchBar(
              value: provider.query,
              onChanged: provider.setQuery,
            );
          }),
          Expanded(
            child: Consumer<MessagesProvider>(
              builder: (context, provider, _) {
                final convos = provider.conversations;
                if (convos.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'No conversations yet. Start a new message to connect with your community.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: convos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, i) {
                    final c = convos[i];
                    return ConversationTile(
                      conversation: c,
                      onTap: () {
                        // Mark read and open chat screen
                        provider.markRead(c.id);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ChatScreen(title: c.name, isOnline: c.isUnread)),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
