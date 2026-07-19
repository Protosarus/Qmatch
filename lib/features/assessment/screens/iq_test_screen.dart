import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/elegant_warning.dart';
import '../../../l10n/app_localizations.dart';
import '../models/question_model.dart';
import '../services/assessment_set_service.dart';
import '../services/question_service.dart';
import '../widgets/assessment_widgets.dart';
import 'eq_test_screen.dart';

class IQTestScreen extends StatefulWidget {
  const IQTestScreen({super.key});

  @override
  State<IQTestScreen> createState() => _IQTestScreenState();
}

class _IQTestScreenState extends State<IQTestScreen> {
  final _questionService = QuestionService();
  List<QuestionModel> _questions = [];
  int _currentQuestionIndex = 0;
  int? _selectedAnswer;
  bool _isLoading = true;
  bool _didStartLoading = false;
  int _correctAnswers = 0;

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

  Future<void> _loadQuestions() async {
    try {
      final languageCode =
          Localizations.maybeLocaleOf(context)?.languageCode ??
              WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      final questions = await _questionService.getRandomIQQuestions(
        count: 10,
        languageCode: languageCode,
      );
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('IQ questions load failed: $e');
      if (!mounted) return;
      setState(() {
        _questions = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _nextQuestion() async {
    if (_selectedAnswer == null) {
      final l10n = AppLocalizations.of(context)!;
      showElegantWarning(context, l10n.assessmentPleaseSelectAnswer);
      return;
    }

    if (_selectedAnswer == _questions[_currentQuestionIndex].correctAnswer) {
      _correctAnswers++;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
      });
    } else {
      try {
        final languageCode =
            Localizations.maybeLocaleOf(context)?.languageCode ??
                WidgetsBinding.instance.platformDispatcher.locale.languageCode;
        await AssessmentSetService().markAssignmentCompleted(
          type: 'iq',
          score: _correctAnswers,
          languageCode: languageCode,
        );
      } catch (e) {
        debugPrint('IQ assignment completion: $e');
      }
      if (!mounted) return;
      _showTransitionDialog();
    }
  }

  void _showTransitionDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.background,
                AppColors.background.withValues(alpha: 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Text(
                  '🧠',
                  style: TextStyle(fontSize: 64),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.iqTestCompleted,
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.iqToEqMessage,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) =>
                            EQTestScreen(iqScore: _correctAnswers),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: AppColors.primary.withValues(alpha: 0.5),
                  ),
                  child: Text(
                    l10n.startEqTest.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const QAssessmentScaffold(
        richBackdrop: true,
        backgroundImageAsset: 'assets/images/iq_question_cosmic_bg.png',
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.vizIq),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return QAssessmentScaffold(
        richBackdrop: true,
        backgroundImageAsset: 'assets/images/iq_question_cosmic_bg.png',
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
      backgroundImageAsset: 'assets/images/iq_question_cosmic_bg.png',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final compact = h < 760;
          final heroH = (h * (compact ? 0.18 : 0.20)).clamp(110.0, 168.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Soft dark wash behind question + options for readability.
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
                      _currentQuestionIndex + 1,
                      _questions.length,
                    ),
                    progress: progress,
                  ),
                  SizedBox(
                    height: heroH,
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/iq_question_neural_hero.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                    ),
                  ),
                  IqInsightQuestionCard(
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
                          IqAnswerOptionRow(
                            index: index,
                            label: currentQuestion.options[index],
                            selected: _selectedAnswer == index,
                            compact: true,
                            onTap: () {
                              setState(() {
                                _selectedAnswer = index;
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
                    active: _selectedAnswer != null,
                    onPressed: _nextQuestion,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
