import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/identity/identity.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';
import '../../../core/widgets/qmatch_glass_icon_button.dart';
import '../../../l10n/app_localizations.dart';
import '../models/user_profile_model.dart';
import '../utils/profile_option_labels.dart';

/// Compact Profile title + Settings action (44×44 tap target).
class QMatchProfileHeader extends StatelessWidget {
  const QMatchProfileHeader({
    super.key,
    required this.title,
    required this.settingsTooltip,
    required this.onSettings,
  });

  final String title;
  final String settingsTooltip;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('qmatch-profile-header'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.playfairDisplay(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ),
          QMatchGlassIconButton(
            key: const Key('qmatch-profile-settings'),
            icon: Icons.settings_outlined,
            iconSize: 22,
            tooltip: settingsTooltip,
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

/// Photo + identity + optional location meta. Presentation only.
class QMatchProfileIdentityCard extends StatelessWidget {
  const QMatchProfileIdentityCard({
    super.key,
    required this.profile,
    required this.missingPhotoLabel,
    required this.editPhotoSemanticLabel,
    this.onPhotoTap,
    this.photoImageProvider,
  });

  final UserProfileModel profile;
  final String missingPhotoLabel;
  final String editPhotoSemanticLabel;
  final VoidCallback? onPhotoTap;
  final ImageProvider? photoImageProvider;

  @override
  Widget build(BuildContext context) {
    final identity = UserIdentityResolver.formatNameAndAge(
      displayName: profile.name,
      age: profile.age > 0 ? profile.age : null,
    );
    final location = profile.locationText?.trim();
    final hasLocation = location != null && location.isNotEmpty;
    final photoUrl = profile.profilePhotoUrl?.trim();
    final hasPhoto = (photoImageProvider != null) ||
        (photoUrl != null && photoUrl.isNotEmpty);

    return QGlassCard(
      key: const Key('qmatch-profile-identity-card'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Semantics(
            button: onPhotoTap != null,
            label: editPhotoSemanticLabel,
            child: GestureDetector(
              onTap: onPhotoTap,
              child: SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: hasPhoto
                            ? Image(
                                key: const Key('qmatch-profile-photo'),
                                image: photoImageProvider ??
                                    NetworkImage(photoUrl!),
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                                errorBuilder: (_, __, ___) =>
                                    _ProfilePhotoPlaceholder(
                                  label: missingPhotoLabel,
                                ),
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const _ProfilePhotoPlaceholder(
                                    showSpinner: true,
                                  );
                                },
                              )
                            : _ProfilePhotoPlaceholder(
                                key: const Key('qmatch-profile-photo-missing'),
                                label: missingPhotoLabel,
                              ),
                      ),
                    ),
                    if (onPhotoTap != null)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: QMatchGlassIconButton(
                          key: const Key('qmatch-profile-photo-edit'),
                          icon: Icons.camera_alt_outlined,
                          circular: true,
                          size: 44,
                          iconSize: 20,
                          semanticLabel: editPhotoSemanticLabel,
                          onPressed: onPhotoTap,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (identity != null && identity.isNotEmpty)
            Text(
              key: const Key('qmatch-profile-identity'),
              identity,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          if (hasLocation) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              key: const Key('qmatch-profile-location'),
              location,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfilePhotoPlaceholder extends StatelessWidget {
  const _ProfilePhotoPlaceholder({
    super.key,
    this.label,
    this.showSpinner = false,
  });

  final String? label;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceElevated,
      child: Center(
        child: showSpinner
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.softGold,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 40,
                    color: AppColors.textMuted,
                  ),
                  if (label != null && label!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        label!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// About / interests / compact attribute rows.
class QMatchProfileInfoSections extends StatelessWidget {
  const QMatchProfileInfoSections({
    super.key,
    required this.profile,
  });

  final UserProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bio = profile.bio.trim();
    final interests = profile.interests
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    final rows = _infoRows(l10n, profile);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rows.isNotEmpty) ...[
          QMatchProfileSectionCard(
            key: const Key('qmatch-profile-info-section'),
            title: l10n.profileDetailsSection,
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  _InfoRow(label: rows[i].$1, value: rows[i].$2),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        QMatchProfileSectionCard(
          key: const Key('qmatch-profile-about-section'),
          title: l10n.profileAboutMe,
          child: bio.isEmpty
              ? QMatchProfileEmptySection(
                  key: const Key('qmatch-profile-about-empty'),
                  message: l10n.profileNoBioYet,
                )
              : Text(
                  key: const Key('qmatch-profile-bio'),
                  bio,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        QMatchProfileSectionCard(
          key: const Key('qmatch-profile-interests-section'),
          title: l10n.profileInterests,
          child: interests.isEmpty
              ? QMatchProfileEmptySection(
                  key: const Key('qmatch-profile-interests-empty'),
                  message: l10n.profileNoInterestsYet,
                )
              : Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final interest in interests)
                      QMatchProfileInterestChip(
                        label: ProfileOptionLabels.interest(l10n, interest),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  static List<(String, String)> _infoRows(
    AppLocalizations l10n,
    UserProfileModel profile,
  ) {
    final out = <(String, String)>[];
    void add(String label, String? raw) {
      final v = (raw ?? '').trim();
      if (v.isEmpty) return;
      final localized = ProfileOptionLabels.label(l10n, v);
      final display = localized.isNotEmpty ? localized : v;
      out.add((label, display));
    }

    add(l10n.profileFieldGender, profile.gender);
    add(l10n.profileFieldEducation, profile.education);
    add(l10n.profileFieldLookingFor, profile.lookingFor);
    final occupation = profile.occupation?.trim();
    if (occupation != null && occupation.isNotEmpty) {
      out.add((l10n.profileFieldOccupation, occupation));
    }
    add(l10n.profileFieldDrinking, profile.drinking);
    add(l10n.profileFieldSmoking, profile.smoking);
    return out;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class QMatchProfileSectionCard extends StatelessWidget {
  const QMatchProfileSectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return QGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.softGold,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class QMatchProfileInterestChip extends StatelessWidget {
  const QMatchProfileInterestChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('qmatch-profile-interest-chip'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.resonanceViolet.withValues(alpha: 0.18),
        borderRadius: AppRadii.pillBorder,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class QMatchProfileEmptySection extends StatelessWidget {
  const QMatchProfileEmptySection({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: GoogleFonts.inter(
        color: AppColors.textMuted,
        fontSize: 14,
        height: 1.4,
      ),
    );
  }
}

/// Layout-shaped loading skeleton (no fake user text).
class QMatchProfileLoadingView extends StatefulWidget {
  const QMatchProfileLoadingView({
    super.key,
    required this.title,
    required this.settingsTooltip,
    required this.loadingLabel,
    required this.onSettings,
  });

  final String title;
  final String settingsTooltip;
  final String loadingLabel;
  final VoidCallback onSettings;

  @override
  State<QMatchProfileLoadingView> createState() =>
      _QMatchProfileLoadingViewState();
}

class _QMatchProfileLoadingViewState extends State<QMatchProfileLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 0.75).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('qmatch-profile-loading'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QMatchProfileHeader(
          title: widget.title,
          settingsTooltip: widget.settingsTooltip,
          onSettings: widget.onSettings,
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: _opacity,
            builder: (context, _) {
              return Opacity(
                opacity: _opacity.value,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  children: [
                    QGlassCard(
                      emphasized: true,
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceElevated,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _bone(width: 160, height: 22),
                          const SizedBox(height: AppSpacing.xs),
                          _bone(width: 100, height: 14),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    QGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _bone(width: 88, height: 16),
                          const SizedBox(height: AppSpacing.sm),
                          _bone(height: 12),
                          const SizedBox(height: AppSpacing.xs),
                          _bone(width: 220, height: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Semantics(
                      liveRegion: true,
                      label: widget.loadingLabel,
                      child: Text(
                        widget.loadingLabel,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _bone({double? width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
    );
  }
}

class QMatchProfileErrorView extends StatelessWidget {
  const QMatchProfileErrorView({
    super.key,
    required this.title,
    required this.settingsTooltip,
    required this.message,
    required this.retryLabel,
    required this.onSettings,
    required this.onRetry,
  });

  final String title;
  final String settingsTooltip;
  final String message;
  final String retryLabel;
  final VoidCallback onSettings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('qmatch-profile-error'),
      children: [
        QMatchProfileHeader(
          title: title,
          settingsTooltip: settingsTooltip,
          onSettings: onSettings,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: QGlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      color: AppColors.textMuted,
                      size: 36,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      key: const Key('qmatch-profile-retry'),
                      onPressed: onRetry,
                      child: Text(
                        retryLabel,
                        style: GoogleFonts.inter(
                          color: AppColors.softGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Full ready-state Profile body (synthetic-data friendly for goldens).
class QMatchProfileReadyView extends StatelessWidget {
  const QMatchProfileReadyView({
    super.key,
    required this.profile,
    required this.title,
    required this.settingsTooltip,
    required this.missingPhotoLabel,
    required this.editPhotoSemanticLabel,
    required this.onSettings,
    this.onPhotoTap,
    this.photoImageProvider,
    this.bottomInset = 0,
  });

  final UserProfileModel profile;
  final String title;
  final String settingsTooltip;
  final String missingPhotoLabel;
  final String editPhotoSemanticLabel;
  final VoidCallback onSettings;
  final VoidCallback? onPhotoTap;
  final ImageProvider? photoImageProvider;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('qmatch-profile-ready'),
      children: [
        QMatchProfileHeader(
          title: title,
          settingsTooltip: settingsTooltip,
          onSettings: onSettings,
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl + bottomInset,
            ),
            children: [
              QMatchProfileIdentityCard(
                profile: profile,
                missingPhotoLabel: missingPhotoLabel,
                editPhotoSemanticLabel: editPhotoSemanticLabel,
                onPhotoTap: onPhotoTap,
                photoImageProvider: photoImageProvider,
              ),
              const SizedBox(height: AppSpacing.md),
              QMatchProfileInfoSections(profile: profile),
            ],
          ),
        ),
      ],
    );
  }
}
