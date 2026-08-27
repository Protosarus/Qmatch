import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'core/debug/debug_access.dart';
import 'core/navigation/auth_wrapper.dart';
import 'core/theme/app_theme.dart';
import 'features/debug/debug_home_screen.dart';
import 'features/debug/screens/assessment_admin_screen.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inter / Playfair are bundled under test/fonts/google_fonts/.
  // First paint must not wait on fonts.google.com.
  GoogleFonts.config.allowRuntimeFetching = false;
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
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Global app: en/tr as supported; everything else falls back to English.
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('en');
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) {
            return supported;
          }
        }
        return const Locale('en');
      },
      home: const AuthWrapper(),
      // Debug-only routes — not registered in release/profile.
      routes: {
        if (kDebugMode) ...{
          DebugHomeScreen.routeName: (_) => DebugAccess.isAllowed
              ? const DebugHomeScreen()
              : const DebugAccessDeniedScreen(),
          AssessmentAdminScreen.routeName: (_) => DebugAccess.isAllowed
              ? const AssessmentAdminScreen()
              : const DebugAccessDeniedScreen(),
        },
      },
    );
  }
}
