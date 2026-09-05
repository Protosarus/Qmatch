import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/notifications/message_push_tap_host.dart';
import '../../../core/notifications/notification_registration_host.dart';
import '../../../l10n/app_localizations.dart';
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
    this.onInternalContinue,
    this.selectionHold = selectionHoldDuration,
  });

  final FrequencyV2SessionController? controller;
  final FrequencyV2AssetRuntime? assetRuntime;
  final FrequencyV2PendingFinalizationPipeline? pendingPipeline;
  final FirebaseAuth? auth;
  final VoidCallback? onLocked;

  /// Test hook. Production uses [exitInternalCompletion].
  final VoidCallback? onInternalContinue;

  /// Visible confirmation before the session advances. Tests may shorten it.
  final Duration selectionHold;

  static const Duration selectionHoldDuration = Duration(milliseconds: 350);

  static const String internalCompletionTitle =
      'Frequency V2 internal test completed';

  static const Key internalContinueKey = Key('frequency-v2-internal-continue');

  /// Leaves the internal V2 test without writing completion flags, Persona,
  /// or Discover eligibility.
  ///
  /// Pushed routes (intro / debug home): one [Navigator.pop].
  /// Root / cold-start (this screen is the assessment-gate child): push the
  /// existing main shell so AuthWrapper stays mounted. V2 finalize does not
  /// bump [AuthRoutingRefresh], so the gate will not immediately re-open
  /// Frequency.
  static void exitInternalCompletion(BuildContext context) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationRegistrationHost(
          child: MessagePushTapHost(),
        ),
      ),
    );
  }

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
      setState(() {
        _heldOptionIndex = null;
      });
      if (controller.session?.status ==
          FrequencyV2PersistedSessionStatus.completedPendingPersistence) {
        widget.onLocked?.call();
        await _runPendingFinalizationPipeline();
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _heldOptionIndex = null;
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

  void _onInternalContinue() {
    if (widget.onInternalContinue != null) {
      widget.onInternalContinue!();
      return;
    }
    FrequencyV2TestScreen.exitInternalCompletion(context);
  }

  bool get _inputsLocked =>
      _isFinishing ||
      _busy ||
      _pipelineInFlight ||
      _showDormantCompletion ||
      _heldOptionIndex != null ||
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
    final visualIndex = _heldOptionIndex ??
        (selectedIndex != null && selectedIndex >= 0 ? selectedIndex : null);
    final compact = MediaQuery.sizeOf(context).height < 700;
    final statusLine = _uiErrorCode ?? _loadError;
    final retryable = _uiErrorCode != null &&
        !_showDormantCompletion &&
        controller?.session?.status ==
            FrequencyV2PersistedSessionStatus.completedPendingPersistence;
    final l10n = AppLocalizations.of(context);

    return QAssessmentScaffold(
      richBackdrop: true,
      backgroundImageAsset: 'assets/images/welcome_cosmic_background.png',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FrequencyQuestionTopBar(),
          if (statusLine != null)
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
                ? _InternalCompletionPane(
                    title: FrequencyV2TestScreen.internalCompletionTitle,
                    continueLabel: l10n?.assessmentContinue ?? 'Continue',
                    onContinue: _onInternalContinue,
                  )
                : FrequencyQuestionPanel(
                    compact: compact,
                    eyebrow: 'Frequency',
                    question: item?.prompt ?? '',
                    labels: labels,
                    selectedValue: visualIndex != null ? visualIndex + 1 : null,
                    onSelected: _onPanelSelected,
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

class _InternalCompletionPane extends StatelessWidget {
  const _InternalCompletionPane({
    required this.title,
    required this.continueLabel,
    required this.onContinue,
  });

  final String title;
  final String continueLabel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(child: FrequencyWaveHero()),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Internal debug result only. Discover, Persona, and V1 Frequency '
          'were not written.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 13,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        FrequencyContinueButton(
          key: FrequencyV2TestScreen.internalContinueKey,
          label: continueLabel,
          active: true,
          onPressed: onContinue,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
