import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/eq_bank/eq_bank.dart';
import '../domain/eq_session/eq_session.dart';
import '../services/eq_canonical_runtime_service.dart';
import '../services/eq_pending_finalization_pipeline.dart';
import '../utils/assessment_language.dart';
import '../widgets/assessment_widgets.dart';
import 'frequency_intro_screen.dart';

/// Canonical 30-item EQ session — behavioral tendency, not correctness.
class EQTestScreen extends StatefulWidget {
  const EQTestScreen({
    super.key,
    this.runtime,
    this.pendingPipeline,
  });

  final EqCanonicalRuntimeService? runtime;
  final EqPendingFinalizationPipeline? pendingPipeline;

  @override
  State<EQTestScreen> createState() => _EQTestScreenState();
}

class _EQTestScreenState extends State<EQTestScreen> {
  late final EqCanonicalRuntimeService _runtime;
  late final EqPendingFinalizationPipeline _pendingPipeline;

  EqPersistedSessionState? _session;
  EqCanonicalBankDocument? _bank;
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
  static const _warningAboveContinueGap = 12.0;

  @override
  void initState() {
    super.initState();
    _runtime = widget.runtime ?? EqCanonicalRuntimeService();
    _pendingPipeline = widget.pendingPipeline ??
        EqPendingFinalizationPipeline.live(runtime: _runtime);
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
      _selectAnswerWarningTimer = null;
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
          EqPersistedSessionStatus.completedPendingPersistence;
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
      debugPrint('EQ canonical bootstrap failed: $e');
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
        EqPersistedSessionStatus.completedPendingPersistence) {
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

      if (existing == null) {
        final answered = await _runtime.answer(
          sessionId: state.sessionId,
          itemId: curPlan.itemId,
          selectedOptionId: _selectedOptionId!,
        );
        if (!answered.ok || answered.state == null) {
          debugPrint('EQ answer failed: ${answered.message}');
          if (!mounted) return;
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.iqCanonicalAnswerError)),
          );
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
      await _runPendingFinalizationPipeline(
        session: completed.state!,
        locale: locale,
        language: language,
      );
    } catch (e) {
      debugPrint('EQ continue failed: $e');
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.iqCanonicalPersistError)),
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
  void _schedulePendingPipelineOnce(EqPersistedSessionState session) {
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

  /// finalizeEq → existing client score → assessments/eq → canonical_v1 →
  /// markEqCompleted → markRemoteFinalized → Frequency intro.
  ///
  /// Scoring is never a substitute for a failed server finalize.
  Future<void> _runPendingFinalizationPipeline({
    required EqPersistedSessionState session,
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
      if (!outcome.navigateToFrequency) {
        setState(() {
          _isFinishing = false;
          _busy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.iqCanonicalPersistError),
          ),
        );
        return;
      }
      setState(() {
        _session = outcome.session;
        _isFinishing = false;
        _busy = false;
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const FrequencyIntroScreen()),
      );
    } catch (e) {
      debugPrint('❌ Error saving canonical EQ results: $e');
      if (!mounted) return;
      setState(() {
        _isFinishing = false;
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.iqCanonicalPersistError),
        ),
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
        backgroundImageAsset: 'assets/images/eq_question_cosmic_bg.png',
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
        backgroundImageAsset: 'assets/images/eq_question_cosmic_bg.png',
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
    final pendingFinalize =
        session.status == EqPersistedSessionStatus.completedPendingPersistence;

    return QAssessmentScaffold(
      richBackdrop: true,
      backgroundImageAsset: 'assets/images/eq_question_cosmic_bg.png',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final compact = h < 760;
          final heroH = (h * (compact ? 0.175 : 0.198)).clamp(110.0, 170.0);

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
                  const EqQuestionTopBar(),
                  const SizedBox(height: 2),
                  EqQuestionProgressHeader(
                    label: l10n.eqQuestionProgress(
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
                    height: heroH,
                    width: double.infinity,
                    child: const EqMindHeartFigure(),
                  ),
                  EqInsightQuestionCard(
                    insightLabel: EqInsightQuestionCard.categoryLabelFor(
                      plan.itemId,
                      l10n,
                    ),
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
                      itemBuilder: (context, index) {
                        return EqAnswerOptionRow(
                          index: index,
                          label: EqAnswerOptionRow.displayLabel(
                            options[index].text,
                          ),
                          selected:
                              _selectedOptionId == options[index].optionId,
                          compact: true,
                          onTap: (_isFinishing || pendingFinalize)
                              ? () {}
                              : () {
                                  _dismissSelectAnswerWarning();
                                  setState(() {
                                    _selectedOptionId =
                                        options[index].optionId;
                                  });
                                },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  EqContinueButton(
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
}
