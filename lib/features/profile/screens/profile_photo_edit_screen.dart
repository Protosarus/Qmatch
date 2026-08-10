import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';
import '../../../core/widgets/cosmic/qmatch_cosmic_background.dart';
import '../../../core/widgets/elegant_warning.dart';
import '../../../core/widgets/qmatch_primary_action.dart';
import '../../../core/widgets/qmatch_pushed_screen_header.dart';
import '../../../l10n/app_localizations.dart';
import '../models/user_profile_model.dart';
import '../services/photo_upload_service.dart';
import '../services/profile_service.dart';

/// Maximum photos supported by the existing upload/save pipeline.
const int kProfilePhotoMaxCount = 9;

class ProfilePhotoEditScreen extends StatefulWidget {
  const ProfilePhotoEditScreen({
    super.key,
    required this.profile,
    this.photoUploadService,
    this.profileService,
    this.animateBackground,
    this.debugPhotos,
    this.debugUploading = false,
    this.photoImageProviders,
    this.debugPickPhotos,
    this.debugSaveProfile,
  });

  final UserProfileModel profile;

  final PhotoUploadService? photoUploadService;
  final ProfileService? profileService;

  /// Goldens: freeze cosmic animation.
  final bool? animateBackground;

  /// Synthetic photo URL list for tests (skips initial profile copy when set).
  final List<String>? debugPhotos;

  /// Forces uploading UI in tests.
  final bool debugUploading;

  /// Optional deterministic image providers keyed by index (goldens).
  final Map<int, ImageProvider>? photoImageProviders;

  /// Test-only pick override to avoid touching picker / Firebase upload runtime.
  final Future<List<String>> Function(int maxImages)? debugPickPhotos;

  /// Test-only save override to avoid touching Firestore runtime.
  final Future<void> Function(UserProfileModel profile)? debugSaveProfile;

  @override
  State<ProfilePhotoEditScreen> createState() => _ProfilePhotoEditScreenState();
}

