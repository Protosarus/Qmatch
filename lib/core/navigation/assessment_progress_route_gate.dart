import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../debug/qmatch_perf.dart';
import '../../features/assessment/domain/frequency_v2_runtime/frequency_runtime_test_screen_factory.dart';
import '../../features/assessment/models/assessment_progress.dart';
import '../../features/assessment/screens/eq_test_intro_screen.dart';
import '../../features/assessment/screens/eq_test_screen.dart';
import '../../features/assessment/screens/frequency_intro_screen.dart';
import '../../features/assessment/screens/iq_test_intro_screen.dart';
import '../../features/assessment/screens/iq_test_screen.dart';
import '../../features/assessment/screens/persona_assignment_gate_screen.dart';
import '../../features/assessment/services/assessment_cold_start_pending_reconciler.dart';
import '../../features/assessment/services/assessment_progress_service.dart';
import '../../features/profile/screens/profile_setup_screen.dart';
import '../../l10n/app_localizations.dart';
import '../notifications/message_push_tap_host.dart';
import '../notifications/notification_registration_host.dart';
import '../theme/app_colors.dart';

/// Resolves assessment routing after auth + display-name gates.
///
/// Progress read / network / Firestore failures must not be treated as
/// "IQ not completed" — they show a retryable error instead.
class AssessmentProgressRouteGate extends StatefulWidget {
  const AssessmentProgressRouteGate({
    super.key,
    required this.uid,
    this.refreshToken = 0,
    this.initialUserDoc,
    this.resolveRoute,
    this.buildDestination,
  });

  final String uid;

  /// Bumped by [AuthRoutingRefresh] so progress is re-resolved after flow steps.
  final int refreshToken;

  /// Prefetched `users/{uid}` from the auth gate. Used only on first resolve.
  final Map<String, dynamic>? initialUserDoc;

  /// Tests inject failures / staged successes. Production uses progress +
  /// [AssessmentColdStartPendingReconciler].
  final Future<AssessmentColdStartDecision> Function(String uid)? resolveRoute;

  /// Tests may swap destination widgets; production builds real screens.
  final Widget Function(AssessmentColdStartDecision decision)? buildDestination;

  @override
  State<AssessmentProgressRouteGate> createState() =>
      _AssessmentProgressRouteGateState();
}

class _AssessmentProgressRouteGateState
    extends State<AssessmentProgressRouteGate> {
  late Future<AssessmentColdStartDecision> _future;

  @override
  void initState() {
    super.initState();
    _future = _resolve(userDoc: widget.initialUserDoc);
  }

  @override
  void didUpdateWidget(covariant AssessmentProgressRouteGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid ||
        oldWidget.refreshToken != widget.refreshToken) {
      _future = _resolve(
        userDoc: oldWidget.refreshToken != widget.refreshToken
            ? null
            : widget.initialUserDoc,
      );
    }
  }

  Future<AssessmentColdStartDecision> _resolve(
      {Map<String, dynamic>? userDoc}) {
    final custom = widget.resolveRoute;
    if (custom != null) return custom(widget.uid);
    return defaultResolveAssessmentRoute(widget.uid, userDoc: userDoc);
  }

  void _retry() {
    setState(() {
      _future = _resolve();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AssessmentColdStartDecision>(
      future: _future,
      builder: (context, routeSnap) {
        if (routeSnap.connectionState == ConnectionState.waiting) {
          return const AuthAssessmentLoadingScaffold();
        }

        if (routeSnap.hasError || !routeSnap.hasData) {
          return AuthAssessmentProgressErrorScaffold(onRetry: _retry);
        }

        final decision = routeSnap.data!;
        final custom = widget.buildDestination;
        if (custom != null) return custom(decision);
        return buildAssessmentDestination(decision);
      },
    );
  }
}

/// Default AuthWrapper resolve path (progress → cold-start reconcile).
Future<AssessmentColdStartDecision> defaultResolveAssessmentRoute(
  String uid, {
  Map<String, dynamic>? userDoc,
}) {
  return QmatchPerf.trace('auth.gate', () async {
    final progress = await AssessmentProgressService().resolveForUid(
      uid,
      userDoc: userDoc,
    );
    return AssessmentColdStartPendingReconciler().reconcile(
      uid: uid,
      progress: progress,
    );
  });
}

/// Maps a successful cold-start decision to the live onboarding screen.
Widget buildAssessmentDestination(AssessmentColdStartDecision decision) {
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
      // Pending recovery (including V2) must use the shared factory so a
      // V2 locked session is not opened on the V1 Frequency test screen.
      return decision.openAssessmentTestScreen
          ? FrequencyRuntimeTestScreenFactory.build()
          : const FrequencyIntroScreen();
    case AssessmentFlowDestination.persona:
      return const PersonaAssignmentGateScreen();
    case AssessmentFlowDestination.profileSetup:
      return const ProfileSetupScreen();
    case AssessmentFlowDestination.main:
      return const NotificationRegistrationHost(
        child: MessagePushTapHost(),
      );
  }
}

class AuthAssessmentLoadingScaffold extends StatelessWidget {
  const AuthAssessmentLoadingScaffold({super.key});

  static const Color _spinner = Color(0xFFDAC8ED);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('auth-assessment-progress-loading'),
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

/// Safe recoverable state when assessment progress cannot be read.
class AuthAssessmentProgressErrorScaffold extends StatelessWidget {
  const AuthAssessmentProgressErrorScaffold({
    super.key,
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTr =
        Localizations.maybeLocaleOf(context)?.languageCode.startsWith('tr') ??
            false;
    final title = isTr ? 'İlerleme yüklenemedi' : "Couldn't load your progress";
    final body = isTr
        ? 'Bağlantını kontrol edip yeniden dene. Bu, değerlendirmeyi baştan '
            'başlatmaz.'
        : 'Check your connection and try again. This does not restart your '
            'assessment.';
    final retryLabel = l10n?.retry ?? (isTr ? 'Yeniden dene' : 'Retry');

    return Scaffold(
      key: const Key('auth-assessment-progress-error'),
      backgroundColor: const Color(0xFF0C0C0C),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                  size: 36,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                TextButton(
                  key: const Key('auth-assessment-progress-retry'),
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFDAC8ED),
                  ),
                  child: Text(retryLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
