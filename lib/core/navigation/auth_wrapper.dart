import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/assessment/services/assessment_cold_start_pending_reconciler.dart';
import '../../features/auth/screens/email_verification_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/profile/screens/display_name_completion_screen.dart';
import '../../features/profile/services/display_name_service.dart';
import '../../features/iap/widgets/ios_iap_session_host.dart';
import '../services/auth_service.dart';
import '../services/email_verification_policy.dart';
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

            final streamUser = snapshot.data!;
            final user = FirebaseAuth.instance.currentUser ?? streamUser;
            return AuthSignedInPolicyGate(
              user: user,
              child: IosIapSessionHost(
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
                      buildDestination:
                          widget.buildAssessmentDestinationOverride,
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Resolves the Phase 3 gate from the **current** sign-in provider.
///
/// Linked Google/Apple sessions are not password-gated. Mixed accounts wait
/// for the ID-token `sign_in_provider` when memory has no hint.
class AuthSignedInPolicyGate extends StatelessWidget {
  const AuthSignedInPolicyGate({
    super.key,
    required this.user,
    required this.child,
  });

  final User user;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final providerIds = user.providerData.map((info) => info.providerId);
    final sync = EmailVerificationPolicy.tryResolveSync(
      providerIds: providerIds,
      emailVerified: user.emailVerified,
      currentSignInProvider: SignInProviderMemory.current,
    );
    if (sync != null) {
      return AuthSignedInVerificationBranch(
        requiresEmailVerification: sync,
        email: user.email,
        child: child,
      );
    }
    return FutureBuilder<String?>(
      future: EmailVerificationPolicy.readTokenSignInProvider(user),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const AuthAssessmentLoadingScaffold();
        }
        final requires = EmailVerificationPolicy.requiresEmailVerification(
          providerIds: providerIds,
          emailVerified: user.emailVerified,
          currentSignInProvider: snap.data ?? SignInProviderMemory.current,
        );
        return AuthSignedInVerificationBranch(
          requiresEmailVerification: requires,
          email: user.email,
          child: child,
        );
      },
    );
  }
}

/// Signed-in branch used by the single root [AuthWrapper].
///
/// Unverified password users stay on [EmailVerificationScreen] and never
/// reach display-name / assessment / main routing.
class AuthSignedInVerificationBranch extends StatelessWidget {
  const AuthSignedInVerificationBranch({
    super.key,
    required this.requiresEmailVerification,
    required this.child,
    this.email,
  });

  final bool requiresEmailVerification;
  final String? email;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (requiresEmailVerification) {
      return EmailVerificationScreen(email: email);
    }
    return child;
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
