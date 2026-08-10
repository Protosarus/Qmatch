import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/assessment/models/assessment_progress.dart';
import '../../features/assessment/screens/eq_test_intro_screen.dart';
import '../../features/assessment/screens/eq_test_screen.dart';
import '../../features/assessment/screens/frequency_intro_screen.dart';
import '../../features/assessment/screens/frequency_test_screen.dart';
import '../../features/assessment/screens/iq_test_intro_screen.dart';
import '../../features/assessment/screens/iq_test_screen.dart';
import '../../features/assessment/services/assessment_cold_start_pending_reconciler.dart';
import '../../features/assessment/services/assessment_progress_service.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/profile/screens/display_name_completion_screen.dart';
import '../../features/profile/screens/profile_setup_screen.dart';
import '../../features/profile/services/display_name_service.dart';
import '../services/auth_service.dart';
import 'auth_routing_refresh.dart';
import 'main_navigation_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<AssessmentColdStartDecision> _resolveAssessmentRoute(String uid) async {
    final progress = await AssessmentProgressService().resolveForUid(uid);
    return AssessmentColdStartPendingReconciler().reconcile(
      uid: uid,
      progress: progress,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AuthRoutingRefresh.tick,
      builder: (context, _, __) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _AuthLoadingScaffold();
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const WelcomeScreen();
            }

            final user = snapshot.data!;

            return FutureBuilder<void>(
              future: AuthService().ensureUserDocumentExists(),
              builder: (context, ensureSnap) {
                if (ensureSnap.connectionState == ConnectionState.waiting) {
                  return const _AuthLoadingScaffold();
                }

                return FutureBuilder<bool>(
                  future: DisplayNameService()
                      .hasValidCanonicalDisplayName(user.uid),
                  builder: (context, nameSnap) {
                    if (nameSnap.connectionState == ConnectionState.waiting) {
                      return const _AuthLoadingScaffold();
                    }

                    if (nameSnap.data != true) {
                      return const DisplayNameCompletionScreen();
                    }

                    return FutureBuilder<AssessmentColdStartDecision>(
                      future: _resolveAssessmentRoute(user.uid),
                      builder: (context, routeSnap) {
                        if (routeSnap.connectionState ==
                            ConnectionState.waiting) {
                          return const _AuthLoadingScaffold();
                        }

                        if (routeSnap.hasError || !routeSnap.hasData) {
                          return const IQTestIntroScreen();
                        }

                        final decision = routeSnap.data!;
                        switch (decision.destination) {
                          case AssessmentFlowDestination.iq:
                            return decision.openAssessmentTestScreen
                                ? const IQTestScreen()
                                : const IQTestIntroScreen();
                          case AssessmentFlowDestination.eq:
                            return decision.openAssessmentTestScreen
                                ? const EQTestScreen()
                                : const EQTestIntroScreen();
                          case AssessmentFlowDestination.frequency:
                            return decision.openAssessmentTestScreen
                                ? const FrequencyTestScreen()
                                : const FrequencyIntroScreen();
                          case AssessmentFlowDestination.profileSetup:
                            return const ProfileSetupScreen();
                          case AssessmentFlowDestination.main:
                            return const MainNavigationScreen();
                        }
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AuthLoadingScaffold extends StatelessWidget {
  const _AuthLoadingScaffold();

  /// Cool lavender — Frequency / cosmic accent (not soft-gold).
  static const Color _spinner = Color(0xFFDAC8ED);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0C0C0C),
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_spinner),
          strokeWidth: 2.6,
        ),
      ),
    );
  }
}
