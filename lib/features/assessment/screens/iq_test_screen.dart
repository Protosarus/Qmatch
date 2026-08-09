import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/iq_bank/iq_bank.dart';
import '../domain/iq_scoring/iq_scoring.dart';
import '../domain/iq_session/iq_session.dart';
import '../services/assessment_progress_service.dart';
import '../services/canonical_assessment_persistence.dart';
import '../services/iq_canonical_runtime_service.dart';
import '../utils/assessment_language.dart';
import '../widgets/assessment_widgets.dart';
import 'eq_test_intro_screen.dart';
import 'iq_reasoning_profile_screen.dart';

/// Live IQ assessment — canonical 25-question session (P2C-2A-5).
///
/// Legacy 10-item assigned-set path is no longer used for new sessions.
class IQTestScreen extends StatefulWidget {
  const IQTestScreen({super.key});

  @override
  State<IQTestScreen> createState() => _IQTestScreenState();
}

class _IQTestScreenState extends State<IQTestScreen> {
  final _runtime = IqCanonicalRuntimeService();
  final _persistence = CanonicalAssessmentPersistence();
  final _progress = AssessmentProgressService();

  IqRecoveredBankDocument? _bank;
  IqPersistedSessionState? _session;
  String? _loadErrorCode;
  bool _isLoading = true;
  bool _didStartLoading = false;
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
    _disableScreenshots();
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
    _enableScreenshots();
    super.dispose();
  }

  Future<void> _disableScreenshots() async {
    try {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (_) {}
  }

  Future<void> _enableScreenshots() async {
    try {
      await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (_) {}
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
      final bank = await _runtime.loadBank();
      final created = await _runtime.getOrCreateActiveSession();
      if (!mounted) return;
      if (!created.ok || created.state == null) {
        setState(() {
          _bank = bank;
          _loadErrorCode = created.code ?? 'session_unavailable';
          _isLoading = false;
        });
        return;
      }
      final session = created.state!;
      final idx = session.currentQuestionIndex;
      final plan = session.itemPlans[idx];
      final existing = session.answersByItemId[plan.itemId];
      setState(() {
        _bank = bank;
        _session = session;
        _selectedOptionId = existing?.selectedOptionId;
        _startedAt = DateTime.tryParse(session.startedAt) ?? DateTime.now();
        _isLoading = false;
      });
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

    if (_selectedOptionId == null) {
      _showSelectAnswerWarningBanner();
      return;
    }
    _dismissSelectAnswerWarning();

    final languageCode = Localizations.maybeLocaleOf(context)?.languageCode ??
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final language = AssessmentLanguage.languageUsed(
      languageCode: languageCode,
    );
    final locale = AssessmentLanguage.localeUsed(locale: Locale(language));

    final idx = session.currentQuestionIndex;
    final plan = session.itemPlans[idx];
    final isLast = idx >= session.itemPlans.length - 1;

    setState(() => _busy = true);
    try {
      final answered = await _runtime.answer(
        sessionId: session.sessionId,
        itemId: plan.itemId,
        selectedOptionId: _selectedOptionId!,
      );
      if (!answered.ok || answered.state == null) {
        if (!mounted) return;
        _showErrorSnack(answered.code ?? 'answer_failed');
        setState(() => _busy = false);
        return;
      }

      if (!isLast) {
        final moved = await _runtime.moveToIndex(
          sessionId: session.sessionId,
          index: idx + 1,
        );
        if (!moved.ok || moved.state == null) {
          if (!mounted) return;
          _showErrorSnack(moved.code ?? 'index_failed');
          setState(() {
            _session = answered.state;
            _busy = false;
          });
          return;
        }
        final next = moved.state!;
        final nextPlan = next.itemPlans[next.currentQuestionIndex];
        final existing = next.answersByItemId[nextPlan.itemId];
        if (!mounted) return;
        setState(() {
          _session = next;
          _selectedOptionId = existing?.selectedOptionId;
          _busy = false;
        });
        return;
      }

      // Complete → score → persist → reasoning profile → EQ.
      final completed = await _runtime.completeSession(
        sessionId: session.sessionId,
      );
      if (!completed.ok || completed.state == null) {
        if (!mounted) return;
        _showErrorSnack(completed.code ?? 'complete_failed');
        setState(() {
          _session = answered.state;
          _busy = false;
        });
        return;
      }

      final scored = await _runtime.scoreCompleted(completed.state!);
      if (!scored.ok || scored.result == null) {
        if (!mounted) return;
        _showErrorSnack(scored.code?.name ?? 'score_failed');
        setState(() => _busy = false);
        return;
      }

      try {
        await _persistence.upsertCompletedAssessment(
          assessmentType: 'iq',
          fields: _persistence.buildCanonicalIq4dPayload(
            result: scored.result!,
            locale: locale,
            languageUsed: language,
            startedAt: _startedAt,
          ),
        );
        // Do not write legacy scalar iq_score (not a standardized IQ).
        await _progress.markIqCompleted(rawScore: null);
      } catch (e) {
        debugPrint('Canonical IQ result persistence failed: $e');
        if (!mounted) return;
        _showErrorSnack('persist_failed');
        setState(() => _busy = false);
        return;
      }

      if (!mounted) return;
      setState(() => _busy = false);
      _openReasoningProfile(scored.result!);
    } catch (e) {
      debugPrint('Canonical IQ continue failed: $e');
      if (!mounted) return;
      _showErrorSnack('unexpected_error');
      setState(() => _busy = false);
    }
  }

  void _openReasoningProfile(IqCanonicalScoringResult result) {
    final nav = Navigator.of(context);
    nav.pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => IqReasoningProfileScreen(
          result: result,
          onContinue: () {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder<void>(
                opaque: true,
                barrierDismissible: false,
                transitionDuration: const Duration(milliseconds: 280),
                reverseTransitionDuration: const Duration(milliseconds: 220),
                pageBuilder: (context, animation, secondaryAnimation) {
                  return IqToEqTransitionScreen(
                    onStartEq: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          // Legacy ctor retained; score unused for calibration.
                          builder: (context) => const EQTestIntroScreen(
                            iqScore: 0,
                          ),
                        ),
                      );
                    },
                  );
                },
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                    child: child,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _showErrorSnack(String code) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.iqCanonicalSessionError)),
    );
    debugPrint('IQ canonical error code=$code');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const QAssessmentScaffold(
        richBackdrop: true,
        backgroundImageAsset: 'assets/images/welcome_cosmic_background.png',
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.vizIq),
          ),
        ),
      );
    }

    if (_loadErrorCode != null || _session == null || _bank == null) {
      return QAssessmentScaffold(
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
    }

    final session = _session!;
    final bank = _bank!;
    final idx = session.currentQuestionIndex;
    final plan = session.itemPlans[idx];
    final prompt = _runtime.promptFor(bank: bank, itemId: plan.itemId) ?? '';
    final options = _runtime.displayedOptions(bank: bank, plan: plan);
    final progress = (idx + 1) / session.itemPlans.length;
    final isLast = idx >= session.itemPlans.length - 1;

    return QAssessmentScaffold(
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
                  IqQuestionTopBar(
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (var i = 0; i < options.length; i++)
                          IqAnswerOptionRow(
                            index: i,
                            label: options[i].text,
                            selected: _selectedOptionId == options[i].optionId,
                            compact: true,
                            onTap: _busy
                                ? () {}
                                : () {
                                    _dismissSelectAnswerWarning();
                                    setState(() {
                                      _selectedOptionId = options[i].optionId;
                                    });
                                  },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  IqContinueButton(
                    label: isLast
                        ? l10n.assessmentFinish
                        : l10n.assessmentContinue,
                    active: _selectedOptionId != null && !_busy,
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
                    child: _IqSelectAnswerWarningBanner(
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

class _IqSelectAnswerWarningBanner extends StatelessWidget {
  const _IqSelectAnswerWarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.pillBorder,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: AppRadii.pillBorder,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.resonanceViolet.withValues(alpha: 0.55),
                const Color(0xCC1A2240),
                AppColors.softGold.withValues(alpha: 0.28),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
            border: Border.all(
              color: AppColors.resonanceViolet.withValues(alpha: 0.72),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.resonanceViolet.withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: AppColors.softGold.withValues(alpha: 0.98),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.98),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
