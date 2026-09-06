import 'package:flutter/material.dart';

import 'qmatch_feedback.dart';

/// Compatibility entry for older call sites.
///
/// Routes through [QMatchFeedback] so the app has one transient surface.
void showElegantWarning(BuildContext context, String message) {
  QMatchFeedback.show(
    context,
    message: message,
    type: QMatchFeedbackType.warning,
    compact: true,
  );
}
