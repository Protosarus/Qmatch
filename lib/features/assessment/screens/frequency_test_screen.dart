import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/services/profile_service.dart';
import '../domain/frequency_bank/frequency_bank.dart';
import '../domain/frequency_session/frequency_session.dart';
import '../domain/profile/profile.dart';
import '../services/assessment_progress_service.dart';
import '../services/canonical_assessment_persistence.dart';
import '../services/canonical_assessment_profile_reconciler.dart';
import '../services/frequency_canonical_runtime_service.dart';
import '../utils/assessment_language.dart';
import '../widgets/assessment_capture_guard.dart';
import '../widgets/frequency_question_chrome.dart';
import '../widgets/q_assessment_scaffold.dart';
import 'assessment_flow_complete_screen.dart';

/// Canonical 50-item Frequency session — behavioral tendency, not correctness.
///
/// Completes the 20D measurement profile. Does NOT invoke Persona / Matching /
/// QRCF / quantum / RVI gating.
class FrequencyTestScreen extends StatefulWidget {
  const FrequencyTestScreen({super.key});

  @override
  State<FrequencyTestScreen> createState() => _FrequencyTestScreenState();
}

class _FrequencyTestScreenState extends State<FrequencyTestScreen> {
  final _runtime = FrequencyCanonicalRuntimeService();
  final _persistence = CanonicalAssessmentPersistence();
  final _progress = AssessmentProgressService();
  final _reconciler = CanonicalAssessmentProfileReconciler();

  FrequencyPersistedSessionState? _session;
  FrequencyCanonicalBankDocument? _bank;
  String? _selectedOptionId;
  bool _isLoading = true;
  bool _didStartLoading = false;
  bool _isFinishing = false;
  bool _busy = false;
  String? _loadError;
  DateTime? _startedAt;
  bool _showSelectAnswerWarning = false;
  Timer? _selectAnswerWarningTimer;

