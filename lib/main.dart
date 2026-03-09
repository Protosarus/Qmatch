import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/main/screens/main_app_screen.dart';
import 'core/navigation/auth_wrapper.dart';
import 'core/utils/upload_questions_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QMatch',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFFE8D978),
      ),
      // AuthWrapper kullanıcı durumuna göre yönlendirir
      home: kDebugMode ? const DebugHomeScreen() : const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DebugHomeScreen extends StatelessWidget {
  const DebugHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🔧 DEBUG MODE',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 40),
            
            // Upload Questions butonu
            ElevatedButton(
              onPressed: () async {
                try {
                  await UploadQuestionsHelper.uploadAllQuestions();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Questions uploaded!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: Text(
                '📤 Upload Questions to Firebase',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // AuthWrapper'a git
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AuthWrapper()),
                );
              },
              child: const Text('🔐 Go to Auth Wrapper'),
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                );
              },
              child: const Text('Go to Welcome Screen'),
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MainAppScreen()),
                );
              },
              child: const Text('Go to Main App Screen'),
            ),
          ],
        ),
      ),
    );
  }
}
