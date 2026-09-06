import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/widgets/qmatch_feedback.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/frequency_bank/frequency_bank.dart';
import '../domain/frequency_session/frequency_session.dart';
import '../services/frequency_canonical_runtime_service.dart';
import '../services/frequency_pending_finalization_pipeline.dart';
import '../utils/assessment_language.dart';
import '../widgets/assessment_capture_guard.dart';
import '../widgets/frequency_question_chrome.dart';
import '../widgets/q_assessment_scaffold.dart';
import 'persona_assignment_gate_screen.dart';

/// Canonical 50-item Frequency session — behavioral tendency, not correctness.
///
/// Completes the 20D measurement profile. Persona assign/reveal is the next
/// live step (distance-only). Does NOT invoke Matching / QRCF / quantum / RVI.
class FrequencyTestScreen extends StatefulWidget {
  const FrequencyTestScreen({
    super.key,
    this.runtime,
    this.pendingPipeline,
  });

  final FrequencyCanonicalRuntimeService? runtime;
  final FrequencyPendingFinalizationPipeline? pendingPipeline;

  @override
  State<FrequencyTestScreen> createState() => _FrequencyTestScreenState();
}

class _FrequencyTestScreenState extends State<FrequencyTestScreen> {
  late final FrequencyCanonicalRuntimeService _runtime;
  late final FrequencyPendingFinalizationPipeline _pendingPipeline;

  FrequencyPersistedSessionState? _session;
  FrequencyCanonicalBankDocument? _bank;
  String? _selectedOptionId;
  bool _isLoading = true;
  bool _didStartLoading = false;
  bool _didAutoRetryPending = false;
  bool _pipelineInFlight = false;
  bool _isFinishing = false;
  bool _busy = false;
  String? _loadError;
  DateTime? _startedAt;
  bool _showSelectAnswerWarning = false;
  Timer? _selectAnswerWarningTimer;

  static const _continueButtonHeight = 54.0;
  static const _warningAboveContinueGap = 62.0;

  @override
  void initState() {
    super.initState();
    _runtime = widget.runtime ?? FrequencyCanonicalRuntimeService();
    _pendingPipeline = widget.pendingPipeline ??
        FrequencyPendingFinalizationPipeline.live(runtime: _runtime);
  }

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
      final pending = session.status ==
          FrequencyPersistedSessionStatus.completedPendingPersistence;
      if (!mounted) return;
      setState(() {
        _session = session;
        _bank = bank;
        _selectedOptionId = existing?.selectedOptionId;
        _startedAt = DateTime.tryParse(session.startedAt) ?? DateTime.now();
        _isLoading = false;
        if (pending) {
          _busy = true;
          _isFinishing = true;
        }
      });
      if (pending) {
        _schedulePendingPipelineOnce(session);
      }
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
    if (session == null ||
        bank == null ||
        _isFinishing ||
        _busy ||
        _pipelineInFlight) {
      return;
    }

    final languageCode = Localizations.maybeLocaleOf(context)?.languageCode ??
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final language = AssessmentLanguage.languageUsed(
      languageCode: languageCode,
    );
    final locale = AssessmentLanguage.localeUsed(locale: Locale(language));

    if (session.status ==
        FrequencyPersistedSessionStatus.completedPendingPersistence) {
      setState(() {
        _busy = true;
        _isFinishing = true;
      });
      await _runPendingFinalizationPipeline(
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
          QMatchFeedback.show(
            context,
            message: l10n.iqCanonicalAnswerError,
            type: QMatchFeedbackType.error,
            compact: true,
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
            QMatchFeedback.show(
              context,
              message: l10n.iqCanonicalAnswerError,
              type: QMatchFeedbackType.error,
              compact: true,
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
      await _runPendingFinalizationPipeline(
        session: completed.state!,
        locale: locale,
        language: language,
      );
    } catch (e) {
      debugPrint('Frequency continue failed: $e');
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      QMatchFeedback.show(
        context,
        message: l10n.iqCanonicalPersistError,
        type: QMatchFeedbackType.error,
        compact: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          if (!_pipelineInFlight) _isFinishing = false;
        });
      }
    }
  }

  ({String locale, String language}) _assessmentLocaleLanguage() {
    final languageCode = Localizations.maybeLocaleOf(context)?.languageCode ??
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final language = AssessmentLanguage.languageUsed(
      languageCode: languageCode,
    );
    final locale = AssessmentLanguage.localeUsed(locale: Locale(language));
    return (locale: locale, language: language);
  }

