import 'package:flutter/material.dart';

/// Shared post-auth navigation for phone and email sign-in.
///
/// The [MaterialApp] home [AuthWrapper] already listens to
/// [FirebaseAuth.authStateChanges]. After a successful credential, drop
/// login/OTP routes so that single wrapper is the only auth authority.
/// Never push another [AuthWrapper].
class AuthNavigation {
  AuthNavigation._();

  static void completeAuthentication(BuildContext context) {
    final navigator = Navigator.of(context);
    if (!navigator.canPop()) return;
    navigator.popUntil((route) => route.isFirst);
  }
}
