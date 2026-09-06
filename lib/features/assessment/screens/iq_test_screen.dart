import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/qmatch_feedback.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/iq_bank/iq_bank.dart';
import '../domain/iq_session/iq_session.dart';
import '../services/iq_canonical_runtime_service.dart';
import '../services/iq_pending_finalization_pipeline.dart';
import '../utils/assessment_language.dart';
import '../widgets/assessment_widgets.dart';
import 'eq_test_intro_screen.dart';

/// Live IQ assessment — canonical 25-question session (P2C-2A-5).
///
/// Legacy 10-item assigned-set path is no longer used for new sessions.
class IQTestScreen extends StatefulWidget {
  const IQTestScreen({
    super.key,
    this.runtime,
    this.pendingPipeline,
  });

  final IqCanonicalRuntimeService? runtime;
  final IqPendingFinalizationPipeline? pendingPipeline;

  @override
  State<IQTestScreen> createState() => _IQTestScreenState();
}

class _IQTestScreenState extends State<IQTestScreen> {
  late final IqCanonicalRuntimeService _runtime;
  late final IqPendingFinalizationPipeline _pendingPipeline;

  IqRecoveredBankDocument? _bank;
  IqPersistedSessionState? _session;
  String? _loadErrorCode;
  bool _isLoading = true;
  bool _didStartLoading = false;
  bool _didAutoRetryPending = false;
  bool _pipelineInFlight = false;
  bool _busy = false;
  String? _selectedOptionId;
  bool _showSelectAnswerWarning = false;
  Timer? _selectAnswerWarningTimer;
  DateTime? _startedAt;

  static const _continueButtonHeight = 54.0;
  static const _warningAboveContinueGap = 12.0;

