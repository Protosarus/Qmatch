import 'package:flutter/material.dart';

import '../services/ios_iap_session.dart';

/// Binds [IosIapSession] to an authenticated widget subtree.
///
/// Insert only after Firebase Auth has a user. Dispose (sign-out) detaches
/// the StoreKit listener.
class IosIapSessionHost extends StatefulWidget {
  const IosIapSessionHost({
    super.key,
    required this.child,
    this.session,
  });

  final Widget child;
  final IosIapSession? session;

  @override
  State<IosIapSessionHost> createState() => _IosIapSessionHostState();
}

class _IosIapSessionHostState extends State<IosIapSessionHost> {
  IosIapSession get _session => widget.session ?? IosIapSession.instance;

  @override
  void initState() {
    super.initState();
    _session.attach();
  }

  @override
  void dispose() {
    _session.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
