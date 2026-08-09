import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qmatch/core/theme/app_colors.dart';
import 'package:qmatch/features/profile/models/profile_read_result.dart';
import 'package:qmatch/features/profile/models/user_profile_model.dart';
import 'package:qmatch/features/profile/screens/profile_screen.dart';
import 'package:qmatch/l10n/app_localizations.dart';

Widget wrapProfileGolden({
  required Size surfaceSize,
  required Widget child,
  double textScale = 1.0,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.cosmicBlack,
      useMaterial3: true,
    ),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: MediaQuery(
      data: MediaQueryData(
        size: surfaceSize,
        padding: const EdgeInsets.only(bottom: 34),
        viewPadding: const EdgeInsets.only(bottom: 34),
        textScaler: TextScaler.linear(textScale),
        devicePixelRatio: 1,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cosmicBlack,
        body: SizedBox(
          width: surfaceSize.width,
          height: surfaceSize.height,
          child: child,
        ),
      ),
    ),
  );
}

/// Presentation scene for Profile goldens (synthetic data only).
class ProfileGoldenScene extends StatelessWidget {
  const ProfileGoldenScene({
    super.key,
    required this.profile,
    this.photoImageProvider,
    this.forceLoading = false,
    this.forceError = false,
  });

  final UserProfileModel? profile;
  final ImageProvider? photoImageProvider;
  final bool forceLoading;
  final bool forceError;

  @override
  Widget build(BuildContext context) {
    if (forceLoading) {
      return const ProfileScreen(
        debugForceLoading: true,
        animateBackground: false,
      );
    }
    if (forceError) {
      return const ProfileScreen(
        debugStatus: ProfileReadStatus.failed,
        animateBackground: false,
      );
    }
    return ProfileScreen(
      debugProfile: profile,
      photoImageProvider: photoImageProvider,
      animateBackground: false,
    );
  }
}