  @override
  void initState() {
    super.initState();
    _runtime = widget.runtime ?? IqCanonicalRuntimeService();
    _pendingPipeline = widget.pendingPipeline ??
        IqPendingFinalizationPipeline.live(runtime: _runtime);
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
      setState(() {
        _showSelectAnswerWarning = false;
        _selectAnswerWarningTimer = null;
      });
    });
  }

  Future<void> _bootstrap() async {
    try {
      final languageCode = Localizations.maybeLocaleOf(context)?.languageCode ??
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      final created = await _runtime.getOrCreateActiveSession(
        preferredLanguageCode: languageCode,
      );
      if (!mounted) return;
      if (!created.ok || created.state == null) {
        setState(() {
          _bank = _runtime.activeBank;
          _loadErrorCode = created.code ?? 'session_unavailable';
          _isLoading = false;
        });
        return;
      }
      final session = created.state!;
      final bank = _runtime.activeBank ??
          await _runtime.loadBankForLocale(session.bankLocale);
      final idx = session.currentQuestionIndex;
      final plan = session.itemPlans[idx];
      final existing = session.answersByItemId[plan.itemId];
      final pending = session.status ==
          IqPersistedSessionStatus.completedPendingPersistence;
      setState(() {
        _bank = bank;
        _session = session;
        _selectedOptionId = existing?.selectedOptionId;
        _startedAt = DateTime.tryParse(session.startedAt) ?? DateTime.now();
        _isLoading = false;
        if (pending) _busy = true;
      });
      if (pending) {
        _schedulePendingPipelineOnce(session);
      }
    } catch (e) {
      debugPrint('Canonical IQ bootstrap failed: $e');
      if (!mounted) return;
      setState(() {
        _loadErrorCode = 'bootstrap_failed';
        _isLoading = false;
      });
    }
  }

  Future<void> _onContinue() async {
    if (_busy) return;
    final session = _session;
    final bank = _bank;
    if (session == null || bank == null) return;

    final languageCode = Localizations.maybeLocaleOf(context)?.languageCode ??
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final language = AssessmentLanguage.languageUsed(
      languageCode: languageCode,
    );
    final locale = AssessmentLanguage.localeUsed(locale: Locale(language));

    if (session.status ==
        IqPersistedSessionStatus.completedPendingPersistence) {
      setState(() => _busy = true);
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

      if (existing == null) {
        final answered = await _runtime.answer(
          sessionId: state.sessionId,
          itemId: curPlan.itemId,
          selectedOptionId: _selectedOptionId!,
        );
        if (!answered.ok || answered.state == null) {
          if (!mounted) return;
          _showErrorSnack(answered.code ?? 'answer_failed');
          return;
        }
        state = answered.state!;
      }

      final unanswered = state.firstUnansweredIndex;
      final isComplete = unanswered >= state.itemPlans.length;
      if (!isComplete) {
        final moved = await _runtime.moveToIndex(
          sessionId: state.sessionId,
          index: unanswered,
        );
        var nextState = moved.state;
        if (!moved.ok || nextState == null) {
          final reconciled = await _runtime.reconcileCursor(
            sessionId: state.sessionId,
          );
          if (!reconciled.ok || reconciled.state == null) {
            if (!mounted) return;
            _showErrorSnack(reconciled.code ?? 'index_failed');
            return;
          }
          nextState = reconciled.state;
        }
        if (!mounted) return;
        final next = nextState!;
        final nextPlan = next.itemPlans[next.currentQuestionIndex];
        final existingNext = next.answersByItemId[nextPlan.itemId];
        setState(() {
          _session = next;
          _selectedOptionId = existingNext?.selectedOptionId;
        });
        return;
      }

      final completed = await _runtime.completeSession(
        sessionId: state.sessionId,
      );
      if (!completed.ok || completed.state == null) {
        if (!mounted) return;
        _showErrorSnack(completed.code ?? 'complete_failed');
        return;
      }
      if (!mounted) return;
      setState(() => _session = completed.state);
      await _runPendingFinalizationPipeline(
        session: completed.state!,
        locale: locale,
        language: language,
      );
    } catch (e) {
      debugPrint('Canonical IQ continue failed: $e');
      if (!mounted) return;
      _showErrorSnack('unexpected_error');
    } finally {
      if (mounted) setState(() => _busy = false);
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
  void _schedulePendingPipelineOnce(IqPersistedSessionState session) {
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

  /// finalizeIq → score → persist → markIqCompleted → markRemoteFinalized → EQ.
  /// Safe to retry; does not call [answer]; never clears pending on failure.
  Future<void> _runPendingFinalizationPipeline({
    required IqPersistedSessionState session,
    required String locale,
    required String language,
  }) async {
    if (_pipelineInFlight) return;
    _pipelineInFlight = true;
    try {
      final outcome = await _pendingPipeline.run(
        session: session,
        locale: locale,
        language: language,
        startedAt: _startedAt,
      );
      if (!mounted) return;
      if (!outcome.navigateToEq) {
        _showErrorSnack(outcome.uiErrorCode ?? 'persist_failed');
        setState(() => _busy = false);
        return;
      }
      setState(() {
        _session = outcome.session;
        _busy = false;
      });
      _openEqIntro();
    } catch (e) {
      debugPrint('Canonical IQ finalize failed: $e');
      if (!mounted) return;
      _showErrorSnack('unexpected_error');
      setState(() => _busy = false);
    } finally {
      _pipelineInFlight = false;
    }
  }

  /// Onboarding: IQ finalize → EQ Intro (no intermediate reasoning profile).
  void _openEqIntro() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => const EQTestIntroScreen(),
      ),
    );
  }

  void _showErrorSnack(String code) {
    final l10n = AppLocalizations.of(context)!;
    final message = switch (code) {
      'persist_failed' ||
      'finalize_failed' ||
      'score_failed' ||
      'ownerUnavailable' ||
      'sessionIncomplete' ||
      'sessionNotCompleted' ||
      'resultInvalid' =>
        l10n.iqCanonicalPersistError,
      'answer_failed' ||
      'invalid_option' ||
      'invalid_item' ||
      'index_failed' ||
      'incomplete_answers' ||
      'complete_failed' ||
      'session_not_editable' =>
        l10n.iqCanonicalAnswerError,
      _ => l10n.iqCanonicalSessionError,
    };
    QMatchFeedback.show(
      context,
      message: message,
      type: QMatchFeedbackType.error,
      compact: true,
    );
    debugPrint('IQ canonical error code=$code');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    late final Widget body;
    if (_isLoading) {
      body = const QAssessmentScaffold(
        richBackdrop: true,
        backgroundImageAsset: 'assets/images/welcome_cosmic_background.png',
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDAC8ED)),
            strokeWidth: 2.6,
          ),
        ),
      );
    } else if (_loadErrorCode != null || _session == null || _bank == null) {
      body = QAssessmentScaffold(
        richBackdrop: true,
        backgroundImageAsset: 'assets/images/welcome_cosmic_background.png',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.iqCanonicalSessionError,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _loadErrorCode = null;
                    });
                    _bootstrap();
                  },
                  child: Text(l10n.assessmentStart),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      final session = _session!;
      final bank = _bank!;
      final idx = session.currentQuestionIndex;
      final plan = session.itemPlans[idx];
      final prompt = _runtime.promptFor(bank: bank, itemId: plan.itemId) ?? '';
      final options = _runtime.displayedOptions(bank: bank, plan: plan);
      final progress = (idx + 1) / session.itemPlans.length;
      final isLast = idx >= session.itemPlans.length - 1;
      final pendingFinalize = session.status ==
          IqPersistedSessionStatus.completedPendingPersistence;
      final continueLabel = pendingFinalize
          ? l10n.iqCanonicalFinalizeRetry
          : (isLast ? l10n.assessmentFinish : l10n.assessmentContinue);
      final continueActive =
          pendingFinalize ? !_busy : (_selectedOptionId != null && !_busy);

      body = QAssessmentScaffold(
        richBackdrop: true,
        backgroundImageAsset: 'assets/images/welcome_cosmic_background.png',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final compact = h < 760;
            final heroH = (h * (compact ? 0.18 : 0.20)).clamp(110.0, 168.0);

            return Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: 0.58,
                      widthFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              const Color(0x33060A14),
                              const Color(0x77050A12),
                              const Color(0x99040A10),
                            ],
                            stops: const [0.0, 0.28, 0.62, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const IqQuestionTopBar(),
                    const SizedBox(height: 2),
                    IqQuestionProgressHeader(
                      label: l10n.iqQuestionProgress(
                        idx + 1,
                        session.itemPlans.length,
                      ),
                      progress: progress,
                    ),
                    SizedBox(
                      height: heroH,
                      width: double.infinity,
                      child: const IqQuestionBreathingHero(),
                    ),
                    IqInsightQuestionCard(
                      text: prompt,
                      compact: compact,
                    ),
                    SizedBox(height: compact ? 6.0 : 8.0),
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        physics: const ClampingScrollPhysics(),
                        itemCount: options.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: compact ? 6.0 : 8.0),
                        itemBuilder: (context, i) {
                          return IqAnswerOptionRow(
                            index: i,
                            label: options[i].text,
                            selected: _selectedOptionId == options[i].optionId,
                            compact: true,
                            onTap: (_busy || pendingFinalize)
                                ? () {}
                                : () {
                                    _dismissSelectAnswerWarning();
                                    setState(() {
                                      _selectedOptionId = options[i].optionId;
                                    });
                                  },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    IqContinueButton(
                      label: continueLabel,
                      active: continueActive,
                      onPressed: _busy ? () {} : _onContinue,
                    ),
                  ],
                ),
                if (_showSelectAnswerWarning)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: _continueButtonHeight + _warningAboveContinueGap,
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

    return AssessmentCaptureGuard(child: body);
  }
}
