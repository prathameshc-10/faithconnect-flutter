import 'package:faith_connect/providers/app_state_provider.dart';
import 'package:faith_connect/providers/user_role_provider.dart';
import 'package:faith_connect/providers/posts_provider.dart';
import 'package:faith_connect/services/firestore_service.dart';
import 'package:faith_connect/models/user_model.dart';
import 'package:faith_connect/views/widgets/leader_main_navigation.dart';
import 'package:faith_connect/views/widgets/worshiper_main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sign_in_screen.dart';
import 'leader_profile_setup_screen.dart';


class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _hasCachedUser = false;

  Future<void> _cacheCurrentUser(String userId, UserRole role) async {
    if (_hasCachedUser) return;
    
    try {
      final postsProvider = context.read<PostsProvider>();
      
      Map<String, dynamic>? userData;
      if (role == UserRole.leader) {
        userData = await _firestoreService.getLeaderData(userId);
      } else {
        userData = await _firestoreService.getWorshiperData(userId);
      }
      
      if (userData != null) {
        final currentUser = UserModel(
          id: userId,
          name: userData['name'] as String? ?? '',
          username: '@${(userData['name'] as String? ?? '').toLowerCase().replaceAll(' ', '_')}',
          profileImageUrl: userData['profileImageUrl'] as String? ?? '',
          isVerified: false,
          description: role == UserRole.leader ? (userData['bio'] as String?) : null,
          community: userData['community'] as String?,
          role: role == UserRole.leader ? (userData['role'] as String?) : 'worshiper',
        );
        
        postsProvider.cacheCurrentUser(currentUser);
        _hasCachedUser = true;
      }
    } catch (e) {
      debugPrint('Error caching current user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    if (!appState.isAuthenticated) {
      _hasCachedUser = false;
      return const SignInScreen();
    }

    if (appState.userRole == null || appState.userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Cache current user for comment functionality
    if (appState.userId != null && appState.userRole != null && !_hasCachedUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cacheCurrentUser(appState.userId!, appState.userRole!);
      });
    }

    switch (appState.userRole!) {
      case UserRole.leader:
        if (!appState.isLeaderProfileComplete) {
          return const LeaderProfileSetupScreen();
        }
        return const LeaderMainNavigation();

      case UserRole.worshiper:
        return const WorshiperMainNavigation();
    }
  }
}