import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../l10n/app_localizations.dart';
import '../models/question_model.dart';
import '../models/archetype_model.dart';
import '../services/assessment_progress_service.dart';
import '../services/assessment_set_service.dart';
import '../services/canonical_assessment_persistence.dart';
import '../services/iq_recovery.dart';
import '../services/question_service.dart';
import '../utils/assessment_language.dart';
import '../widgets/assessment_widgets.dart';
import 'frequency_intro_screen.dart';

/// EQ MCQ pilot — cosmic presentation shell.
///
/// Runtime behavior unchanged: load, select, score, advance, complete, navigate.
class EQTestScreen extends StatefulWidget {
  final int iqScore;

  const EQTestScreen({
    super.key,
    this.iqScore = 0,
  });

  @override
  State<EQTestScreen> createState() => _EQTestScreenState();
}

class _EQTestScreenState extends State<EQTestScreen> {
  final _questionService = QuestionService();
  final _persistence = CanonicalAssessmentPersistence();
  final _progress = AssessmentProgressService();
  List<QuestionModel> _questions = [];
  String _setId = '';
  String _contentVersion = 'content_legacy_2026_01';
  DateTime? _startedAt;
  int _resolvedIqScore = 0;
  int? _iqQuestionCount;
  String? _iqRecoveryStatus;
  String? _iqRecoveryReason;
  int _currentQuestionIndex = 0;
  int? _selectedAnswer;
  bool _isLoading = true;
  bool _didStartLoading = false;
  int _correctAnswers = 0;
  bool _showSelectAnswerWarning = false;
  Timer? _selectAnswerWarningTimer;

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
    _loadQuestions();
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
    } catch (e) {
      // Sessizce devam et
    }
  }

  Future<void> _enableScreenshots() async {
    try {
      await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (e) {
      // Sessizce devam et
    }
  }

  void _dismissSelectAnswerWarning() {
    _selectAnswerWarningTimer?.cancel();
    _selectAnswerWarningTimer = null;
    if (!_showSelectAnswerWarning || !mounted) return;
    setState(() {
      _showSelectAnswerWarning = false;
    });
  }

  void _showSelectAnswerWarningBanner() {
    // One banner only — repeated Continue taps refresh the timer, no stacks.
    _selectAnswerWarningTimer?.cancel();
    if (!_showSelectAnswerWarning) {
      setState(() {
        _showSelectAnswerWarning = true;
      });
    }
    _selectAnswerWarningTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _showSelectAnswerWarning = false;
      });
      _selectAnswerWarningTimer = null;
    });
  }

  Future<void> _loadQuestions() async {
    try {
      final languageCode = Localizations.maybeLocaleOf(context)?.languageCode ??
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      final loaded = await _questionService.loadEQAssessment(
        languageCode: languageCode,
      );

      // Prefer constructor score; recover from canonical IQ / assignment if needed.
      final recoveredIq = await _persistence.recoverIqResult();
      var iqScore = widget.iqScore;
      if (iqScore <= 0 && recoveredIq.rawScore != null) {
        iqScore = recoveredIq.rawScore!;
      }

      // Module-specific IQ denominator — never fabricate; null stays unknown.
      final iqQuestionCount =
          recoveredIq.hasQuestionCount ? recoveredIq.questionCount : null;

      if (!mounted) return;
      setState(() {
        _questions = loaded.questions;
        _setId = loaded.set.id;
        _contentVersion = loaded.set.version.isNotEmpty
            ? loaded.set.version
            : 'content_legacy_2026_01';
        _startedAt = DateTime.now();
        _resolvedIqScore = iqScore;
        _iqQuestionCount = iqQuestionCount;
        _iqRecoveryStatus = recoveredIq.status;
        _iqRecoveryReason = recoveredIq.reasonCode;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('EQ questions load failed: $e');
      if (!mounted) return;
      setState(() {
        _questions = [];
        _isLoading = false;
      });
    }
  }

  void _nextQuestion() {
    if (_selectedAnswer == null) {
      _showSelectAnswerWarningBanner();
      return;
    }

    _dismissSelectAnswerWarning();

    if (_selectedAnswer == _questions[_currentQuestionIndex].correctAnswer) {
      _correctAnswers++;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
      });
    } else {
      _showResults();
    }
  }

  void _showResults() async {
    // P1B-2A: EQ completion persists results and continues to Frequency.
    // Do not run ArchetypeCalculator / write archetype / show persona reward.
    final eqNormalized = ArchetypeCalculator.normalizeScore(
      _correctAnswers,
      _questions.length,
    );

    try {
      final languageCode = Localizations.maybeLocaleOf(context)?.languageCode ??
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      final language = AssessmentLanguage.languageUsed(
        languageCode: languageCode,
      );
      final locale = AssessmentLanguage.localeUsed(
        locale: Locale(language),
      );

      await AssessmentSetService().markAssignmentCompleted(
        type: 'eq',
        score: _correctAnswers,
        languageCode: languageCode,
      );
      await _persistence.upsertCompletedAssessment(
        assessmentType: 'eq',
        fields: _persistence.buildLegacyIqEqPayload(
          assessmentType: 'eq',
          setId: _setId,
          contentVersion: _contentVersion,
          locale: locale,
          languageUsed: language,
          questionCount: _questions.length,
          answeredCount: _questions.length,
          rawScore: _correctAnswers,
          missingDimensions: CanonicalDimensions.eq,
          assignmentType: 'eq',
          legacyScoringMode: 'correct_answer_total',
          startedAt: _startedAt,
        ),
      );
      await _progress.markEqCompleted(
        eqScore: _correctAnswers,
        eqNormalized: eqNormalized,
        iqScore: _resolvedIqScore > 0 ? _resolvedIqScore : null,
      );

      if (_iqQuestionCount == null || _iqQuestionCount! <= 0) {
        debugPrint(
          'IQ recovery ${_iqRecoveryStatus ?? IqRecoveryResult.statusInsufficientMetadata}'
          ' reason=${_iqRecoveryReason ?? IqRecoveryResult.reasonMissingIqQuestionCount}'
          ' — EQ saved without persona rewrite',
        );
      }

      debugPrint('✅ EQ completed (flow v2) — navigating to Frequency');
    } catch (e) {
      debugPrint('❌ Error saving EQ results: $e');
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const FrequencyIntroScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const QAssessmentScaffold(
        richBackdrop: true,
        backgroundImageAsset: 'assets/images/eq_question_cosmic_bg.png',
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.vizEq),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return QAssessmentScaffold(
        richBackdrop: true,
        backgroundImageAsset: 'assets/images/eq_question_cosmic_bg.png',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.assessmentNoQuestionsAvailable,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    final isLast = _currentQuestionIndex >= _questions.length - 1;

    return QAssessmentScaffold(
      richBackdrop: true,
      backgroundImageAsset: 'assets/images/eq_question_cosmic_bg.png',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final compact = h < 760;
          final heroH = (h * (compact ? 0.205 : 0.228)).clamp(126.0, 192.0);

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
                  EqQuestionTopBar(
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: 2),
                  EqQuestionProgressHeader(
                    label: l10n.eqQuestionProgress(
                      _currentQuestionIndex + 1,
                      _questions.length,
                    ),
                    progress: progress,
                  ),
                  SizedBox(
                    height: heroH,
                    width: double.infinity,
                    child: const EqMindHeartFigure(),
                  ),
                  EqInsightQuestionCard(
                    insightLabel: EqInsightQuestionCard.categoryLabelFor(
                      currentQuestion.id,
                      l10n,
                    ),
                    text: currentQuestion.question,
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 6.0 : 8.0),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (var index = 0;
                            index < currentQuestion.options.length;
                            index++)
                          EqAnswerOptionRow(
                            index: index,
                            label: EqAnswerOptionRow.displayLabel(
                              currentQuestion.options[index],
                            ),
                            selected: _selectedAnswer == index,
                            compact: true,
                            onTap: () {
                              _dismissSelectAnswerWarning();
                              setState(() {
                                _selectedAnswer = index;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  EqContinueButton(
                    label: isLast
                        ? l10n.assessmentFinish
                        : l10n.assessmentContinue,
                    active: _selectedAnswer != null,
                    onPressed: _nextQuestion,
                  ),
                ],
              ),
              // Floating validation — overlays only; does not shift Column layout.
              if (_showSelectAnswerWarning)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: _continueButtonHeight + _warningAboveContinueGap,
                  child: IgnorePointer(
                    child: _EqSelectAnswerWarningBanner(
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

/// Compact secondary validation chip — same chrome as IQ.
class _EqSelectAnswerWarningBanner extends StatelessWidget {
  const _EqSelectAnswerWarningBanner({required this.message});

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
