import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/eq_bank/eq_bank.dart';
import '../domain/eq_session/eq_session.dart';
import '../domain/profile/profile.dart';
import '../services/assessment_progress_service.dart';
import '../services/canonical_assessment_persistence.dart';
import '../services/eq_canonical_runtime_service.dart';
import '../utils/assessment_language.dart';
import '../widgets/assessment_widgets.dart';
import 'frequency_intro_screen.dart';

/// Canonical 30-item EQ session — behavioral tendency, not correctness.
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
  final _runtime = EqCanonicalRuntimeService();
  final _persistence = CanonicalAssessmentPersistence();
  final _progress = AssessmentProgressService();

  EqPersistedSessionState? _session;
  EqCanonicalBankDocument? _bank;
  String? _selectedOptionId;
  bool _isLoading = true;
  bool _didStartLoading = false;
  bool _isFinishing = false;
  String? _loadError;
  DateTime? _startedAt;
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
      if (!mounted) return;
      setState(() {
        _session = session;
        _bank = bank;
        _selectedOptionId = existing?.selectedOptionId;
        _startedAt = DateTime.tryParse(session.startedAt) ?? DateTime.now();
        _isLoading = false;
      });
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
    if (session == null || bank == null || _isFinishing) return;
    if (_selectedOptionId == null) {
      _showSelectAnswerWarningBanner();
      return;
    }
    _dismissSelectAnswerWarning();

    final plan = session.itemPlans[session.currentQuestionIndex];
    final answered = await _runtime.answer(
      sessionId: session.sessionId,
      itemId: plan.itemId,
      selectedOptionId: _selectedOptionId!,
    );
    if (!answered.ok || answered.state == null) {
      debugPrint('EQ answer failed: ${answered.message}');
      return;
    }

    final isLast = session.currentQuestionIndex >= session.itemPlans.length - 1;
    if (!isLast) {
      final moved = await _runtime.moveToIndex(
        sessionId: session.sessionId,
        index: session.currentQuestionIndex + 1,
      );
      if (!moved.ok || moved.state == null || !mounted) return;
      final next = moved.state!;
      final existing = next
          .answersByItemId[next.itemPlans[next.currentQuestionIndex].itemId];
      setState(() {
        _session = next;
        _selectedOptionId = existing?.selectedOptionId;
      });
      return;
    }

    await _completeAndNavigate(answered.state!);
  }

  Future<void> _completeAndNavigate(EqPersistedSessionState answered) async {
    setState(() => _isFinishing = true);
    try {
      final languageCode =
          Localizations.maybeLocaleOf(context)?.languageCode ??
              WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      final language = AssessmentLanguage.languageUsed(
        languageCode: languageCode,
      );
      final locale = AssessmentLanguage.localeUsed(
        locale: Locale(language),
      );

      final completed = await _runtime.completeSession(
        sessionId: answered.sessionId,
      );
      if (!completed.ok || completed.state == null) {
        throw StateError(completed.message);
      }
      final scored = await _runtime.scoreCompleted(completed.state!);
      if (!scored.ok || scored.result == null) {
        throw StateError(scored.message ?? 'EQ scoring failed');
      }
      final result = scored.result!;

      await _persistence.upsertCompletedAssessment(
        assessmentType: 'eq',
        fields: _persistence.buildCanonicalEq10dPayload(
          result: result,
          sessionId: completed.state!.sessionId,
          locale: locale,
          languageUsed: language,
          startedAt: _startedAt,
        ),
      );

      final uid = _runtime.currentUid;
      if (uid == null || uid.isEmpty) {
        throw StateError('Owner UID unavailable');
      }

      final existingProfile = await _persistence.getCanonicalProfile(uid: uid);
      final existingIq = <QmatchProfileDimension>[];
      if (existingProfile != null) {
        final rows = existingProfile['measured_dimensions'];
        if (rows is List) {
          for (final row in rows) {
            if (row is! Map) continue;
            final d = QmatchProfileDimension.fromJson(
              Map<String, dynamic>.from(row),
            );
            if (d.module == 'iq' &&
                d.measurementState == QmatchMeasurementState.measured) {
              existingIq.add(d);
            }
          }
        }
      }

      final adapted = const EqTo20dRuntimeAdapter().adapt(
        result: result,
        ownerUid: uid,
        sessionId: completed.state!.sessionId,
        existingIqDimensions: existingIq,
      );
      if (!adapted.ok || adapted.fragment == null) {
        throw StateError(adapted.message ?? 'EQ→20D adapt failed');
      }
      await _persistence.upsertCanonicalProfileFragment(adapted.fragment!);

      await _progress.markEqCompleted();

      debugPrint('✅ Canonical EQ completed — navigating to Frequency');
    } catch (e) {
      debugPrint('❌ Error saving canonical EQ results: $e');
      if (mounted) {
        setState(() => _isFinishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('EQ completion failed: $e')),
        );
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const FrequencyIntroScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading || _isFinishing) {
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
                  EqQuestionTopBar(
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (var index = 0; index < options.length; index++)
                          EqAnswerOptionRow(
                            index: index,
                            label: EqAnswerOptionRow.displayLabel(
                              options[index].text,
                            ),
                            selected:
                                _selectedOptionId == options[index].optionId,
                            compact: true,
                            onTap: () {
                              _dismissSelectAnswerWarning();
                              setState(() {
                                _selectedOptionId = options[index].optionId;
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
                    active: _selectedOptionId != null,
                    onPressed: _onContinue,
                  ),
                ],
              ),
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
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: AppRadii.pillBorder,
            color: const Color(0xCC1A1028),
            border: Border.all(
              color: AppColors.vizEq.withValues(alpha: 0.45),
            ),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
