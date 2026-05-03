import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/elegant_warning.dart';
import '../models/question_model.dart';
import '../services/assessment_set_service.dart';
import '../services/question_service.dart';
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
  int _correctAnswers = 0;

  @override
  void initState() {
    super.initState();
    _disableScreenshots();
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
    final questions = await _questionService.getRandomIQQuestions(count: 10);
    setState(() {
      _questions = questions;
      _isLoading = false;
    });
  }

  Future<void> _nextQuestion() async {
    if (_selectedAnswer == null) {
      showElegantWarning(context, 'Lütfen bir cevap seçin');
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
        await AssessmentSetService().markAssignmentCompleted(
          type: 'iq',
          score: _correctAnswers,
        );
      } catch (e) {
        debugPrint('IQ assignment completion: $e');
      }
      if (!mounted) return;
      _showTransitionDialog();
    }
  }

  void _showTransitionDialog() {
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
              // Icon
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
              
              // Title
              Text(
                'IQ Testi Tamamlandı!',
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Message
              Text(
                'Harika! Şimdi duygusal zekanı test edelim.',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Dialog'u kapat
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => EQTestScreen(iqScore: _correctAnswers),
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
                    'EQ TESTİNE BAŞLA',
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'No questions available',
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor:
                            (_currentQuestionIndex + 1) / _questions.length,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_currentQuestionIndex + 1}/${_questions.length}',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                currentQuestion.question,
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView.builder(
                  itemCount: currentQuestion.options.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedAnswer == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAnswer = index;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? null
                                      : Border.all(
                                          color: AppColors.primary,
                                          width: 2,
                                        ),
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + index),
                                    style: GoogleFonts.inter(
                                      color: AppColors.primary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  currentQuestion.options[index],
                                  style: GoogleFonts.inter(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: 15,
                                  ),
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
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => _nextQuestion(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentQuestionIndex < _questions.length - 1
                        ? 'NEXT'
                        : 'FINISH',
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
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
}
