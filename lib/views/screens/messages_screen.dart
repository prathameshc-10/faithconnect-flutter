import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/messages_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../services/firestore_service.dart';
import '../widgets/search_bar.dart';
import '../widgets/conversation_tile.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appState = context.read<AppStateProvider>();
      if (appState.userId != null) {
        context.read<MessagesProvider>().loadConversations(appState.userId!);
      }
    });
  }

  Future<void> _openChat(String conversationId, String receiverId) async {
    if (!mounted) return;
    
    // Mark messages as read
    final appState = context.read<AppStateProvider>();
    if (appState.userId != null) {
      await _firestoreService.markMessagesAsRead(
        conversationId: conversationId,
        userId: appState.userId!,
      );
      context.read<MessagesProvider>().markRead(conversationId);
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversationId,
          title: 'Chat',
          receiverId: receiverId,
        ),
      ),
    );
  }

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
            child: Consumer2<MessagesProvider, AppStateProvider>(
              builder: (context, provider, appState, _) {
                if (provider.isLoading && provider.conversations.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final convos = provider.conversations;
                if (convos.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No conversations yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a conversation with a leader from their profile',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    if (appState.userId != null) {
                      await provider.loadConversations(appState.userId!);
                    }
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: convos.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, i) {
                      final c = convos[i];
                      // Get receiver ID from participants
                      final currentUserId = appState.userId ?? '';
                      final receiverId = c.participants?.firstWhere(
                        (id) => id != currentUserId,
                        orElse: () => c.participants?.isNotEmpty == true 
                            ? c.participants!.first 
                            : '',
                      ) ?? '';
                      
                      return ConversationTile(
                        conversation: c,
                        onTap: receiverId.isNotEmpty 
                            ? () => _openChat(c.id, receiverId)
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
