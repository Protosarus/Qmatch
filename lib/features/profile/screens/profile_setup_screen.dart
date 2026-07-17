import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/success_dialog.dart';
import '../../../core/widgets/elegant_warning.dart';
import '../../../core/navigation/auth_wrapper.dart';
import '../../../l10n/app_localizations.dart';
import '../models/user_profile_model.dart';
import '../services/profile_service.dart';
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
  String? _education;
  String _bio = '';
  List<String> _interests = [];
  String? _occupation;
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
      final name = _authService.currentUser?.displayName ?? '';

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

      await _profileService.saveProfile(profile);

      if (mounted) {
        final readyL10n = AppLocalizations.of(context)!;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => SuccessDialog(
            icon: '✨',
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                onPressed: _previousStep,
              )
            : null,
        title: Text(
          l10n.profileSetupTitle,
          style: GoogleFonts.playfairDisplay(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: List.generate(_totalSteps, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(
                      right: index < _totalSteps - 1 ? 8 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: index <= _currentStep
                          ? AppColors.primary
                          : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
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
                  onLocationChanged: (pos, text) => setState(() {
                    _location = pos;
                    _locationText = text;
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
                  drinking: _drinking,
                  smoking: _smoking,
                  pets: _pets,
                  children: _children,
                  religion: _religion,
                  animalLove: _animalLove,
                  onOccupationChanged: (value) =>
                      setState(() => _occupation = value),
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
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _currentStep < _totalSteps - 1
                      ? l10n.profileSetupContinue
                      : l10n.profileSetupComplete,
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
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
