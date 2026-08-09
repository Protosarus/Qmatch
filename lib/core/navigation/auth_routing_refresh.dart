import 'package:flutter/foundation.dart';

/// Bumps so [AuthWrapper] re-resolves display-name / assessment routing.
class AuthRoutingRefresh {
  AuthRoutingRefresh._();

  static final ValueNotifier<int> tick = ValueNotifier<int>(0);

  static void bump() => tick.value++;
}
