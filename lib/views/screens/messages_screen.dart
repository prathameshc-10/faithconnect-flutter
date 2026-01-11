import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/messages_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/user_role_provider.dart';
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
  String? _profileImageUrl;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _loadUserProfile();
  }

  void _loadConversations() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appState = context.read<AppStateProvider>();
      final userId = appState.userId;
      if (userId != null) {
        context.read<MessagesProvider>().loadConversations(userId);
      }
    });
  }

  // ✅ NEW: Load user profile photo
  Future<void> _loadUserProfile() async {
    final appState = context.read<AppStateProvider>();
    final userId = appState.userId;
    final userRole = appState.userRole;

    if (userId == null || userRole == null) {
      setState(() => _isLoadingProfile = false);
      return;
    }

    try {
      Map<String, dynamic>? userData;

      if (userRole == UserRole.leader) {
        userData = await _firestoreService.getLeaderData(userId);
      } else {
        userData = await _firestoreService.getWorshiperData(userId);
      }

      if (userData != null && mounted) {
        setState(() {
          _profileImageUrl = userData?['profileImageUrl'] as String?;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  Future<void> _openChat(
    String conversationId,
    String receiverId,
  ) async {
    if (!mounted) return;

    final appState = context.read<AppStateProvider>();
    final userId = appState.userId;
    if (userId == null) return;

    await _firestoreService.markMessagesAsRead(
      conversationId: conversationId,
      userId: userId,
    );

    context.read<MessagesProvider>().markRead(conversationId);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversationId,
          receiverId: receiverId,
          title: 'Chat',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// APP BAR
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
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.only(right: 16),
        //     child: _isLoadingProfile
        //         ? CircleAvatar(
        //             radius: 18,
        //             backgroundColor: Colors.grey[300],
        //             child: const SizedBox(
        //               width: 16,
        //               height: 16,
        //               child: CircularProgressIndicator(
        //                 strokeWidth: 2,
        //                 color: Colors.grey,
        //               ),
        //             ),
        //           )
        //         : CircleAvatar(
        //             radius: 18,
        //             backgroundColor: Colors.grey[300],
        //             backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
        //                 ? NetworkImage(_profileImageUrl!)
        //                 : null,
        //             child: _profileImageUrl == null || _profileImageUrl!.isEmpty
        //                 ? const Icon(
        //                     Icons.person,
        //                     color: Colors.grey,
        //                     size: 20,
        //                   )
        //                 : null,
        //           ),
        //   ),
        // ],
      ),

      /// BODY
      body: Column(
        children: [
          /// SEARCH BAR
          Consumer<MessagesProvider>(
            builder: (context, provider, _) {
              return MessagesSearchBar(
                value: provider.query,
                onChanged: provider.setQuery,
              );
            },
          ),

          /// CONVERSATION LIST
          Expanded(
            child: Consumer2<MessagesProvider, AppStateProvider>(
              builder: (context, provider, appState, _) {
                if (provider.isLoading &&
                    provider.conversations.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final userId = appState.userId ?? '';
                final allConversations = provider.conversations;

                /// 🔥 DEDUPLICATION LOGIC (KEY FIX)
                final Map<String, dynamic> uniqueByUser = {};

                for (final convo in allConversations) {
                  final participants = convo.participants ?? [];
                  if (participants.length < 2) continue;

                  final receiverId = participants.firstWhere(
                    (id) => id != userId,
                    orElse: () => '',
                  );

                  if (receiverId.isEmpty) continue;

                  // Keep the most recent conversation only
                  if (!uniqueByUser.containsKey(receiverId)) {
                    uniqueByUser[receiverId] = convo;
                  }
                }

                final conversations =
                    uniqueByUser.values.toList();

                if (conversations.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
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
                            'Start a conversation from a leader profile',
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
                    if (userId.isNotEmpty) {
                      await provider.loadConversations(userId);
                    }
                  },
                  child: ListView.separated(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8),
                    itemCount: conversations.length,
                    separatorBuilder: (_, __) =>
                        const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final convo = conversations[index];
                      final participants =
                          convo.participants ?? [];

                      final receiverId =
                          participants.firstWhere(
                        (id) => id != userId,
                        orElse: () => '',
                      );

                      return ConversationTile(
                        conversation: convo,
                        onTap: receiverId.isNotEmpty
                            ? () => _openChat(
                                  convo.id,
                                  receiverId,
                                )
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