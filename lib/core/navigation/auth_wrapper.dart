import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/assessment/screens/frequency_intro_screen.dart';
import '../../features/assessment/screens/iq_test_intro_screen.dart';
import '../../features/profile/screens/profile_setup_screen.dart';
import '../services/auth_service.dart';
import 'main_navigation_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0C0C0C),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE3C565)),
              ),
            ),
          );
        }

        // Kullanıcı giriş yapmamış
        if (!snapshot.hasData || snapshot.data == null) {
          return const WelcomeScreen();
        }

        final user = snapshot.data!;

        // Ensure a user doc exists, then route based on completion flags.
        return FutureBuilder<void>(
          future: AuthService().ensureUserDocumentExists(),
          builder: (context, ensureSnap) {
            // Loading
            if (ensureSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF0C0C0C),
                body: Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFE3C565)),
                  ),
                ),
              );
            }

            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(),
              builder: (context, userSnapshot) {
                // Loading
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    backgroundColor: Color(0xFF0C0C0C),
                    body: Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFE3C565)),
                      ),
                    ),
                  );
                }

                // If user doc is still missing for any reason, route safely to setup.
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const ProfileSetupScreen();
                }

                final userData = userSnapshot.data!.data() ?? <String, dynamic>{};
                final testCompleted = userData['test_completed'] as bool? ?? false;
                final frequencyCompleted =
                    userData['frequency_completed'] as bool? ?? false;
                final profileCompleted =
                    userData['profile_completed'] as bool? ?? false;

                // Tests not completed -> IQ intro flow.
                if (!testCompleted) {
                  return const IQTestIntroScreen();
                }

                // Frequency not completed -> Frequency intro flow.
                if (!frequencyCompleted) {
                  return const FrequencyIntroScreen();
                }

                // Profile not completed -> profile setup.
                if (!profileCompleted) {
                  return const ProfileSetupScreen();
                }

                // Everything complete -> main app.
                return const MainNavigationScreen();
              },
            );
          },
        );
      },
    );
  }
}
