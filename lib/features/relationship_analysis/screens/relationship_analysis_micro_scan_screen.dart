import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_cosmic_button.dart';
import '../../../core/widgets/cosmic/qmatch_cosmic_background.dart';
import '../../../core/widgets/qmatch_feedback.dart';
import '../../../core/widgets/qmatch_pushed_screen_header.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/relationship_analysis_state.dart';
import '../domain/relationship_bank_models.dart';
import '../domain/relationship_dimensions.dart';
import '../domain/relationship_insight_copy.dart';
import '../domain/relationship_insight_engine.dart';
import '../domain/relationship_scorer.dart';
import '../services/relationship_analysis_service.dart';

class RelationshipAnalysisMicroScanScreen extends StatefulWidget {
  const RelationshipAnalysisMicroScanScreen({
    super.key,
    this.service,
    this.uidOverride,
    this.initialState,
  });

  final RelationshipAnalysisService? service;
  final String? uidOverride;
  final RelationshipAnalysisState? initialState;

  @override
  State<RelationshipAnalysisMicroScanScreen> createState() =>
      _RelationshipAnalysisMicroScanScreenState();
}

class _RelationshipAnalysisMicroScanScreenState
    extends State<RelationshipAnalysisMicroScanScreen> {
  late final RelationshipAnalysisService _service =
      widget.service ?? RelationshipAnalysisService();

  RelationshipAnalysisBank? _bank;
  RelationshipAnalysisState? _state;
  String? _selectedOptionId;
  bool _loading = true;
  bool _saving = false;
  bool _completedBatch = false;
  bool _loadFailed = false;
  bool _bankComplete = false;
  double _depthAtScanStart = 0.0;

  final RelationshipInsightEngine _insightEngine =
      const RelationshipInsightEngine();
  final RelationshipInsightCopyResolver _insightCopyResolver =
      const RelationshipInsightCopyResolver();

  Set<String> _insightSignaturesAtScanStart = const {};
  RelationshipInsight? _completionInsight;

  String get _uid =>
      widget.uidOverride ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  String get _lang =>
      Localizations.localeOf(context).languageCode.toLowerCase();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
      _bankComplete = false;
      _completedBatch = false;
      _completionInsight = null;
      _insightSignaturesAtScanStart = const {};
    });
    try {
      if (_uid.isEmpty) throw StateError('Not signed in');
      final bank = await _service.loadBank();
      var state = await _service.loadState(_uid);
      if (_service.isBankComplete(state)) {
        if (!mounted) return;
        setState(() {
          _bank = bank;
          _state = state;
          _bankComplete = true;
          _loading = false;
        });
        return;
      }
      _depthAtScanStart = state.analysisDepth;

      final baselineState = _stateBeforeActiveBatch(
        bank: bank,
        state: state,
      );
      _insightSignaturesAtScanStart =
          _insightEngine.derive(baselineState).map(_insightSignature).toSet();

      state = await _service.beginMicroScan(uid: _uid, state: state);
      if (!mounted) return;
      if (!state.hasActiveMicroScan) {
        setState(() {
          _bank = bank;
          _state = state;
          _bankComplete = _service.isBankComplete(state);
          _completedBatch = !_bankComplete;
          _loading = false;
        });
        return;
      }
      final ids = state.activeMicroScanQuestionIds;
      final idx = state.activeMicroScanIndex.clamp(0, ids.length - 1);
      setState(() {
        _bank = bank;
        _state = state;
        _selectedOptionId = state.answersByQuestionId[ids[idx]];
        _completedBatch = false;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  RelationshipQuestion? get _currentQuestion {
    final state = _state;
    final bank = _bank;
    if (state == null || bank == null) return null;
    final ids = state.activeMicroScanQuestionIds;
    if (ids.isEmpty) return null;
    final index = state.activeMicroScanIndex.clamp(0, ids.length - 1);
    return bank.byId[ids[index]];
  }

  String _insightSignature(RelationshipInsight insight) {
    return '${insight.family.name}:'
        '${insight.firstBand.name}:'
        '${insight.secondBand.name}';
  }

  RelationshipAnalysisState _stateBeforeActiveBatch({
    required RelationshipAnalysisBank bank,
    required RelationshipAnalysisState state,
  }) {
    final activeIds = state.activeMicroScanQuestionIds.toSet();
    if (activeIds.isEmpty) return state;

    final baselineAnswers = Map<String, String>.from(state.answersByQuestionId)
      ..removeWhere((questionId, _) => activeIds.contains(questionId));

    final snapshot = const RelationshipAnalysisScorer().score(
      bank: bank,
      answersByQuestionId: baselineAnswers,
    );

    return state.copyWith(
      answersByQuestionId: baselineAnswers,
      dimensionScores: snapshot.dimensionScores,
      dimensionEvidenceCounts: snapshot.dimensionEvidenceCounts,
      dimensionRawSignedEvidence: snapshot.dimensionRawSignedEvidence,
      analysisDepth: snapshot.analysisDepth,
    );
  }

  RelationshipInsight? _findCompletionInsight(
    RelationshipAnalysisState state,
  ) {
    final current = _insightEngine.derive(state);

    for (final insight in current) {
      if (!_insightSignaturesAtScanStart.contains(
        _insightSignature(insight),
      )) {
        return insight;
      }
    }

    return null;
  }

  Future<void> _onNext() async {
    final question = _currentQuestion;
    final optionId = _selectedOptionId;
    final state = _state;
    if (question == null || optionId == null || state == null || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final hadScan = state.activeMicroScanQuestionIds.isNotEmpty;
      final next = await _service.submitAnswer(
        uid: _uid,
        state: state,
        questionId: question.id,
        optionId: optionId,
      );
      if (!mounted) return;
      final completed = hadScan && !next.hasActiveMicroScan;
      final completionInsight = completed ? _findCompletionInsight(next) : null;

      String? selected;
      if (next.hasActiveMicroScan) {
        final ids = next.activeMicroScanQuestionIds;
        final idx = next.activeMicroScanIndex.clamp(0, ids.length - 1);
        selected = next.answersByQuestionId[ids[idx]];
      }
      setState(() {
        _state = next;
        _selectedOptionId = selected;
        _completedBatch = completed;
        _completionInsight = completionInsight;
        _bankComplete = _service.isBankComplete(next);
        _saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      final l10n = AppLocalizations.of(context)!;
      QMatchFeedback.show(
        context,
        message: l10n.relationshipAnalysisSaveFailed,
        type: QMatchFeedbackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: QMatchCosmicBackground(
        seed: 19,
        starCount: 16,
        animate: false,
        showAccentHalos: false,
        starfieldOpacity: 0.36,
        child: SafeArea(
          child: Column(
            children: [
              QMatchPushedScreenHeader(
                title: l10n.relationshipAnalysisTitle,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(child: _buildBody(l10n)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('relationship-analysis-loading'),
          color: AppColors.resonanceViolet,
        ),
      );
    }
    if (_loadFailed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.relationshipAnalysisLoadFailed,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              QCosmicButton(
                label: l10n.retry,
                onPressed: _bootstrap,
                variant: QCosmicButtonVariant.glass,
                expanded: false,
                height: 44,
              ),
            ],
          ),
        ),
      );
    }
    if (_bankComplete) {
      return _buildCompletePayoff(
        l10n,
        title: l10n.relationshipAnalysisCompleteTitle,
        body: l10n.relationshipAnalysisStatusComplete,
        before: null,
        after: _state?.analysisDepth ?? 1.0,
      );
    }
    if (_completedBatch || _currentQuestion == null) {
      return _buildCompletePayoff(
        l10n,
        title: l10n.relationshipAnalysisCompleteTitle,
        body: l10n.relationshipAnalysisCompleteBody,
        before: _depthAtScanStart,
        after: _state?.analysisDepth ?? _depthAtScanStart,
      );
    }

    final question = _currentQuestion!;
    final total = (_state?.activeMicroScanQuestionIds.length ??
            RelationshipAnalysisContract.microScanSize)
        .clamp(1, RelationshipAnalysisContract.microScanSize);
    final step = ((_state?.activeMicroScanIndex ?? 0) + 1).clamp(1, total);
    final overallPct =
        ((_state?.analysisDepth ?? 0) * 100).round().clamp(0, 100);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.relationshipAnalysisMicroScanProgress(step, total),
            key: const Key('relationship-analysis-progress-label'),
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.relationshipAnalysisOverallDepth(overallPct),
            key: const Key('relationship-analysis-overall-depth'),
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              key: const Key('relationship-analysis-progress'),
              value: step / total,
              minHeight: 6,
              backgroundColor: AppColors.borderSubtle,
              color: AppColors.resonanceViolet,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _bank!.responseInstruction.resolve(_lang),
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            question.prompt.resolve(_lang),
            key: const Key('relationship-analysis-prompt'),
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView(
              children: [
                for (final option in question.options) ...[
                  Material(
                    key: Key('relationship-analysis-option-${option.id}'),
                    color: _selectedOptionId == option.id
                        ? AppColors.resonanceViolet.withValues(alpha: 0.28)
                        : AppColors.glassSurface,
                    borderRadius: AppRadii.buttonBorder,
                    child: InkWell(
                      onTap: _saving
                          ? null
                          : () => setState(() => _selectedOptionId = option.id),
                      borderRadius: AppRadii.buttonBorder,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 56),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: AppRadii.buttonBorder,
                          border: Border.all(
                            color: _selectedOptionId == option.id
                                ? AppColors.resonanceViolet
                                : AppColors.borderSubtle,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedOptionId == option.id
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: _selectedOptionId == option.id
                                  ? AppColors.resonanceViolet
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option.text.resolve(_lang),
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
          Row(
            children: [
              const Spacer(),
              if (_saving)
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.resonanceViolet,
                      ),
                    ),
                  ),
                )
              else
                QCosmicButton(
                  key: const Key('relationship-analysis-next'),
                  label: l10n.relationshipAnalysisNext,
                  onPressed: _selectedOptionId == null ? null : _onNext,
                  variant: QCosmicButtonVariant.primary,
                  expanded: false,
                  height: 48,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletePayoff(
    AppLocalizations l10n, {
    required String title,
    required String body,
    required double? before,
    required double after,
  }) {
    final afterPct = (after * 100).round().clamp(0, 100);
    final beforePct =
        before == null ? null : (before * 100).round().clamp(0, 100);
    final showRange = beforePct != null && beforePct != afterPct;

    final insight = _completedBatch ? _completionInsight : null;
    final insightCopy =
        insight == null ? null : _insightCopyResolver.resolve(insight);
    final isTurkish = _lang == 'tr';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.resonanceViolet,
            size: 36,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            key: const Key('relationship-analysis-complete-title'),
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            key: const Key('relationship-analysis-complete'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          if (insightCopy != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              key: const Key('relationship-analysis-completion-insight'),
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.resonanceViolet.withValues(alpha: 0.38),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTurkish
                        ? 'Yeni bir örüntü belirdi'
                        : 'A new pattern emerged',
                    style: GoogleFonts.inter(
                      color: AppColors.resonanceViolet,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isTurkish ? insightCopy.titleTr : insightCopy.titleEn,
                    key: const Key(
                      'relationship-analysis-completion-insight-title',
                    ),
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isTurkish ? insightCopy.bodyTr : insightCopy.bodyEn,
                    key: const Key(
                      'relationship-analysis-completion-insight-body',
                    ),
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.relationshipAnalysisDepthLabel,
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            showRange
                ? l10n.relationshipAnalysisDepthTransition(
                    beforePct,
                    afterPct,
                  )
                : l10n.relationshipAnalysisDepthPercent(afterPct),
            key: const Key('relationship-analysis-complete-depth'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.resonanceViolet,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          QCosmicButton(
            key: const Key('relationship-analysis-back'),
            label: l10n.relationshipAnalysisBackToProfile,
            onPressed: () => Navigator.of(context).pop(true),
            variant: QCosmicButtonVariant.primary,
            height: 48,
          ),
        ],
      ),
    );
  }
}