  /// One automatic pending retry per screen lifecycle (bootstrap only).
  void _schedulePendingPipelineOnce(FrequencyPersistedSessionState session) {
    if (_didAutoRetryPending) return;
    _didAutoRetryPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_session?.sessionId != session.sessionId) return;
      final loc = _assessmentLocaleLanguage();
      unawaited(
        _runPendingFinalizationPipeline(
          session: session,
          locale: loc.locale,
          language: loc.language,
        ),
      );
    });
  }

  /// finalizeFrequency → existing client score → assessments/frequency →
  /// canonical_v1 → markRemoteFinalized → Persona assignment gate.
  ///
  /// Scoring is never a substitute for a failed server finalize.
  Future<void> _runPendingFinalizationPipeline({
    required FrequencyPersistedSessionState session,
    required String locale,
    required String language,
  }) async {
    if (_pipelineInFlight) return;
    _pipelineInFlight = true;
    setState(() {
      _isFinishing = true;
      _busy = true;
    });
    try {
      final outcome = await _pendingPipeline.run(
        session: session,
        locale: locale,
        language: language,
        startedAt: _startedAt,
      );
      if (!mounted) return;
      if (!outcome.navigateToPersona) {
        setState(() {
          _isFinishing = false;
          _busy = false;
        });
        QMatchFeedback.show(
          context,
          message: AppLocalizations.of(context)!.iqCanonicalPersistError,
          type: QMatchFeedbackType.error,
          compact: true,
        );
        return;
      }

      final profileCompleted = await AuthService().hasCompletedProfile();
      // discover_eligible is recomputed by trusted Cloud Function on the
      // assessment completion write — no client self-grant.

      debugPrint(
        '✅ Canonical Frequency completed — 20D ready; navigating to Persona gate',
      );

      if (!mounted) return;
      setState(() {
        _session = outcome.session;
        _isFinishing = false;
        _busy = false;
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PersonaAssignmentGateScreen(
            profileCompleted: profileCompleted,
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error saving canonical Frequency results: $e');
      if (!mounted) return;
      setState(() {
        _isFinishing = false;
        _busy = false;
      });
      QMatchFeedback.show(
        context,
        message: AppLocalizations.of(context)!.iqCanonicalPersistError,
        type: QMatchFeedbackType.error,
        compact: true,
      );
    } finally {
      _pipelineInFlight = false;
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
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDAC8ED)),
            strokeWidth: 2.6,
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

    return QAssessmentScaffold(
      richBackdrop: true,
      backgroundImageAsset: 'assets/images/welcome_cosmic_background.png',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final compact = height < 700;
          // Roomier wave slot so the static resonance art fills more of the row.
          final heroHeight =
              (height * (compact ? 0.14 : 0.16)).clamp(78.0, 148.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FrequencyQuestionTopBar(),
                  const SizedBox(height: 2),
                  FrequencyProgressHeader(
                    label: l10n.frequencyQuestionProgress(
                      session.currentQuestionIndex + 1,
                      session.itemPlans.length,
                    ),
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
                  // Wave stays fixed above; keep Q+options centered in the
                  // remaining space (not glued to Devam), with a light upward
                  // bias so the gap under the wave is not oversized.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, bodyConstraints) {
                        return SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: bodyConstraints.maxHeight,
                            ),
                            child: Padding(
                              // Subtle upward shift of the centered cluster —
                              // does not change wave height or CTA slot.
                              padding: EdgeInsets.only(
                                bottom: compact ? 10 : 16,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 10,
                                          sigmaY: 10,
                                        ),
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0x8A17142D),
                                                Color(0x72101227),
                                              ],
                                            ),
                                            border: Border.all(
                                              color: const Color(0x554F4D79),
                                              width: 0.9,
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
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Column(
                                      children: [
                                        for (var index = 0;
                                            index < options.length;
                                            index++) ...[
                                          if (index > 0)
                                            SizedBox(height: compact ? 6 : 8),
                                          FrequencyAnswerOptionRow(
                                            value: index + 1,
                                            label: options[index].text,
                                            selected: _selectedOptionId ==
                                                options[index].optionId,
                                            compact: compact,
                                            onTap: (_isFinishing ||
                                                    pendingFinalize ||
                                                    _pipelineInFlight)
                                                ? () {}
                                                : () {
                                                    _dismissSelectAnswerWarning();
                                                    setState(
                                                      () => _selectedOptionId =
                                                          options[index]
                                                              .optionId,
                                                    );
                                                  },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                        ? !_isFinishing && !_pipelineInFlight
                        : (_selectedOptionId != null &&
                            !_isFinishing &&
                            !_busy &&
                            !_pipelineInFlight),
                    saving: _isFinishing || _busy || _pipelineInFlight,
                    onPressed: (_isFinishing || _busy || _pipelineInFlight)
                        ? () {}
                        : _onContinue,
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
