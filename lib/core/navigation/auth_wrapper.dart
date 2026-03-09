import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/profile/screens/profile_setup_screen.dart';
import '../../features/assessment/screens/iq_test_screen.dart';
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

        // Kullanıcı durumunu kontrol et
        return FutureBuilder<DocumentSnapshot>(
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

            // Kullanıcı verisi yok - setup'a yönlendir
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const ProfileSetupScreen();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final testCompleted = userData['test_completed'] ?? false;
            final profileCompleted = userData['profile_completed'] ?? false;

            // Test tamamlanmamış - Test ekranına
            if (!testCompleted) {
              return const IQTestScreen();
            }

            // Profil tamamlanmamış - Profil setup'a
            if (!profileCompleted) {
              return const ProfileSetupScreen();
            }

            // Her şey tamam - Ana uygulamaya
            return const MainNavigationScreen();
          },
        );
      },
    );
  }
}