class _ProfilePhotoEditScreenState extends State<ProfilePhotoEditScreen> {
  late final PhotoUploadService _photoService =
      widget.photoUploadService ?? PhotoUploadService();
  late final ProfileService _profileService =
      widget.profileService ?? ProfileService();
  late List<String> _photos;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _photos = List<String>.from(widget.debugPhotos ?? widget.profile.photos);
    _isUploading = widget.debugUploading;
  }

  Future<void> _pickPhotos() async {
    final l10n = AppLocalizations.of(context)!;
    if (_photos.length >= kProfilePhotoMaxCount) {
      showElegantWarning(context, l10n.maxPhotos);
      return;
    }
    if (_isUploading) return;

    setState(() => _isUploading = true);

    try {
      final remainingSlots = kProfilePhotoMaxCount - _photos.length;
      final newPhotos = await (widget.debugPickPhotos != null
          ? widget.debugPickPhotos!(remainingSlots)
          : _photoService.pickMultipleImages(
              maxImages: remainingSlots,
            ));

      // Picker cancellation → empty list; not an error.
      if (newPhotos.isEmpty) return;

      setState(() {
        _photos.addAll(newPhotos);
      });

      await _savePhotos();

      if (mounted) {
        showElegantWarning(context, l10n.photosUploaded(newPhotos.length));
      }
    } catch (e) {
      debugPrint('Error picking photos: $e');
      if (mounted) {
        showElegantWarning(context, l10n.profilePhotosUploadFailed);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _setAsMainPhoto(int index) async {
    if (index == 0) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      final photo = _photos.removeAt(index);
      _photos.insert(0, photo);
    });

    await _savePhotos();

    if (mounted) {
      showElegantWarning(context, l10n.mainPhotoUpdated);
    }
  }

  Future<void> _deletePhoto(int index) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final photoUrl = _photos[index];
      await _photoService.deletePhoto(photoUrl);

      setState(() {
        _photos.removeAt(index);
      });

      await _savePhotos();

      if (mounted) {
        showElegantWarning(context, l10n.photoDeleted);
      }
    } catch (e) {
      debugPrint('Error deleting photo: $e');
      if (mounted) {
        showElegantWarning(context, l10n.profilePhotosDeleteFailed);
      }
    }
  }

  Future<void> _savePhotos() async {
    final updatedProfile = widget.profile.copyWith(
      photos: _photos,
      profilePhotoUrl: _photos.isNotEmpty ? _photos.first : null,
    );

    if (widget.debugSaveProfile != null) {
      await widget.debugSaveProfile!(updatedProfile);
      return;
    }
    await _profileService.saveProfile(updatedProfile);
  }

  void _showPhotoOptions(int index) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index != 0)
              ListTile(
                leading: const Icon(Icons.star, color: AppColors.softGold),
                title: Text(
                  l10n.setAsMain,
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _setAsMainPhoto(index);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.danger),
              title: Text(
                l10n.deleteAction,
                style: GoogleFonts.inter(color: AppColors.danger),
              ),
              onTap: () {
                Navigator.pop(context);
                _deletePhoto(index);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final count = _photos.length;
    final canAdd = count < kProfilePhotoMaxCount;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: QMatchCosmicBackground(
        key: const Key('qmatch-photos-cosmic'),
        seed: 29,
        animate: widget.animateBackground,
        child: SafeArea(
          child: Column(
            children: [
              QMatchPushedScreenHeader(
                key: const Key('qmatch-photos-header'),
                title: l10n.myPhotos,
                backButtonKey: const Key('qmatch-photos-back'),
                titleKey: const Key('qmatch-photos-title'),
                trailing: Text(
                  key: const Key('qmatch-photos-count'),
                  l10n.photoCount(count),
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    count == 0
                        ? l10n.profilePhotosEmptyHint
                        : l10n.longPressHint,
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: count == 0
                    ? _EmptyPhotosState(
                        onAdd: _isUploading ? null : _pickPhotos,
                        uploading: _isUploading,
                      )
                    : GridView.builder(
                        key: const Key('qmatch-photos-grid'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: count + (canAdd ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < count) {
                            return _PhotoTile(
                              key: Key('qmatch-photo-tile-$index'),
                              photoUrl: _photos[index],
                              isPrimary: index == 0,
                              imageProvider: widget.photoImageProviders?[index],
                              primaryLabel: l10n.profilePhotosPrimaryBadge,
                              onLongPress: () => _showPhotoOptions(index),
                            );
                          }
                          return _AddPhotoTile(
                            key: const Key('qmatch-photos-add-tile'),
                            label: l10n.profilePhotosAddTile,
                            onTap: _isUploading ? null : _pickPhotos,
                          );
                        },
                      ),
              ),
              if (count > 0 || _isUploading)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md + bottomInset,
                  ),
                  child: Column(
                    children: [
                      if (!canAdd)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Text(
                            l10n.profilePhotosAtCapacity,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (canAdd)
                        QMatchPrimaryAction(
                          key: const Key('qmatch-photos-add-button'),
                          label: _isUploading
                              ? l10n.profilePhotosUploading
                              : l10n.addPhotos,
                          loading: _isUploading,
                          enabled: !_isUploading,
                          onPressed: _isUploading ? null : _pickPhotos,
                          icon: Icons.add_photo_alternate_outlined,
                          semanticLabel: _isUploading
                              ? l10n.profilePhotosUploading
                              : l10n.addPhotos,
                        ),
                    ],
                  ),
                )
              else
                SizedBox(height: AppSpacing.md + bottomInset),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPhotosState extends StatelessWidget {
  const _EmptyPhotosState({
    required this.onAdd,
    required this.uploading,
  });

  final VoidCallback? onAdd;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      key: const Key('qmatch-photos-empty'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: QGlassCard(
          emphasized: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.profilePhotosEmptyTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.profilePhotosEmptyBody,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              QMatchPrimaryAction(
                key: const Key('qmatch-photos-add-button'),
                label: uploading
                    ? l10n.profilePhotosUploading
                    : l10n.profilePhotosAddFirst,
                loading: uploading,
                enabled: !uploading,
                onPressed: onAdd,
                icon: Icons.add_a_photo_outlined,
                semanticLabel: uploading
                    ? l10n.profilePhotosUploading
                    : l10n.profilePhotosAddFirst,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.glassSurface,
      borderRadius: AppRadii.cardBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.cardBorder,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadii.cardBorder,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.softGold,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    super.key,
    required this.photoUrl,
    required this.isPrimary,
    required this.primaryLabel,
    required this.onLongPress,
    this.imageProvider,
  });

  final String photoUrl;
  final bool isPrimary;
  final String primaryLabel;
  final VoidCallback onLongPress;
  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: AppRadii.cardBorder,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: AppColors.surfaceElevated,
              child: Image(
                image: imageProvider ?? NetworkImage(photoUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: AppColors.surfaceElevated,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textMuted,
                  ),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFDAC8ED),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (isPrimary)
              Positioned(
                top: 8,
                left: 8,
                child: Semantics(
                  label: primaryLabel,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.softGold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star,
                      color: AppColors.cosmicBlack,
                      size: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
