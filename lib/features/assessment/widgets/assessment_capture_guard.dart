import 'dart:async';

import 'package:flutter/material.dart';

import '../services/assessment_capture_protection.dart';

/// Locks route pop and applies capture/privacy overlay for active questions.
///
/// Enables [AssessmentCaptureProtection] for the widget lifetime (ref-counted).
class AssessmentCaptureGuard extends StatefulWidget {
  const AssessmentCaptureGuard({
    super.key,
    required this.child,
    this.lockRoutePop = true,
  });

  final Widget child;
  final bool lockRoutePop;

  @override
  State<AssessmentCaptureGuard> createState() => _AssessmentCaptureGuardState();
}

class _AssessmentCaptureGuardState extends State<AssessmentCaptureGuard>
    with WidgetsBindingObserver {
  bool _obscure = false;
  StreamSubscription<bool>? _obscureSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final protection = AssessmentCaptureProtection.active;
    _obscureSub = protection.obscureStream.listen((value) {
      if (!mounted) return;
      setState(() => _obscure = value);
    });
    unawaited(_enable(protection));
  }

  Future<void> _enable(AssessmentCaptureProtection protection) async {
    await protection.enable();
    if (!mounted) return;
    setState(() => _obscure = protection.shouldObscure);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final inactive = state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden;
    AssessmentCaptureProtection.active.setAppInactive(inactive);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _obscureSub?.cancel();
    unawaited(AssessmentCaptureProtection.active.disable());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_obscure)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0xFF05070E),
              child: SizedBox.expand(),
            ),
          ),
      ],
    );

    if (!widget.lockRoutePop) return body;
    return PopScope(
      canPop: false,
      child: body,
    );
  }
}
