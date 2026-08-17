import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/assessment/services/assessment_cold_start_pending_reconciler.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/profile/screens/display_name_completion_screen.dart';
import '../../features/profile/services/display_name_service.dart';
import '../../features/iap/widgets/ios_iap_session_host.dart';
import '../services/auth_service.dart';
import 'assessment_progress_route_gate.dart';
import 'auth_routing_refresh.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({
    super.key,
    this.resolveAssessmentRoute,
    this.buildAssessmentDestinationOverride,
  });

  /// Test injection for assessment progress resolve. Production leaves null.
  final Future<AssessmentColdStartDecision> Function(String uid)?
      resolveAssessmentRoute;

  /// Test injection for destination widgets. Production leaves null.
  final Widget Function(AssessmentColdStartDecision decision)?
      buildAssessmentDestinationOverride;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AuthRoutingRefresh.tick,
      builder: (context, refreshToken, __) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AuthAssessmentLoadingScaffold();
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const WelcomeScreen();
            }

            final user = snapshot.data!;

            return IosIapSessionHost(
              key: ValueKey('qmatch-iap-session-${user.uid}'),
              child: FutureBuilder<void>(
                future: AuthService().ensureUserDocumentExists(),
                builder: (context, ensureSnap) {
                  if (ensureSnap.connectionState == ConnectionState.waiting) {
                    return const AuthAssessmentLoadingScaffold();
                  }

                  return FutureBuilder<bool>(
                    future: DisplayNameService()
                        .hasValidCanonicalDisplayName(user.uid),
                    builder: (context, nameSnap) {
                      if (nameSnap.connectionState == ConnectionState.waiting) {
                        return const AuthAssessmentLoadingScaffold();
                      }

                      if (nameSnap.data != true) {
                        return const DisplayNameCompletionScreen();
                      }

                      return AssessmentProgressRouteGate(
                        uid: user.uid,
                        refreshToken: refreshToken,
                        resolveRoute: resolveAssessmentRoute,
                        buildDestination: buildAssessmentDestinationOverride,
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
