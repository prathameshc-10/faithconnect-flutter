import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/user_role_provider.dart';
import 'sign_in_screen.dart';
import 'leader_profile_setup_screen.dart';
import '../widgets/leader_main_navigation.dart';
import '../widgets/worshiper_main_navigation.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('🚪 AuthGate.build() called');
    
    // ✅ Use Consumer instead of context.watch for guaranteed rebuilds
    return Consumer<AppStateProvider>(
      builder: (context, appState, _) {
        debugPrint('🔄 AuthGate Consumer rebuilding');
        debugPrint('   - isAuthenticated: ${appState.isAuthenticated}');
        debugPrint('   - userRole: ${appState.userRole}');
        debugPrint('   - userId: ${appState.userId}');

        if (!appState.isAuthenticated) {
          debugPrint('➡️  Routing to: SignInScreen');
          return const SignInScreen();
        }

        if (appState.userRole == null) {
          debugPrint('⏳ Showing loading...');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        debugPrint('🎭 Routing based on role: ${appState.userRole}');

        switch (appState.userRole!) {
          case UserRole.leader:
            if (!appState.isLeaderProfileComplete) {
              debugPrint('➡️  Routing to: LeaderProfileSetupScreen');
              return const LeaderProfileSetupScreen();
            }
            debugPrint('➡️  Routing to: LeaderMainNavigation');
            return const LeaderMainNavigation();

          case UserRole.worshiper:
            debugPrint('➡️  Routing to: WorshiperMainNavigation');
            return const WorshiperMainNavigation();
        }
      },
    );
  }
}