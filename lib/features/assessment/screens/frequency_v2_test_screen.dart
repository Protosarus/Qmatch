import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/navigation/auth_routing_refresh.dart';
import '../../../core/services/auth_service.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/frequency_v2_runtime/frequency_v2_runtime.dart';
import '../domain/frequency_v2_runtime/frequency_v2_screen_finalize_coordinator.dart';
import '../services/frequency_v2_finalize_callable_client.dart';
import '../services/frequency_v2_pending_finalization_pipeline.dart';
import '../utils/assessment_language.dart';
import '../widgets/frequency_question_chrome.dart';
import '../widgets/q_assessment_progress.dart';
import '../widgets/q_assessment_scaffold.dart';
import 'persona_assignment_gate_screen.dart';

enum _FrequencyV2LoadFailure { unsigned, generic }

enum _FrequencyV2SaveFailure { network, generic, account }

/// Live Frequency V2 question UI.
///
/// When no [controller] is injected, the screen loads reviewed TR/EN banks
/// from the Flutter asset bundle. After lock it runs
/// [FrequencyV2PendingFinalizationPipeline] and continues to Persona.
class FrequencyV2TestScreen extends StatefulWidget {
  const FrequencyV2TestScreen({
    super.key,
    this.controller,
    this.assetRuntime,
    this.pendingPipeline,
    this.auth,
    this.onLocked,
    this.onProductContinue,
    this.selectionHold = selectionHoldDuration,
  });

  final FrequencyV2SessionController? controller;
  final FrequencyV2AssetRuntime? assetRuntime;
  final FrequencyV2PendingFinalizationPipeline? pendingPipeline;
  final FirebaseAuth? auth;
  final VoidCallback? onLocked;

  /// Test hook. Production navigates to [PersonaAssignmentGateScreen].
  final VoidCallback? onProductContinue;

  /// Visible confirmation before the session advances. Tests may shorten it.
  final Duration selectionHold;

  static const Duration selectionHoldDuration = Duration(milliseconds: 350);

  @override
  State<FrequencyV2TestScreen> createState() => _FrequencyV2TestScreenState();
}

class _FrequencyV2TestScreenState extends State<FrequencyV2TestScreen> {
  FrequencyV2SessionController? _owned;
  FrequencyV2ScreenFinalizeCoordinator? _finalize;
  bool _didStartLoading = false;
  bool _pipelineInFlight = false;
  bool _isFinishing = false;
  bool _busy = false;
  bool _continuingToProduct = false;
  _FrequencyV2LoadFailure? _loadFailure;
  _FrequencyV2SaveFailure? _saveFailure;
  int? _heldOptionIndex;

  FrequencyV2SessionController? get _controller => widget.controller ?? _owned;

  String? _currentUid() =>
      (widget.auth ?? FirebaseAuth.instance).currentUser?.uid;

  FrequencyV2PendingFinalizationPipeline _livePipelineFor(
    FrequencyV2SessionController controller,
  ) {
    return widget.pendingPipeline ??
        FrequencyV2PendingFinalizationPipeline.live(
          manager: controller.manager,
          currentUid: _currentUid,
        );
  }

  void _ensureFinalize(FrequencyV2SessionController controller) {
    _finalize ??= FrequencyV2ScreenFinalizeCoordinator(
      pipeline: _livePipelineFor(controller),
    );
  }

