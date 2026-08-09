import 'package:flutter/material.dart';

import '../../../core/widgets/cosmic/qmatch_cosmic_background.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/screens/settings_screen.dart';
import '../models/profile_read_result.dart';
import '../models/user_profile_model.dart';
import '../services/profile_service.dart';
import '../widgets/qmatch_profile_presentation.dart';
import 'profile_photo_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.profileService,
    this.debugProfile,
    this.debugStatus,
    this.debugForceLoading = false,
    this.photoImageProvider,
    this.animateBackground,
  });

  /// Optional override for tests (defaults to [ProfileService]).
  final ProfileService? profileService;

  /// Synthetic profile for golden / widget tests (skips Firestore).
  final UserProfileModel? debugProfile;

  /// When set without [debugProfile], forces missing/error presentation.
  final ProfileReadStatus? debugStatus;

  /// Forces the loading skeleton (tests / goldens).
  final bool debugForceLoading;

  /// Test-only photo provider (no network).
  final ImageProvider? photoImageProvider;

  /// Goldens / reduced-motion: freeze cosmic breathing when false.
  final bool? animateBackground;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileService _profileService =
      widget.profileService ?? ProfileService();

  UserProfileModel? _profile;
  ProfileReadStatus _status = ProfileReadStatus.failed;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.debugForceLoading) {
      _loading = true;
      return;
    }
    if (widget.debugProfile != null || widget.debugStatus != null) {
      _applyDebug();
    } else {
      _loadProfile();
    }
  }

  void _applyDebug() {
    if (widget.debugProfile != null) {
      _profile = widget.debugProfile;
      _status = ProfileReadStatus.loaded;
      _loading = false;
      return;
    }
    _profile = null;
    _status = widget.debugStatus ?? ProfileReadStatus.failed;
    _loading = false;
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final result = await _profileService.readOwnProfile();
    if (!mounted) return;
    setState(() {
      _profile = result.profile;
      _status = result.status;
      _loading = false;
    });
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  Future<void> _openPhotoEdit() async {
    final profile = _profile;
    if (profile == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePhotoEditScreen(profile: profile),
      ),
    );
    if (mounted && widget.debugProfile == null) {
      await _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    Widget body;
    if (_loading) {
      body = QMatchProfileLoadingView(
        title: l10n.profileTitle,
        settingsTooltip: l10n.navSettings,
        loadingLabel: l10n.profileLoading,
        onSettings: _openSettings,
      );
    } else if (_status == ProfileReadStatus.failed ||
        _status == ProfileReadStatus.unauthenticated) {
      body = QMatchProfileErrorView(
        title: l10n.profileTitle,
        settingsTooltip: l10n.navSettings,
        message: l10n.profileLoadFailed,
        retryLabel: l10n.retry,
        onSettings: _openSettings,
        onRetry: _loadProfile,
      );
    } else if (_profile == null) {
      body = QMatchProfileErrorView(
        title: l10n.profileTitle,
        settingsTooltip: l10n.navSettings,
        message: l10n.profileNotFound,
        retryLabel: l10n.retry,
        onSettings: _openSettings,
        onRetry: _loadProfile,
      );
    } else {
      body = QMatchProfileReadyView(
        profile: _profile!,
        title: l10n.profileTitle,
        settingsTooltip: l10n.navSettings,
        missingPhotoLabel: l10n.profileMissingPhoto,
        editPhotoSemanticLabel: l10n.profileEditPhotoSemantic,
        onSettings: _openSettings,
        onPhotoTap: widget.debugProfile != null ? () {} : _openPhotoEdit,
        photoImageProvider: widget.photoImageProvider,
        bottomInset: bottomInset,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: QMatchCosmicBackground(
        key: const Key('qmatch-profile-cosmic'),
        seed: 7,
        starCount: 18,
        animate: widget.animateBackground,
        child: SafeArea(
          bottom: false,
          child: body,
        ),
      ),
    );
  }
}