  static const _continueButtonHeight = 54.0;
  static const _warningAboveContinueGap = 62.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStartLoading) return;
    _didStartLoading = true;
    _bootstrap();
  }

  @override
  void dispose() {
    _selectAnswerWarningTimer?.cancel();
    super.dispose();
  }

  void _dismissSelectAnswerWarning() {
    _selectAnswerWarningTimer?.cancel();
    _selectAnswerWarningTimer = null;
    if (!_showSelectAnswerWarning || !mounted) return;
    setState(() => _showSelectAnswerWarning = false);
  }

  void _showSelectAnswerWarningBanner() {
    _selectAnswerWarningTimer?.cancel();
    if (!_showSelectAnswerWarning) {
      setState(() => _showSelectAnswerWarning = true);
    }
    _selectAnswerWarningTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _showSelectAnswerWarning = false);
    });
  }

  String _tendencyInstruction(AppLocalizations l10n) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    if (code.startsWith('tr')) {
      return 'Gerçekte yapma eğiliminde olduğunuz yanıta en yakın seçeneği seçin.';
    }
    return 'Choose the response closest to what you would actually tend to do.';
  }

  Future<void> _bootstrap() async {
    try {
      final languageCode = Localizations.maybeLocaleOf(context)?.languageCode ??
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      final created = await _runtime.getOrCreateActiveSession(
        preferredLanguageCode: languageCode,
      );
      if (!created.ok || created.state == null) {
        if (!mounted) return;
        setState(() {
          _loadError =
              created.message.isNotEmpty ? created.message : created.code;
          _isLoading = false;
        });
        return;
      }
      final session = created.state!;
      final bank = await _runtime.loadBankForLocale(session.bankLocale);
      final existing = session.answersByItemId[
          session.itemPlans[session.currentQuestionIndex].itemId];
      if (!mounted) return;
      setState(() {
        _session = session;
        _bank = bank;
        _selectedOptionId = existing?.selectedOptionId;
        _startedAt = DateTime.tryParse(session.startedAt) ?? DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Frequency canonical bootstrap failed: $e');
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _onContinue() async {
    final session = _session;
    final bank = _bank;
    if (session == null || bank == null || _isFinishing || _busy) return;

    final languageCode = Localizations.maybeLocaleOf(context)?.languageCode ??
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final language = AssessmentLanguage.languageUsed(
      languageCode: languageCode,
    );
    final locale = AssessmentLanguage.localeUsed(locale: Locale(language));

    if (session.status ==
        FrequencyPersistedSessionStatus.completedPendingPersistence) {
      await _finalizeRemoteAndNavigate(
        session: session,
        locale: locale,
        language: language,
      );
      return;
    }

    if (_selectedOptionId == null) {
      _showSelectAnswerWarningBanner();
      return;
    }
    _dismissSelectAnswerWarning();

    setState(() => _busy = true);
    try {
      var state = session;
      final curPlan = state.itemPlans[state.currentQuestionIndex];
      final existing = state.answersByItemId[curPlan.itemId];

      // Commit exactly once. Never overwrite a committed response.
      if (existing == null) {
        final answered = await _runtime.answer(
          sessionId: state.sessionId,
          itemId: curPlan.itemId,
          selectedOptionId: _selectedOptionId!,
        );
        if (!answered.ok || answered.state == null) {
          debugPrint('Frequency answer failed: ${answered.message}');
          if (!mounted) return;
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.iqCanonicalAnswerError)),
          );
          return;
        }
        state = answered.state!;
      } else if (existing.selectedOptionId != _selectedOptionId) {
        // Cursor stuck on a committed item — advance without re-answer.
        debugPrint(
          'Frequency skip re-answer for committed item ${curPlan.itemId}',
        );
      }

      final unanswered = state.firstUnansweredIndex;
      final isComplete = unanswered >= state.itemPlans.length;
      if (!isComplete) {
        final moved = await _runtime.moveToIndex(
          sessionId: state.sessionId,
          index: unanswered,
        );
        FrequencyPersistedSessionState? nextState = moved.state;
        if (!moved.ok || nextState == null) {
          final reconciled = await _runtime.reconcileCursor(
            sessionId: state.sessionId,
          );
          if (!reconciled.ok || reconciled.state == null) {
            if (!mounted) return;
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.iqCanonicalAnswerError)),
            );
            return;
          }
          nextState = reconciled.state;
        }
        if (!mounted) return;
        final next = nextState!;
        final existingNext = next
            .answersByItemId[next.itemPlans[next.currentQuestionIndex].itemId];
        setState(() {
          _session = next;
          _selectedOptionId = existingNext?.selectedOptionId;
        });
        return;
      }

      setState(() => _isFinishing = true);
      final completed = await _runtime.completeSession(
        sessionId: state.sessionId,
      );
      if (!completed.ok || completed.state == null) {
        throw StateError(completed.message);
      }
      if (!mounted) return;
      setState(() => _session = completed.state);
      await _finalizeRemoteAndNavigate(
        session: completed.state!,
        locale: locale,
        language: language,
      );
    } catch (e) {
      debugPrint('Frequency continue failed: $e');
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.iqCanonicalPersistError)),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Score → persist frequency → reconcile IQ4+EQ10 → Frequency→20D →
  /// mark flow complete → finalize session.
  Future<void> _finalizeRemoteAndNavigate({
    required FrequencyPersistedSessionState session,
    required String locale,
    required String language,
  }) async {
    setState(() => _isFinishing = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final scored = await _runtime.scoreCompleted(session);
      if (!scored.ok || scored.result == null) {
        throw StateError(scored.message ?? 'Frequency scoring failed');
      }
      final result = scored.result!;
      final bank = await _runtime.loadBankForLocale(session.bankLocale);
      final qualitySignals =
          FrequencyCanonicalRuntimeService.deriveQualitySignals(
        bank: bank,
        session: session,
      );

      await _persistence.upsertCompletedAssessment(
        assessmentType: 'frequency',
        fields: _persistence.buildCanonicalFrequency6dPayload(
          result: result,
          sessionId: session.sessionId,
          locale: locale,
          languageUsed: language,
          qualitySignals: qualitySignals,
          startedAt: _startedAt,
        ),
      );

      final uid = _runtime.currentUid;
      if (uid == null || uid.isEmpty) {
        throw StateError('Owner UID unavailable');
      }

      final repair = await _reconciler.ensureIq4AndEq10(ownerUid: uid);
      if (!repair.ok) {
        debugPrint(
          'Frequency pre-req 14/20 repair failed: ${repair.code} ${repair.message}',
        );
        if (!mounted) return;
        setState(() => _isFinishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.assessmentPrerequisiteRepairError)),
        );
        return;
      }

      final existingProfile = await _persistence.getCanonicalProfile(uid: uid);
      final existingIq = _reconciler.measuredOfModule(existingProfile, 'iq');
      final existingEq = _reconciler.measuredOfModule(existingProfile, 'eq');

      final adapted = const FrequencyTo20dRuntimeAdapter().adapt(
        result: result,
        ownerUid: uid,
        sessionId: session.sessionId,
        existingIqDimensions: existingIq,
        existingEqDimensions: existingEq,
      );
      if (!adapted.ok || adapted.fragment == null) {
        throw StateError(adapted.message ?? 'Frequency→20D adapt failed');
      }
      await _persistence.upsertCanonicalProfileFragment(adapted.fragment!);

      // Progress mark only after canonical profile upsert succeeds.
      await _progress.markAssessmentFlowCompleted();

      final finalized = await _runtime.markRemoteFinalized(
        sessionId: session.sessionId,
      );
      if (!finalized.ok || finalized.state == null) {
        throw StateError(
          finalized.message.isNotEmpty
              ? finalized.message
              : 'Frequency finalize failed',
        );
      }

      final profileCompleted = await AuthService().hasCompletedProfile();
      try {
        await ProfileService().refreshDiscoverEligibility(uid);
      } catch (_) {}

      debugPrint(
        '✅ Canonical Frequency completed — 20D ready; navigating to flow complete (no Persona)',
      );

      if (!mounted) return;
      setState(() {
        _session = finalized.state;
        _isFinishing = false;
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AssessmentFlowCompleteScreen(
            profileCompleted: profileCompleted,
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error saving canonical Frequency results: $e');
      if (mounted) {
        setState(() => _isFinishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.iqCanonicalPersistError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AssessmentCaptureGuard(
      child: _buildAssessmentBody(context),
    );
  }

  Widget _buildAssessmentBody(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading || _isFinishing) {
      return const QAssessmentScaffold(
        richBackdrop: true,
        backgroundImageAsset: 'assets/images/welcome_cosmic_background.png',
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    final session = _session;
    final bank = _bank;
    if (session == null || bank == null || _loadError != null) {
      return QAssessmentScaffold(
        richBackdrop: true,
        backgroundImageAsset: 'assets/images/welcome_cosmic_background.png',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _loadError ?? l10n.assessmentNoQuestionsAvailable,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ),
      );
    }

    final plan = session.itemPlans[session.currentQuestionIndex];
    final prompt = _runtime.promptFor(bank: bank, itemId: plan.itemId) ?? '';
    final options = _runtime.displayedOptions(bank: bank, plan: plan);
    final progress =
        (session.currentQuestionIndex + 1) / session.itemPlans.length;
    final isLast = session.currentQuestionIndex >= session.itemPlans.length - 1;
    final pendingFinalize = session.status ==
        FrequencyPersistedSessionStatus.completedPendingPersistence;
    final compact = MediaQuery.sizeOf(context).height < 700;

    return QAssessmentScaffold(
      richBackdrop: true,
      backgroundImageAsset: 'assets/images/welcome_cosmic_background.png',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final heroHeight =
              (height * (compact ? 0.14 : 0.17)).clamp(72.0, 140.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FrequencyQuestionTopBar(),
                  FrequencyProgressHeader(
                    label:
                        '${l10n.assessmentStageFrequency} • ${session.currentQuestionIndex + 1} / ${session.itemPlans.length}',
                    progress: progress,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _tendencyInstruction(l10n),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: heroHeight,
                    child: const FrequencyWaveHero(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: const Color(0xB80C0A16),
                            border: Border.all(
                              color: const Color(0x448F79B4),
                              width: 0.8,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 12 : 14,
                              vertical: compact ? 10 : 12,
                            ),
                            child: Text(
                              prompt,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: compact ? 15.5 : 16.5,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: options.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(height: compact ? 6 : 8),
                      itemBuilder: (context, index) {
                        final opt = options[index];
                        return FrequencyAnswerOptionRow(
                          value: index + 1,
                          label: opt.text,
                          selected: _selectedOptionId == opt.optionId,
                          compact: true,
                          onTap: (_isFinishing || pendingFinalize)
                              ? () {}
                              : () {
                                  _dismissSelectAnswerWarning();
                                  setState(
                                    () => _selectedOptionId = opt.optionId,
                                  );
                                },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 9),
                  FrequencyContinueButton(
                    label: pendingFinalize
                        ? l10n.iqCanonicalFinalizeRetry
                        : (isLast
                            ? l10n.assessmentFinish
                            : l10n.assessmentContinue),
                    active: pendingFinalize
                        ? !_isFinishing
                        : (_selectedOptionId != null &&
                            !_isFinishing &&
                            !_busy),
                    saving: _isFinishing || _busy,
                    onPressed: (_isFinishing || _busy) ? () {} : _onContinue,
                  ),
                ],
              ),
              if (_showSelectAnswerWarning)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: _continueButtonHeight + _warningAboveContinueGap - 50,
                  child: IgnorePointer(
                    child: FrequencySelectAnswerWarning(
                      message: l10n.iqPleaseSelectAnswerToContinue,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