  @override
  void initState() {
    super.initState();
    final injected = widget.controller;
    if (injected != null) {
      _ensureFinalize(injected);
      if (injected.session?.status ==
          FrequencyV2PersistedSessionStatus.completedPendingPersistence) {
        _isFinishing = true;
        _busy = true;
      }
    } else if (widget.pendingPipeline != null) {
      _finalize = FrequencyV2ScreenFinalizeCoordinator(
        pipeline: widget.pendingPipeline!,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.controller != null) {
      final session = widget.controller!.session;
      if (session?.status ==
          FrequencyV2PersistedSessionStatus.completedPendingPersistence) {
        _schedulePendingPipelineOnce();
      }
      return;
    }
    if (_didStartLoading) return;
    _didStartLoading = true;
    _bootstrapFromAssets();
  }

  Future<void> _bootstrapFromAssets() async {
    try {
      final uid = _currentUid();
      if (uid == null || uid.isEmpty) {
        if (!mounted) return;
        setState(() => _loadFailure = _FrequencyV2LoadFailure.unsigned);
        return;
      }
      final languageCode = AssessmentLanguage.languageUsed(context: context);
      final runtime = widget.assetRuntime ?? FrequencyV2AssetRuntime();
      final bank = await runtime.loadBankForLanguageCode(languageCode);
      final controller = await runtime.createSession(
        bank: bank,
        ownerUid: uid,
      );
      if (!mounted) return;
      _ensureFinalize(controller);
      final pending = controller.session?.status ==
          FrequencyV2PersistedSessionStatus.completedPendingPersistence;
      setState(() {
        _owned = controller;
        if (pending) {
          _busy = true;
          _isFinishing = true;
        }
      });
      if (pending) {
        _schedulePendingPipelineOnce();
      }
    } catch (error) {
      debugPrint('Frequency V2 load failed: ${error.runtimeType}');
      if (!mounted) return;
      setState(() => _loadFailure = _FrequencyV2LoadFailure.generic);
    }
  }

  void _schedulePendingPipelineOnce() {
    final coordinator = _finalize;
    if (coordinator == null || !coordinator.tryClaimBootstrapRetry()) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_runPendingFinalizationPipeline());
    });
  }

  /// [FrequencyQuestionPanel] reports 1-based option values (1..N).
  void _onPanelSelected(int oneBasedValue) {
    final controller = _controller;
    final plan = controller?.currentPlan;
    if (controller == null || plan == null) return;
    if (_inputsLocked) return;
    final index = oneBasedValue - 1;
    if (index < 0 || index >= plan.presentedOptionOrder.length) {
      return;
    }
    unawaited(_select(plan.presentedOptionOrder[index], visualIndex: index));
  }

  Future<void> _select(String optionId, {required int visualIndex}) async {
    final controller = _controller;
    if (controller == null) return;
    if (_isFinishing ||
        _busy ||
        _pipelineInFlight ||
        _finalize?.isBusy == true ||
        _continuingToProduct) {
      return;
    }
    final status = controller.session?.status;
    if (status ==
        FrequencyV2PersistedSessionStatus.completedPendingPersistence) {
      return;
    }
    if (status != null &&
        status != FrequencyV2PersistedSessionStatus.inProgress) {
      return;
    }
    setState(() {
      _busy = true;
      _heldOptionIndex = visualIndex;
    });
    if (widget.selectionHold > Duration.zero) {
      await Future<void>.delayed(widget.selectionHold);
    }
    if (!mounted) return;
    try {
      await controller.selectOption(optionId);
      await controller.lockIfComplete();
      if (!mounted) return;
      final lockedPending = controller.session?.status ==
          FrequencyV2PersistedSessionStatus.completedPendingPersistence;
      setState(() {
        _heldOptionIndex = null;
        if (lockedPending) {
          _isFinishing = true;
        }
      });
      if (lockedPending) {
        widget.onLocked?.call();
        await _runPendingFinalizationPipeline();
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _heldOptionIndex = null;
          if (!_pipelineInFlight && !_continuingToProduct) {
            _isFinishing = false;
          }
        });
      }
    }
  }

  Future<void> _runPendingFinalizationPipeline() async {
    final coordinator = _finalize;
    final session = _controller?.session;
    if (coordinator == null || session == null) return;
    if (_pipelineInFlight || coordinator.isBusy) return;
    _pipelineInFlight = true;
    setState(() {
      _isFinishing = true;
      _busy = true;
      _saveFailure = null;
    });
    try {
      final outcome = await coordinator.runIfPending(session);
      if (!mounted) return;
      if (outcome == null) {
        setState(() {
          _isFinishing = false;
          _busy = false;
        });
        return;
      }
      if (_controller != null && outcome.session != null) {
        _controller!.session = outcome.session;
      }
      if (outcome.destination ==
          FrequencyV2PendingPipelineDestination.productCompletion) {
        await _continueToProduct();
        return;
      }
      setState(() {
        _isFinishing = false;
        _busy = false;
        _saveFailure = _mapSaveFailure(outcome);
      });
    } finally {
      _pipelineInFlight = false;
    }
  }

  Future<void> _continueToProduct() async {
    if (_continuingToProduct) return;
    _continuingToProduct = true;
    if (widget.onProductContinue != null) {
      widget.onProductContinue!();
      if (mounted) {
        setState(() {
          _isFinishing = false;
          _busy = false;
          _saveFailure = null;
        });
      }
      return;
    }
    AuthRoutingRefresh.bump();
    final profileCompleted = await AuthService().hasCompletedProfile();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PersonaAssignmentGateScreen(
          profileCompleted: profileCompleted,
        ),
      ),
    );
  }

  bool get _inputsLocked =>
      _isFinishing ||
      _busy ||
      _pipelineInFlight ||
      _continuingToProduct ||
      _heldOptionIndex != null ||
      _saveFailure != null ||
      _controller?.session?.status ==
          FrequencyV2PersistedSessionStatus.completedPendingPersistence;

  bool get _hasReadySession => _controller?.session != null;

  _FrequencyV2SaveFailure? _mapSaveFailure(
    FrequencyV2PendingPipelineResult outcome,
  ) {
    if (outcome.destination ==
        FrequencyV2PendingPipelineDestination.productCompletion) {
      return null;
    }
    final code = outcome.uiErrorCode;
    if (code == 'FREQUENCY_V2_ALREADY_FINALIZED') {
      return null;
    }
    if (outcome.failureKind ==
            FrequencyV2FinalizeFailureKind.accountInconsistency ||
        code == 'unauthenticated' ||
        code == 'owner_unavailable' ||
        code == 'owner_mismatch') {
      return _FrequencyV2SaveFailure.account;
    }
    if (outcome.failureKind == FrequencyV2FinalizeFailureKind.retryable) {
      return _FrequencyV2SaveFailure.network;
    }
    return _FrequencyV2SaveFailure.generic;
  }

  Future<void> _retryLoad() async {
    if (_owned != null || _controller != null) {
      return;
    }
    setState(() {
      _loadFailure = null;
    });
    await _bootstrapFromAssets();
  }

  String _saveFailureMessage(
    AppLocalizations l10n,
    _FrequencyV2SaveFailure failure,
  ) {
    switch (failure) {
      case _FrequencyV2SaveFailure.network:
        return l10n.frequencyV2SaveErrorNetwork;
      case _FrequencyV2SaveFailure.account:
        return l10n.frequencyV2SaveErrorAccount;
      case _FrequencyV2SaveFailure.generic:
        return l10n.frequencyV2SaveErrorGeneric;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = _controller;
    final plan = controller?.currentPlan;
    final item = controller?.currentItem;
    final labels = <String>[];
    if (plan != null) {
      for (final id in plan.presentedOptionOrder) {
        labels.add(controller?.optionText(id) ?? id);
      }
    }
    final selectedId = plan == null
        ? null
        : controller?.session?.answersByItemId[plan.itemId]?.selectedOptionId;
    final selectedIndex = selectedId == null || plan == null
        ? null
        : plan.presentedOptionOrder.indexOf(selectedId);
    final visualIndex = _heldOptionIndex ??
        (selectedIndex != null && selectedIndex >= 0 ? selectedIndex : null);
    final compact = MediaQuery.sizeOf(context).height < 700;
    final total = controller?.progressTotal ?? 50;
    final rawIndex = controller?.progressIndex ?? 0;
    final index = rawIndex.clamp(1, total);
    final progress = (index / total).clamp(0.0, 1.0);
    final showQuestion = _hasReadySession &&
        _loadFailure == null &&
        _saveFailure == null &&
        !_isFinishing &&
        item != null &&
        labels.isNotEmpty;
    final retryFinalize = _saveFailure != null &&
        !_continuingToProduct &&
        controller?.session?.status ==
            FrequencyV2PersistedSessionStatus.completedPendingPersistence;
    final retryLoad = _loadFailure != null && !_hasReadySession;
    return QAssessmentScaffold(
      richBackdrop: true,
      backgroundImageAsset: 'assets/images/welcome_cosmic_background.png',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FrequencyQuestionTopBar(),
          if (showQuestion || _isFinishing || _saveFailure != null) ...[
            FrequencyProgressHeader(
              label: '$index / $total',
              progress: progress,
              semanticLabel: l10n.frequencyV2ProgressSemantic(index, total),
            ),
            QAssessmentProgress(value: progress),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: _buildBody(
              l10n: l10n,
              compact: compact,
              showQuestion: showQuestion,
              itemPrompt: item?.prompt ?? '',
              labels: labels,
              visualIndex: visualIndex,
            ),
          ),
          if (retryFinalize || retryLoad)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FrequencyContinueButton(
                key: const Key('frequency-v2-retry'),
                label: l10n.retry,
                active: !_pipelineInFlight && _finalize?.isBusy != true,
                saving: _pipelineInFlight || _finalize?.isBusy == true,
                onPressed: () {
                  if (retryLoad) {
                    unawaited(_retryLoad());
                    return;
                  }
                  if (_pipelineInFlight || _finalize?.isBusy == true) {
                    return;
                  }
                  unawaited(_runPendingFinalizationPipeline());
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody({
    required AppLocalizations l10n,
    required bool compact,
    required bool showQuestion,
    required String itemPrompt,
    required List<String> labels,
    required int? visualIndex,
  }) {
    if (_loadFailure != null && !_hasReadySession) {
      return _FrequencyV2StatusPane(
        key: const Key('frequency-v2-load-error'),
        compact: compact,
        message: _loadFailure == _FrequencyV2LoadFailure.unsigned
            ? l10n.frequencyV2SaveErrorAccount
            : l10n.frequencyV2LoadError,
      );
    }
    if (!_hasReadySession) {
      return _FrequencyV2StatusPane(
        key: const Key('frequency-v2-loading'),
        compact: compact,
        message: l10n.frequencyV2Loading,
        busy: true,
      );
    }
    if (_saveFailure != null) {
      return _FrequencyV2StatusPane(
        key: const Key('frequency-v2-save-error'),
        compact: compact,
        message: _saveFailureMessage(l10n, _saveFailure!),
      );
    }
    if (_isFinishing) {
      return _FrequencyV2StatusPane(
        key: const Key('frequency-v2-finishing'),
        compact: compact,
        message: l10n.frequencyV2Finishing,
        busy: true,
      );
    }
    if (!showQuestion) {
      return _FrequencyV2StatusPane(
        key: const Key('frequency-v2-loading'),
        compact: compact,
        message: l10n.frequencyV2Loading,
        busy: true,
      );
    }
    return FrequencyQuestionPanel(
      key: const Key('frequency-v2-question-panel'),
      compact: compact,
      enabled: !_inputsLocked,
      eyebrow: l10n.assessmentStageFrequency,
      question: itemPrompt,
      labels: labels,
      selectedValue: visualIndex != null ? visualIndex + 1 : null,
      onSelected: _onPanelSelected,
    );
  }
}

class _FrequencyV2StatusPane extends StatelessWidget {
  const _FrequencyV2StatusPane({
    super.key,
    required this.compact,
    required this.message,
    this.busy = false,
  });

  final bool compact;
  final String message;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy) ...[
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Color(0xFFDAC8ED),
                  ),
                ),
                SizedBox(height: compact ? 16 : 20),
              ],
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: compact ? 14.5 : 16,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
