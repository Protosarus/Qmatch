import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/persona_scoring/persona_assignment_coordinator.dart';
import '../domain/persona_scoring/persona_runtime_handoff_result.dart';
import 'assessment_flow_complete_screen.dart';
import 'persona_reveal_screen.dart';

/// Live post-20D gate: reuse or assign+persist Persona, then reveal.
///
/// On persistence/assignment failure shows a retryable error and does not
/// continue into the post-assessment flow. Matching/Discover are not coupled.
class PersonaAssignmentGateScreen extends StatefulWidget {
  const PersonaAssignmentGateScreen({
    super.key,
    this.profileCompleted,
    this.coordinator,
    this.uidOverride,
    this.authService,
  });

  /// When known (e.g. Frequency live path); otherwise looked up on Continue.
  final bool? profileCompleted;

  /// Tests inject a coordinator; production constructs the default.
  final PersonaAssignmentCoordinator? coordinator;

  /// Tests inject a uid; production uses FirebaseAuth.currentUser.
  final String? uidOverride;

  final AuthService? authService;

  @override
  State<PersonaAssignmentGateScreen> createState() =>
      _PersonaAssignmentGateScreenState();
}

class _PersonaAssignmentGateScreenState
    extends State<PersonaAssignmentGateScreen> {
  late Future<PersonaAssignmentOutcome> _future;

  @override
  void initState() {
    super.initState();
    _future = _resolve();
  }

  Future<PersonaAssignmentOutcome> _resolve() async {
    final uid = widget.uidOverride ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return PersonaAssignmentOutcome.fail(
        StateError('Owner UID unavailable for Persona assignment'),
      );
    }
    final coordinator = widget.coordinator ?? PersonaAssignmentCoordinator();
    return coordinator.resolveForUid(uid);
  }

  void _retry() {
    setState(() {
      _future = _resolve();
    });
  }

  Future<void> _onContinue(PersonaRuntimeHandoffResult result) async {
    final known = widget.profileCompleted;
    final profileCompleted =
        known ?? await (widget.authService ?? AuthService()).hasCompletedProfile();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AssessmentFlowCompleteScreen(
          profileCompleted: profileCompleted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PersonaAssignmentOutcome>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _PersonaAssignmentLoadingScaffold();
        }

        final outcome = snap.data;
        if (snap.hasError ||
            outcome == null ||
            !outcome.ok ||
            outcome.result == null) {
          return PersonaAssignmentErrorScaffold(onRetry: _retry);
        }

        final result = outcome.result!;
        return PersonaRevealScreen(
          primaryPersonaId: result.primaryPersonaId,
          secondaryPersonaId: result.secondaryPersonaId,
          onContinue: () => _onContinue(result),
        );
      },
    );
  }
}

class _PersonaAssignmentLoadingScaffold extends StatelessWidget {
  const _PersonaAssignmentLoadingScaffold();

  static const Color _spinner = Color(0xFFDAC8ED);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('persona-assignment-loading'),
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

/// Recoverable Persona persistence/assignment failure — does not continue.
class PersonaAssignmentErrorScaffold extends StatelessWidget {
  const PersonaAssignmentErrorScaffold({
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
    final title = isTr
        ? 'Persona kaydedilemedi'
        : "Couldn't save your Persona";
    final body = isTr
        ? 'Bağlantını kontrol edip yeniden dene. Değerlendirmelerin korunur.'
        : 'Check your connection and try again. Your assessments are safe.';
    final retryLabel = l10n?.retry ?? (isTr ? 'Yeniden dene' : 'Retry');

    return Scaffold(
      key: const Key('persona-assignment-error'),
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
                  key: const Key('persona-assignment-retry'),
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
