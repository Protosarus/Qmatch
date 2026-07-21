import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../models/frequency_model.dart';
import '../services/assessment_set_service.dart';
import '../services/frequency_service.dart';
import '../widgets/frequency_question_chrome.dart';
import '../widgets/q_assessment_scaffold.dart';
import 'frequency_result_screen.dart';

class FrequencyTestScreen extends StatefulWidget {
  const FrequencyTestScreen({super.key});

  @override
  State<FrequencyTestScreen> createState() => _FrequencyTestScreenState();
}

class _FrequencyTestScreenState extends State<FrequencyTestScreen> {
  final _service = FrequencyService();
  List<FrequencyQuestion> _questions = [];
  bool _loadingQuestions = true;
  bool _didStartLoading = false;

  int _index = 0;
  final Map<String, int> _answers = {};
  bool _saving = false;
  bool _showSelectAnswerWarning = false;
  Timer? _selectAnswerWarningTimer;

  static const _continueButtonHeight = 54.0;
  static const _warningAboveContinueGap = 62.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _selectAnswerWarningTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStartLoading) return;
    _didStartLoading = true;
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final languageCode = Localizations.maybeLocaleOf(context)?.languageCode ??
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      final list = await _service.loadAssignedFrequencyQuestions(
        languageCode: languageCode,
      );
      if (!mounted) return;
      setState(() {
        _questions = list.isNotEmpty ? list : _service.getFrequencyQuestions();
        _loadingQuestions = false;
      });
    } catch (e) {
      debugPrint('Frequency questions load failed: $e');
      if (!mounted) return;
      try {
        final fallback = _service.getFrequencyQuestions();
        setState(() {
          _questions = fallback;
          _loadingQuestions = false;
        });
      } catch (fallbackError) {
        debugPrint('Frequency questions fallback failed: $fallbackError');
        setState(() {
          _questions = [];
          _loadingQuestions = false;
        });
      }
    }
  }

  FrequencyQuestion get _current => _questions[_index];

  int? get _currentValue => _answers[_current.id];

  List<String> _likertLabels(AppLocalizations l10n) => [
        l10n.stronglyDisagree,
        l10n.disagree,
        l10n.neutral,
        l10n.agree,
        l10n.stronglyAgree,
      ];

  void _setAnswer(int v) {
    _dismissSelectAnswerWarning();
    setState(() {
      _answers[_current.id] = v;
    });
  }

  void _next() {
    if (_currentValue == null) {
      _showSelectAnswerWarningBanner();
      return;
    }
    _dismissSelectAnswerWarning();
    if (_index < _questions.length - 1) {
      setState(() => _index++);
    } else {
      _finish();
    }
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

  void _back() {
    if (_index == 0) return;
    setState(() => _index--);
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      final languageCode = Localizations.maybeLocaleOf(context)?.languageCode ??
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      final result = _service.calculateResult(_answers, _questions);
      try {
        await AssessmentSetService().markAssignmentCompleted(
          type: 'frequency',
          score: result.scoreTotal,
          languageCode: languageCode,
        );
      } catch (_) {}
      await _service.saveFrequencyResult(
        result,
        languageCode: languageCode,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FrequencyResultScreen(result: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loadingQuestions) {
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

    if (_questions.isEmpty) {
      return QAssessmentScaffold(
        richBackdrop: true,
        backgroundImageAsset: 'assets/images/welcome_cosmic_background.png',
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

    final progress = (_index + 1) / _questions.length;
    final likert = _likertLabels(l10n);
    final isLast = _index >= _questions.length - 1;

    return QAssessmentScaffold(
      richBackdrop: true,
      backgroundImageAsset: 'assets/images/welcome_cosmic_background.png',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final compact = height < 700;
          final heroHeight =
              (height * (compact ? 0.17 : 0.21)).clamp(82.0, 172.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FrequencyQuestionTopBar(
                    onBack: () {
                      if (_index == 0) {
                        Navigator.of(context).maybePop();
                      } else {
                        _back();
                      }
                    },
                  ),
                  FrequencyProgressHeader(
                    label:
                        '${l10n.assessmentStageFrequency} • ${_index + 1} / ${_questions.length}',
                    progress: progress,
                  ),
                  SizedBox(
                    height: heroHeight,
                    child: const FrequencyWaveHero(),
                  ),
                  Expanded(
                    child: FrequencyQuestionPanel(
                      eyebrow: l10n.frequencyTestTitle,
                      question: _current.question,
                      labels: likert,
                      selectedValue: _currentValue,
                      compact: compact,
                      onSelected: _saving ? (_) {} : _setAnswer,
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 9),
                  FrequencyContinueButton(
                    label:
                        isLast ? l10n.seeMyFrequency : l10n.assessmentContinue,
                    active: _currentValue != null,
                    saving: _saving,
                    onPressed: _next,
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
