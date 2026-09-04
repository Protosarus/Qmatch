import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/frequency_v2_runtime/frequency_v2_runtime.dart';
import '../domain/frequency_v2_runtime/frequency_v2_screen_finalize_coordinator.dart';
import '../services/frequency_v2_pending_finalization_pipeline.dart';
import '../utils/assessment_language.dart';
import '../widgets/frequency_question_chrome.dart';
import '../widgets/q_assessment_progress.dart';
import '../widgets/q_assessment_scaffold.dart';

/// Internal Frequency V2 question UI. Not selected by live routing while
/// [FrequencyRuntimeSelectionPolicy] resolves to V1.
///
/// When no [controller] is injected, the screen loads reviewed TR/EN banks
/// from the Flutter asset bundle rather than developer `tool/` paths.
/// After lock it runs [FrequencyV2PendingFinalizationPipeline] itself.
class FrequencyV2TestScreen extends StatefulWidget {
  const FrequencyV2TestScreen({
    super.key,
    this.controller,
    this.assetRuntime,
    this.pendingPipeline,
    this.auth,
    this.onLocked,
  });

  final FrequencyV2SessionController? controller;
  final FrequencyV2AssetRuntime? assetRuntime;
  final FrequencyV2PendingFinalizationPipeline? pendingPipeline;
  final FirebaseAuth? auth;
  final VoidCallback? onLocked;

  static const String internalCompletionTitle =
      'Frequency V2 internal test completed';

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
  bool _showDormantCompletion = false;
  String? _loadError;
  String? _uiErrorCode;

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
        setState(() => _loadError = 'owner_unavailable');
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
      if (!mounted) return;
      setState(() => _loadError = error.toString());
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

  Future<void> _select(String optionId) async {
    final controller = _controller;
    if (controller == null) return;
    if (_isFinishing ||
        _busy ||
        _pipelineInFlight ||
        _finalize?.isBusy == true ||
        _showDormantCompletion) {
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
    setState(() => _busy = true);
    try {
      await controller.selectOption(optionId);
      await controller.lockIfComplete();
      if (!mounted) return;
      setState(() {});
      if (controller.session?.status ==
          FrequencyV2PersistedSessionStatus.completedPendingPersistence) {
        widget.onLocked?.call();
        await _runPendingFinalizationPipeline();
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          if (!_pipelineInFlight && !_showDormantCompletion) {
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
      _uiErrorCode = null;
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
          FrequencyV2PendingPipelineDestination.dormantCompletion) {
        setState(() {
          _showDormantCompletion = true;
          _isFinishing = false;
          _busy = false;
          _uiErrorCode = null;
        });
        return;
      }
      setState(() {
        _isFinishing = false;
        _busy = false;
        _uiErrorCode = outcome.uiErrorCode ??
            outcome.failureKind?.name ??
            'finalize_failed';
      });
    } finally {
      _pipelineInFlight = false;
    }
  }

  bool get _inputsLocked =>
      _isFinishing ||
      _busy ||
      _pipelineInFlight ||
      _showDormantCompletion ||
      _controller?.session?.status ==
          FrequencyV2PersistedSessionStatus.completedPendingPersistence;

  @override
  Widget build(BuildContext context) {
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
    final compact = MediaQuery.sizeOf(context).height < 700;
    final locale = controller?.bank.locale ?? '';
    final statusLine = _uiErrorCode ?? _loadError ?? locale;
    final retryable = _uiErrorCode != null &&
        !_showDormantCompletion &&
        controller?.session?.status ==
            FrequencyV2PersistedSessionStatus.completedPendingPersistence;

    return QAssessmentScaffold(
      richBackdrop: true,
      backgroundImageAsset: 'assets/images/welcome_cosmic_background.png',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FrequencyQuestionTopBar(),
          Text(
            statusLine,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 11,
            ),
          ),
          FrequencyProgressHeader(
            label:
                '${controller?.progressIndex ?? 1} / ${controller?.progressTotal ?? 50}',
            progress: (controller?.progressIndex ?? 1) /
                (controller?.progressTotal ?? 50),
          ),
          QAssessmentProgress(
            value: (controller?.progressIndex ?? 1) /
                (controller?.progressTotal ?? 50),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _showDormantCompletion
                ? Center(
                    child: Text(
                      FrequencyV2TestScreen.internalCompletionTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 16,
                        height: 1.3,
                      ),
                    ),
                  )
                : FrequencyQuestionPanel(
                    compact: compact,
                    eyebrow: 'Frequency',
                    question: item?.prompt ?? '',
                    labels: labels,
                    selectedValue: selectedIndex != null && selectedIndex >= 0
                        ? selectedIndex
                        : null,
                    onSelected: (index) {
                      if (_inputsLocked) return;
                      if (plan == null ||
                          index < 0 ||
                          index >= plan.presentedOptionOrder.length) {
                        return;
                      }
                      _select(plan.presentedOptionOrder[index]);
                    },
                  ),
          ),
          if (retryable)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FrequencyContinueButton(
                label: 'Retry finalize',
                active: !_pipelineInFlight && _finalize?.isBusy != true,
                saving: _pipelineInFlight || _finalize?.isBusy == true,
                onPressed: () {
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
}
