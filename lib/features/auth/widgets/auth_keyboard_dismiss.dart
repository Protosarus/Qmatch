import 'package:flutter/material.dart';

/// Dismisses the software keyboard when the user taps outside the focused input.
class AuthKeyboardDismiss extends StatelessWidget {
  const AuthKeyboardDismiss({
    super.key,
    required this.child,
  });

  final Widget child;

  static void unfocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        final focus = FocusManager.instance.primaryFocus;
        if (focus == null || !focus.hasFocus || focus.context == null) {
          return;
        }
        final renderObject = focus.context!.findRenderObject();
        if (renderObject is! RenderBox || !renderObject.hasSize) {
          return;
        }
        final local = renderObject.globalToLocal(event.position);
        if (!(Offset.zero & renderObject.size).contains(local)) {
          focus.unfocus();
        }
      },
      child: child,
    );
  }
}

/// iOS-style keyboard accessory with a compact forward control (no action key on
/// the phone pad). Tap dismisses the keyboard; it does not send SMS.
class AuthKeyboardActionBar extends StatelessWidget {
  const AuthKeyboardActionBar({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  static const Key doneKey = Key('qmatch-phone-keyboard-done');

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2C2C2E),
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Tooltip(
              message: MaterialLocalizations.of(context).continueButtonLabel,
              child: InkWell(
                key: doneKey,
                onTap: onPressed,
                borderRadius: BorderRadius.circular(10),
                child: Ink(
                  width: 44,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDAC8ED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    key: Key('qmatch-phone-keyboard-forward'),
                    color: Color(0xFF1C1630),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
