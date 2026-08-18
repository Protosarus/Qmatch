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

class AuthWrapper extends StatefulWidget {
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
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _startupUid;
  int? _startupTick;
  Future<_AuthStartup>? _startupFuture;

  void _clearStartupCache() {
    _startupUid = null;
    _startupTick = null;
    _startupFuture = null;
  }

  Future<_AuthStartup> _startupFor(String uid, int refreshToken) {
    if (_startupFuture != null &&
        _startupUid == uid &&
        _startupTick == refreshToken) {
      return _startupFuture!;
    }
    _startupUid = uid;
    _startupTick = refreshToken;
    _startupFuture = _runStartup(uid);
    return _startupFuture!;
  }

  Future<_AuthStartup> _runStartup(String uid) async {
    final userDoc = await AuthService().ensureUserDocumentExists();
    final nameOk =
        DisplayNameService.isValidCanonicalDisplayNameFromMap(userDoc);
    return _AuthStartup(userDoc: userDoc, hasValidDisplayName: nameOk);
  }

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
              _clearStartupCache();
              return const WelcomeScreen();
            }

            final user = snapshot.data!;

            return IosIapSessionHost(
              key: ValueKey('qmatch-iap-session-${user.uid}'),
              child: FutureBuilder<_AuthStartup>(
                future: _startupFor(user.uid, refreshToken),
                builder: (context, ensureSnap) {
                  if (ensureSnap.connectionState == ConnectionState.waiting) {
                    return const AuthAssessmentLoadingScaffold();
                  }

                  if (ensureSnap.hasError) {
                    return AuthAssessmentProgressErrorScaffold(
                      onRetry: () {
                        setState(_clearStartupCache);
                      },
                    );
                  }

                  final startup = ensureSnap.data;
                  if (startup == null || !startup.hasValidDisplayName) {
                    return const DisplayNameCompletionScreen();
                  }

                  return AssessmentProgressRouteGate(
                    uid: user.uid,
                    refreshToken: refreshToken,
                    initialUserDoc: startup.userDoc,
                    resolveRoute: widget.resolveAssessmentRoute,
                    buildDestination: widget.buildAssessmentDestinationOverride,
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

class _AuthStartup {
  const _AuthStartup({
    required this.userDoc,
    required this.hasValidDisplayName,
  });

  final Map<String, dynamic>? userDoc;
  final bool hasValidDisplayName;
}
