import 'package:faith_connect/providers/app_state_provider.dart';
import 'package:faith_connect/providers/user_role_provider.dart';
import 'package:faith_connect/views/widgets/leader_main_navigation.dart';
import 'package:faith_connect/views/widgets/worshiper_main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sign_in_screen.dart';
import 'leader_profile_setup_screen.dart';


class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    if (!appState.isAuthenticated) {
      return const SignInScreen();
    }

    if (appState.userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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