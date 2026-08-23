import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/qmatch_glass_icon_button.dart';
import '../../../core/widgets/success_dialog.dart';
import '../../../core/widgets/elegant_warning.dart';
import '../../../core/navigation/auth_wrapper.dart';
import '../../../l10n/app_localizations.dart';
import '../../assessment/widgets/frequency_question_chrome.dart';
import '../../assessment/widgets/q_assessment_scaffold.dart';
import '../domain/home_geography.dart';
import '../models/user_profile_model.dart';
import '../services/display_name_service.dart';
import '../services/profile_service.dart';
import '../widgets/profile_setup_chrome.dart';
import 'steps/basic_info_step.dart';
import 'steps/bio_step.dart';
import 'steps/interests_step.dart';
import 'steps/lifestyle_step.dart';
import 'steps/preferences_step.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();

  int _currentStep = 0;
  final int _totalSteps = 5;

  // Profil verileri
  int? _age;
  String? _gender;
  Position? _location;
  String? _locationText;
  HomeGeography? _homeGeography;
  String? _education;
  String _bio = '';
  List<String> _interests = [];
  String? _occupation;
  String? _company;
  String? _school;
  String? _educationField;
  String? _drinking;
  String? _smoking;
  String? _pets;
  String? _children;
  String? _religion;
  String? _animalLove;
  String? _lookingFor;
  List<int> _ageRange = [25, 35];
  int _distancePreference = 50;

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _saveProfile();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context)!;
    // Detaylı validation - Konum artık opsiyonel
    List<String> missingFields = [];

    if (_age == null) missingFields.add(l10n.profileFieldAge);
    if (_gender == null) missingFields.add(l10n.profileFieldGender);
    if (_education == null) missingFields.add(l10n.profileFieldEducation);
    if (_bio.trim().isEmpty) missingFields.add(l10n.profileFieldBio);
    if (_lookingFor == null) missingFields.add(l10n.profileFieldLookingFor);

    if (missingFields.isNotEmpty) {
      showElegantWarning(
        context,
        l10n.profileSetupPleaseComplete(missingFields.join(', ')),
      );

      // İlk eksik alana git
      if (_age == null || _gender == null || _education == null) {
        _pageController.jumpToPage(0);
        setState(() => _currentStep = 0);
      } else if (_bio.trim().isEmpty) {
        _pageController.jumpToPage(1);
        setState(() => _currentStep = 1);
      } else if (_lookingFor == null) {
        _pageController.jumpToPage(4);
        setState(() => _currentStep = 4);
      }

      return;
    }

    try {
      final userId = _authService.currentUser?.uid ?? '';
      // Preserve canonical Firestore display name; do not overwrite with Auth.
      final name =
          await DisplayNameService().readCanonicalDisplayName(userId) ?? '';

      final profile = UserProfileModel(
        userId: userId,
        name: name,
        age: _age!,
        gender: _gender!,
        location: _location != null
            ? UserProfileModel.fromPosition(_location!)
            : null,
        locationText: _locationText,
        education: _education!,
        bio: _bio.trim(),
        interests: _interests,
        occupation: _occupation,
        company: _company,
        school: _school,
        educationField: _educationField,
        drinking: _drinking,
        smoking: _smoking,
        pets: _pets,
        children: _children,
        religion: _religion,
        animalLove: _animalLove,
        lookingFor: _lookingFor!,
        ageRange: _ageRange,
        distancePreference: _distancePreference,
        profileCompleted: true,
        completedAt: DateTime.now(),
      );

      await _profileService.saveProfile(
        profile,
        homeGeography: _homeGeography,
      );

      if (mounted) {
        final readyL10n = AppLocalizations.of(context)!;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => SuccessDialog(
            title: readyL10n.profileSetupReadyTitle,
            message: readyL10n.profileSetupReadyMessage,
            onContinue: () {
              // Route through AuthWrapper so gating stays consistent.
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthWrapper()),
                (route) => false,
              );
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showElegantWarning(
          context,
          AppLocalizations.of(context)!.profileSetupErrorGeneric(e.toString()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return QAssessmentScaffold(
      richBackdrop: true,
      backgroundImageAsset: ProfileSetupChrome.cosmicBackgroundAsset,
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                if (_currentStep > 0)
                  QMatchGlassIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: _previousStep,
                    size: 40,
                    iconSize: 18,
                    circular: true,
                    semanticLabel:
                        MaterialLocalizations.of(context).backButtonTooltip,
                  )
                else
                  const SizedBox(width: 40),
                Expanded(
                  child: Text(
                    l10n.profileSetupTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          FrequencyProgressHeader(
            label:
                '${l10n.profileSetupTitle} · ${_currentStep + 1} / $_totalSteps',
            progress: (_currentStep + 1) / _totalSteps,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                BasicInfoStep(
                  age: _age,
                  gender: _gender,
                  location: _location,
                  locationText: _locationText,
                  education: _education,
                  onAgeChanged: (value) => setState(() => _age = value),
                  onGenderChanged: (value) => setState(() => _gender = value),
                  onLocationChanged: (pos, text, home) => setState(() {
                    _location = pos;
                    _locationText = text;
                    _homeGeography = home;
                  }),
                  onEducationChanged: (value) =>
                      setState(() => _education = value),
                ),
                BioStep(
                  bio: _bio,
                  onBioChanged: (value) => setState(() => _bio = value),
                ),
                InterestsStep(
                  interests: _interests,
                  onInterestsChanged: (value) =>
                      setState(() => _interests = value),
                ),
                LifestyleStep(
                  occupation: _occupation,
                  company: _company,
                  school: _school,
                  educationField: _educationField,
                  drinking: _drinking,
                  smoking: _smoking,
                  pets: _pets,
                  children: _children,
                  religion: _religion,
                  animalLove: _animalLove,
                  onOccupationChanged: (value) =>
                      setState(() => _occupation = value),
                  onCompanyChanged: (value) => setState(() => _company = value),
                  onSchoolChanged: (value) => setState(() => _school = value),
                  onEducationFieldChanged: (value) =>
                      setState(() => _educationField = value),
                  onDrinkingChanged: (value) =>
                      setState(() => _drinking = value),
                  onSmokingChanged: (value) => setState(() => _smoking = value),
                  onPetsChanged: (value) => setState(() => _pets = value),
                  onChildrenChanged: (value) =>
                      setState(() => _children = value),
                  onReligionChanged: (value) =>
                      setState(() => _religion = value),
                  onAnimalLoveChanged: (value) =>
                      setState(() => _animalLove = value),
                ),
                PreferencesStep(
                  lookingFor: _lookingFor,
                  ageRange: _ageRange,
                  distancePreference: _distancePreference,
                  onLookingForChanged: (value) =>
                      setState(() => _lookingFor = value),
                  onAgeRangeChanged: (value) =>
                      setState(() => _ageRange = value),
                  onDistanceChanged: (value) =>
                      setState(() => _distancePreference = value),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
            child: FrequencyContinueButton(
              key: const Key('qmatch-profile-setup-continue'),
              // Same widget as Frequency CTA; active mirrors enabled (always).
              label: _currentStep < _totalSteps - 1
                  ? l10n.assessmentContinue
                  : l10n.profileSetupComplete,
              onPressed: _nextStep,
              active: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
