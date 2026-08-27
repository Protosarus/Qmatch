import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DebugAccess {
  DebugAccess._();

  static const String ownerEmail = 'protosarus@gmail.com';

  static bool get isAllowed {
    if (!kDebugMode) return false;

    try {
      final email =
          FirebaseAuth.instance.currentUser?.email?.trim().toLowerCase();
      return email == ownerEmail;
    } catch (_) {
      return false;
    }
  }
}

class DebugAccessDeniedScreen extends StatelessWidget {
  const DebugAccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Debug access unavailable.'),
      ),
    );
  }
}
