import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/elegant_warning.dart';
import '../../../l10n/app_localizations.dart';
import '../models/question_model.dart';
import '../models/archetype_model.dart';
import '../services/assessment_set_service.dart';
import '../services/question_service.dart';
import '../utils/assessment_language.dart';
import '../utils/assessment_result_display_resolver.dart';
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
  final _authService = AuthService();
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
      final questions = await _questionService.getRandomEQQuestions(
        count: 10,
        languageCode: languageCode,
      );
      if (!mounted) return;
      setState(() {
        _questions = questions;
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
      _showResults();
    }
  }

  void _showResults() async {
    final archetype = ArchetypeCalculator.calculateArchetype(
      iqScore: widget.iqScore,
      eqScore: _correctAnswers,
      totalQuestions: _questions.length,
    );

    try {
      final languageCode =
          Localizations.maybeLocaleOf(context)?.languageCode ??
              WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      await _authService.updateTestCompletion(
        archetype: archetype.name,
        category: archetype.category,
        iqScore: widget.iqScore,
        eqScore: _correctAnswers,
        iqNormalized: archetype.iqNormalized,
        eqNormalized: archetype.eqNormalized,
      );
      await AssessmentSetService().markAssignmentCompleted(
        type: 'eq',
        score: _correctAnswers,
        languageCode: languageCode,
      );

      debugPrint('✅ Test completed: ${archetype.name} (${archetype.category})');
    } catch (e) {
      debugPrint('❌ Error saving test results: $e');
    }

    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final languageCode = AssessmentLanguage.languageUsed(
      languageCode: Localizations.maybeLocaleOf(context)?.languageCode,
    );
    final display = AssessmentResultDisplayResolver.resolveIqEqLevel(
      archetype.category,
      languageCode: languageCode,
    );
    final emoji = display.emoji ?? archetype.emoji;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              display.title,
              style: GoogleFonts.playfairDisplay(
                color: AppColors.primary,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (display.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                display.tags.take(2).join(' · '),
                style: GoogleFonts.inter(
                  color: AppColors.primary.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              display.description,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.assessmentComplete,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const FrequencyIntroScreen(),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.assessmentContinue,
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return QAssessmentScaffold(
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.vizEq),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return QAssessmentScaffold(
        child: Center(
          child: Text(
            l10n.assessmentNoQuestionsAvailable,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final progress =
        (_currentQuestionIndex + 1) / _questions.length;
    final isLast = _currentQuestionIndex >= _questions.length - 1;

    return QAssessmentScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QAssessmentHeader(
            title: l10n.eqTestTitle,
            currentIndex: _currentQuestionIndex + 1,
            total: _questions.length,
          ),
          const SizedBox(height: 12),
          QAssessmentProgress(value: progress),
          const SizedBox(height: 16),
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: QQuestionCard(text: currentQuestion.question),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: QAnswerOptionCard(
                          index: index,
                          label: currentQuestion.options[index],
                          selected: _selectedAnswer == index,
                          onTap: () {
                            setState(() {
                              _selectedAnswer = index;
                            });
                          },
                        ),
                      );
                    },
                    childCount: currentQuestion.options.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          QAssessmentNavigation(
            label: isLast ? l10n.assessmentFinish : l10n.assessmentNext,
            onPressed: _nextQuestion,
          ),
        ],
      ),
    );
  }
}
