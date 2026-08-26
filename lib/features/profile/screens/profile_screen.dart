import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/cosmic/qmatch_cosmic_background.dart';
import '../../../l10n/app_localizations.dart';
import '../../iap/domain/entitlement_snapshot.dart';
import '../../assessment/screens/persona_lab_screen.dart';
import '../../assessment/services/persona_result_reader.dart';
import '../../assessment/utils/assessment_persona_reference_catalog.dart';
import '../../iap/services/entitlement_repository.dart';
import '../../relationship_analysis/domain/relationship_analysis_state.dart';
import '../../relationship_analysis/domain/relationship_dimensions.dart';
import '../../relationship_analysis/screens/relationship_analysis_micro_scan_screen.dart';
import '../../relationship_analysis/services/relationship_analysis_discovery.dart';
import '../../relationship_analysis/widgets/relationship_analysis_profile_card.dart';
import '../../settings/screens/settings_screen.dart';
import '../models/profile_read_result.dart';
import '../models/user_profile_model.dart';
import '../services/profile_service.dart';
import '../widgets/qmatch_profile_persona_card.dart';
import '../widgets/qmatch_profile_presentation.dart';
import 'membership_screen.dart';
import 'profile_anthem_edit_screen.dart';
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
    this.debugResonanceAccess,
    this.readResonanceAccess,
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

  /// Test override for trusted `resonance_access`. When set, Firestore is skipped.
  final bool? debugResonanceAccess;

  /// Test injection. Production reads `entitlements/{uid}.resonance_access`.
  final Future<bool> Function()? readResonanceAccess;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool get _showRelationshipAnalysisCard => false;
  late final ProfileService _profileService =
      widget.profileService ?? ProfileService();

  UserProfileModel? _profile;
  ProfileReadStatus _status = ProfileReadStatus.failed;
  bool _loading = true;
  bool _resonanceAccess = false;
  AssignedPersonaResult? _personaResult;
  RelationshipAnalysisState _relationshipState =
      RelationshipAnalysisState.empty();
  StreamSubscription<RelationshipAnalysisState>? _relationshipStateSubscription;

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
      _loadPersonaResult();
      _watchRelationshipAnalysis();
    }
    if (widget.debugResonanceAccess != null) {
      _resonanceAccess = widget.debugResonanceAccess == true;
    } else {
      _loadEntitlement();
    }
  }

  void _watchRelationshipAnalysis() {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim();
    if (uid == null || uid.isEmpty) return;

    _relationshipStateSubscription?.cancel();
    _relationshipStateSubscription =
        RelationshipAnalysisDiscovery.watchState(uid: uid).listen(
      (state) {
        if (!mounted) return;
        setState(() => _relationshipState = state);
      },
      onError: (_) {
        // Non-blocking: keep the last known Relationship Analysis state.
      },
    );
  }

  @override
  void dispose() {
    _relationshipStateSubscription?.cancel();
    super.dispose();
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

  bool get _skipLiveEntitlementRead =>
      widget.debugResonanceAccess == null &&
      widget.readResonanceAccess == null &&
      (widget.debugProfile != null ||
          widget.debugStatus != null ||
          widget.debugForceLoading);

  Future<void> _loadEntitlement() async {
    if (widget.debugResonanceAccess != null) {
      if (!mounted) return;
      setState(() => _resonanceAccess = widget.debugResonanceAccess == true);
      return;
    }
    if (_skipLiveEntitlementRead) return;
    try {
      final custom = widget.readResonanceAccess;
      if (custom != null) {
        final ok = await custom();
        if (!mounted) return;
        setState(() => _resonanceAccess = ok == true);
        return;
      }
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        if (!mounted) return;
        setState(() => _resonanceAccess = false);
        return;
      }
      final snap = await EntitlementRepository().fetch(uid);
      if (!mounted) return;
      setState(() => _resonanceAccess = snap.resonanceAccess == true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _resonanceAccess = false);
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    if (mounted) await _loadEntitlement();
  }

  EntitlementSnapshot get _membershipSnapshot => _resonanceAccess
      ? const EntitlementSnapshot(
          uid: '',
          tier: 'resonance',
          subscriptionState: 'active',
          resonanceAccess: true,
          superResonanceBalance: 0,
          boostBalance: 0,
        )
      : EntitlementSnapshot.free;

  bool get _skipMembershipFetch =>
      _skipLiveEntitlementRead ||
      widget.debugResonanceAccess != null ||
      widget.readResonanceAccess != null;

  bool get _showMembershipRow =>
      !_skipLiveEntitlementRead ||
      widget.debugResonanceAccess != null ||
      widget.readResonanceAccess != null;

  Future<void> _openMembership() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MembershipScreen(
          initialSnapshot: _membershipSnapshot,
          skipFetch: _skipMembershipFetch,
          animateBackground: widget.animateBackground,
        ),
      ),
    );
    if (mounted) await _loadEntitlement();
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

  Future<void> _loadPersonaResult() async {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim();
    if (uid == null || uid.isEmpty) return;

    try {
      final result = await PersonaResultReader().readForUid(uid);
      if (!mounted) return;
      setState(() => _personaResult = result);
    } catch (_) {
      if (!mounted) return;
      setState(() => _personaResult = null);
    }
  }

  Future<void> _openPersonaLab() async {
    final result = _personaResult;
    if (result == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonaLabScreen(
          primaryPersonaId: result.primaryPersonaId,
          secondaryPersonaId: result.secondaryPersonaId,
        ),
      ),
    );
  }

  Future<void> _openRelationshipAnalysis() async {
    if (_relationshipState.answeredCount >=
        RelationshipAnalysisContract.questionCount) {
      return;
    }
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const RelationshipAnalysisMicroScanScreen(),
      ),
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

  Future<void> _openAnthemEdit() async {
    final profile = _profile;
    if (profile == null) return;
    final updated = await Navigator.push<UserProfileModel>(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileAnthemEditScreen(profile: profile),
      ),
    );
    if (!mounted) return;
    if (updated != null) {
      setState(() {
        _profile = updated;
        _status = ProfileReadStatus.loaded;
      });
    } else if (widget.debugProfile == null) {
      await _loadProfile();
    }
  }

  Future<void> _openAnthemLink() async {
    final raw = _profile?.anthemExternalUrl?.trim() ?? '';
    if (raw.isEmpty) return;
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget? _buildPersonaCard() {
    final result = _personaResult;
    if (result == null) return null;

    final primary = assessmentPersonaReferenceCatalog[result.primaryPersonaId];
    final secondary =
        assessmentPersonaReferenceCatalog[result.secondaryPersonaId];

    if (primary == null || secondary == null) return null;

    final isTurkish =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'tr';

    return QMatchProfilePersonaCard(
      primaryTitle: isTurkish ? primary.titleTr : primary.titleEn,
      secondaryTitle: isTurkish ? secondary.titleTr : secondary.titleEn,
      personaAsset: primary.asset,
      sectionLabel: isTurkish ? 'PERSONA’N' : 'YOUR PERSONA',
      supportingLabel: isTurkish ? 'Destekleyen örüntü' : 'Supporting pattern',
      openLabel: isTurkish ? 'Persona Lab’i aç →' : 'Open Persona Lab →',
      onTap: _openPersonaLab,
    );
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
        onEditAnthem: widget.debugProfile != null ? () {} : _openAnthemEdit,
        onOpenAnthemLink: widget.debugProfile != null ? () {} : _openAnthemLink,
        personaCard: _buildPersonaCard(),
        relationshipAnalysisCard:
            widget.debugProfile != null || !_showRelationshipAnalysisCard
                ? null
                : RelationshipAnalysisProfileCard(
                    state: _relationshipState,
                    onDeepen: _openRelationshipAnalysis,
                  ),
        photoImageProvider: widget.photoImageProvider,
        bottomInset: bottomInset,
        showResonanceBadge: _resonanceAccess,
        resonanceBadgeSemanticLabel: l10n.profileResonanceBadgeSemantic,
        membershipLabel: !_showMembershipRow
            ? null
            : (_resonanceAccess
                ? l10n.profileMembershipResonanceActive
                : l10n.profileMembershipFree),
        onMembershipTap: _showMembershipRow ? _openMembership : null,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: QMatchCosmicBackground(
        key: const Key('qmatch-profile-cosmic'),
        seed: 7,
        starCount: 18,
        animate: widget.animateBackground,
        showAccentHalos: false,
        starfieldOpacity: 0.38,
        child: SafeArea(
          bottom: false,
          child: body,
        ),
      ),
    );
  }
}
