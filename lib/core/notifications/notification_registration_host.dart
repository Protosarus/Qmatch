import 'package:flutter/material.dart';

import 'notification_registration_service.dart';

/// Starts FCM permission + token registration after the main app is ready.
///
/// Place only around the authenticated main shell — not splash or login.
class NotificationRegistrationHost extends StatefulWidget {
  const NotificationRegistrationHost({
    super.key,
    required this.child,
    this.service,
  });

  final Widget child;
  final NotificationRegistrationService? service;

  @override
  State<NotificationRegistrationHost> createState() =>
      _NotificationRegistrationHostState();
}

class _NotificationRegistrationHostState
    extends State<NotificationRegistrationHost> {
  NotificationRegistrationService get _service =>
      widget.service ?? NotificationRegistrationService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _service.startAfterAuthenticatedAppReady();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
