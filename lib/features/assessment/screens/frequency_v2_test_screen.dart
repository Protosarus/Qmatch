import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/frequency_v2_runtime/frequency_v2_runtime.dart';
import '../utils/assessment_language.dart';
import '../widgets/frequency_question_chrome.dart';
import '../widgets/q_assessment_progress.dart';
import '../widgets/q_assessment_scaffold.dart';

/// Dormant Frequency V2 question UI. Not selected by live routing while
/// [FrequencyRuntimeSelectionPolicy] resolves to V1.
///
/// When no [controller] is injected, the screen loads reviewed TR/EN banks
/// from the Flutter asset bundle rather than developer `tool/` paths.
class FrequencyV2TestScreen extends StatefulWidget {
  const FrequencyV2TestScreen({
    super.key,
    this.controller,
    this.assetRuntime,
    this.auth,
    this.onLocked,
  });

  final FrequencyV2SessionController? controller;
  final FrequencyV2AssetRuntime? assetRuntime;
  final FirebaseAuth? auth;
  final VoidCallback? onLocked;

  @override
  State<FrequencyV2TestScreen> createState() => _FrequencyV2TestScreenState();
}

class _FrequencyV2TestScreenState extends State<FrequencyV2TestScreen> {
  FrequencyV2SessionController? _owned;
  bool _didStartLoading = false;
  String? _loadError;

  FrequencyV2SessionController? get _controller => widget.controller ?? _owned;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.controller != null || _didStartLoading) return;
    _didStartLoading = true;
    _bootstrapFromAssets();
  }

  Future<void> _bootstrapFromAssets() async {
    try {
      final uid = (widget.auth ?? FirebaseAuth.instance).currentUser?.uid;
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
      setState(() => _owned = controller);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error.toString());
    }
  }

  Future<void> _select(String optionId) async {
    final controller = _controller;
    if (controller == null) return;
    await controller.selectOption(optionId);
    await controller.lockIfComplete();
    if (!mounted) return;
    setState(() {});
    if (controller.session?.status ==
        FrequencyV2PersistedSessionStatus.completedPendingPersistence) {
      widget.onLocked?.call();
    }
  }

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

    return QAssessmentScaffold(
      richBackdrop: true,
      backgroundImageAsset: 'assets/images/welcome_cosmic_background.png',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FrequencyQuestionTopBar(),
          Text(
            _loadError ?? locale,
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
            child: FrequencyQuestionPanel(
              compact: compact,
              eyebrow: 'Frequency',
              question: item?.prompt ?? '',
              labels: labels,
              selectedValue: selectedIndex != null && selectedIndex >= 0
                  ? selectedIndex
                  : null,
              onSelected: (index) {
                if (plan == null ||
                    index < 0 ||
                    index >= plan.presentedOptionOrder.length) {
                  return;
                }
                _select(plan.presentedOptionOrder[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
