import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/frequency_model.dart';
import '../services/assessment_set_service.dart';
import '../services/frequency_service.dart';
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

  int _index = 0;
  final Map<String, int> _answers = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final list = await _service.loadAssignedFrequencyQuestions();
      if (!mounted) return;
      setState(() {
        _questions =
            list.isNotEmpty ? list : _service.getFrequencyQuestions();
        _loadingQuestions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _questions = _service.getFrequencyQuestions();
        _loadingQuestions = false;
      });
    }
  }

  FrequencyQuestion get _current => _questions[_index];

  int? get _currentValue => _answers[_current.id];

  void _setAnswer(int v) {
    setState(() {
      _answers[_current.id] = v;
    });
  }

  void _next() {
    if (_currentValue == null) return;
    if (_index < _questions.length - 1) {
      setState(() => _index++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_index == 0) return;
    setState(() => _index--);
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      final result = _service.calculateResult(_answers, _questions);
      try {
        await AssessmentSetService().markAssignmentCompleted(
          type: 'frequency',
          score: result.scoreTotal,
        );
      } catch (_) {}
      await _service.saveFrequencyResult(result);
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
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingQuestions || _questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.primary),
          title: Text(
            'Frequency Test',
            style: GoogleFonts.playfairDisplay(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    final progress = (_index + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: Text(
          'Frequency Test',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade900,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_index + 1}/${_questions.length}',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                _current.question,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              ...List.generate(5, (i) {
                final v = i + 1;
                final selected = _currentValue == v;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _saving ? null : () => _setAnswer(v),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? Colors.transparent
                              : AppColors.primary.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected ? Colors.black : Colors.transparent,
                              border: selected
                                  ? null
                                  : Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.6),
                                      width: 1.5,
                                    ),
                            ),
                            child: selected
                                ? const Icon(Icons.check, size: 16, color: AppColors.primary)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _current.options[i],
                              style: GoogleFonts.inter(
                                color: selected ? Colors.black : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving || _index == 0 ? null : _back,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Back', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving || _currentValue == null ? null : _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : Text(
                              _index < _questions.length - 1 ? 'Next' : 'See My Frequency',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

