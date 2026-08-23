import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/qmatch_cosmic_background.dart';
import '../../../core/widgets/elegant_warning.dart';
import '../../../core/widgets/qmatch_primary_action.dart';
import '../../../core/widgets/qmatch_pushed_screen_header.dart';
import '../../../l10n/app_localizations.dart';
import '../models/user_profile_model.dart';
import '../services/profile_service.dart';
import '../widgets/profile_setup_chrome.dart';

/// Optional profile anthem editor (title / artist / external link — no player).
class ProfileAnthemEditScreen extends StatefulWidget {
  const ProfileAnthemEditScreen({
    super.key,
    required this.profile,
    this.profileService,
    this.animateBackground,
    this.debugSaveProfile,
  });

  final UserProfileModel profile;
  final ProfileService? profileService;
  final bool? animateBackground;
  final Future<void> Function(UserProfileModel profile)? debugSaveProfile;

  @override
  State<ProfileAnthemEditScreen> createState() =>
      _ProfileAnthemEditScreenState();
}

class _ProfileAnthemEditScreenState extends State<ProfileAnthemEditScreen> {
  late final ProfileService _profileService =
      widget.profileService ?? ProfileService();

  late final TextEditingController _titleController;
  late final TextEditingController _artistController;
  late final TextEditingController _urlController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _titleController = TextEditingController(text: p.anthemTitle?.trim() ?? '');
    _artistController =
        TextEditingController(text: p.anthemArtist?.trim() ?? '');
    _urlController =
        TextEditingController(text: p.anthemExternalUrl?.trim() ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  String _optional(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? '' : trimmed;
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context)!;
    final title = _optional(_titleController.text);
    final artist = _optional(_artistController.text);
    final url = _optional(_urlController.text);

    if (title.isEmpty && (artist.isNotEmpty || url.isNotEmpty)) {
      showElegantWarning(context, l10n.profileAnthemTitleRequired);
      return;
    }

    if (url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
        showElegantWarning(context, l10n.profileAnthemUrlInvalid);
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final updated = widget.profile.copyWith(
        anthemTitle: title,
        anthemArtist: artist,
        anthemExternalUrl: url,
      );
      if (widget.debugSaveProfile != null) {
        await widget.debugSaveProfile!(updated);
      } else {
        await _profileService.saveProfile(updated);
      }
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (_) {
      if (!mounted) return;
      showElegantWarning(context, l10n.profileAnthemSaveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: QMatchCosmicBackground(
        key: const Key('qmatch-profile-anthem-cosmic'),
        seed: 53,
        animate: widget.animateBackground,
        child: SafeArea(
          child: Column(
            children: [
              QMatchPushedScreenHeader(
                key: const Key('qmatch-profile-anthem-header'),
                title: l10n.profileAnthemEditTitle,
                backButtonKey: const Key('qmatch-profile-anthem-back'),
                titleKey: const Key('qmatch-profile-anthem-title'),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  children: [
                    Text(
                      l10n.profileAnthemEditSubtitle,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ProfileSetupChrome.label(l10n.profileAnthemSongTitle),
                    TextField(
                      key: const Key('qmatch-profile-anthem-song-title'),
                      controller: _titleController,
                      style: ProfileSetupChrome.fieldTextStyle(),
                      cursorColor: ProfileSetupChrome.accentLabel,
                      textInputAction: TextInputAction.next,
                      decoration: ProfileSetupChrome.fieldDecoration(
                        l10n.profileAnthemSongTitleHint,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ProfileSetupChrome.label(l10n.profileAnthemArtist),
                    TextField(
                      key: const Key('qmatch-profile-anthem-artist'),
                      controller: _artistController,
                      style: ProfileSetupChrome.fieldTextStyle(),
                      cursorColor: ProfileSetupChrome.accentLabel,
                      textInputAction: TextInputAction.next,
                      decoration: ProfileSetupChrome.fieldDecoration(
                        l10n.profileAnthemArtistHint,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ProfileSetupChrome.label(l10n.profileAnthemLink),
                    TextField(
                      key: const Key('qmatch-profile-anthem-link'),
                      controller: _urlController,
                      style: ProfileSetupChrome.fieldTextStyle(),
                      cursorColor: ProfileSetupChrome.accentLabel,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.done,
                      decoration: ProfileSetupChrome.fieldDecoration(
                        l10n.profileAnthemLinkHint,
                      ),
                      onSubmitted: (_) => _save(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md + bottomInset,
                ),
                child: QMatchPrimaryAction(
                  key: const Key('qmatch-profile-anthem-save'),
                  label: l10n.profileAnthemSave,
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
