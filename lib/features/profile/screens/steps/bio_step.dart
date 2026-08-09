import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../widgets/profile_setup_chrome.dart';

class BioStep extends StatelessWidget {
  final String bio;
  final Function(String) onBioChanged;

  const BioStep({
    super.key,
    required this.bio,
    required this.onBioChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.profileBioTitle,
            style: ProfileSetupChrome.stepTitleStyle(),
          ),
          const SizedBox(height: AppSpacing.xs),
          ProfileSetupChrome.highlightedSubtitle(l10n.profileBioSubtitle),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            maxLines: 8,
            maxLength: 500,
            onChanged: onBioChanged,
            style: ProfileSetupChrome.fieldTextStyle(),
            cursorColor: ProfileSetupChrome.accentLabel,
            decoration: ProfileSetupChrome.fieldDecoration(l10n.profileBioHint)
                .copyWith(
              counterStyle: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
