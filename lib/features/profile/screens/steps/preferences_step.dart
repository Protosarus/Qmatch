import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../utils/profile_option_labels.dart';
import '../../widgets/profile_setup_chrome.dart';
import '../../widgets/profile_setup_select_field.dart';

class PreferencesStep extends StatelessWidget {
  final String? lookingFor;
  final List<int> ageRange;
  final int distancePreference;
  final Function(String?) onLookingForChanged;
  final Function(List<int>) onAgeRangeChanged;
  final Function(int) onDistanceChanged;

  const PreferencesStep({
    super.key,
    required this.lookingFor,
    required this.ageRange,
    required this.distancePreference,
    required this.onLookingForChanged,
    required this.onAgeRangeChanged,
    required this.onDistanceChanged,
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
            l10n.profilePreferencesTitle,
            style: ProfileSetupChrome.stepTitleStyle(),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.profilePreferencesSubtitle,
            style: ProfileSetupChrome.stepSubtitleStyle(),
          ),
          const SizedBox(height: AppSpacing.xl),
          ProfileSetupChrome.label(l10n.profileFieldLookingForLabel),
          ProfileSetupSelectField<String>(
            value: lookingFor,
            hint: l10n.profileLookingForHint,
            options: [
              for (final entry in const [
                ('Ciddi İlişki', '💍'),
                ('Uzun Vadeli İlişki', '❤️'),
                ('Evlilik', '💒'),
                ('Arkadaşlık', '🤝'),
                ('Yakın Arkadaşlık', '👫'),
                ('Tanışma', '☕'),
                ('Henüz Emin Değilim', '🤔'),
                ('Akışına Bırakıyorum', '🌊'),
              ])
                ProfileSetupSelectOption(
                  value: entry.$1,
                  label:
                      '${entry.$2} ${ProfileOptionLabels.label(l10n, entry.$1)}',
                ),
            ],
            onChanged: (v) => onLookingForChanged(v),
          ),
          const SizedBox(height: AppSpacing.xl),
          ProfileSetupChrome.label(
            l10n.profileAgeRangeLabel(ageRange[0], ageRange[1]),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF9B7CFF),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
              thumbColor: const Color(0xFFDAC8ED),
              overlayColor: const Color(0x339B7CFF),
              valueIndicatorColor: const Color(0xFF5B4B8A),
              valueIndicatorTextStyle: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              rangeThumbShape:
                  const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: RangeSlider(
              values: RangeValues(
                ageRange[0].toDouble(),
                ageRange[1].toDouble(),
              ),
              min: 18,
              max: 80,
              divisions: 62,
              labels: RangeLabels(
                ageRange[0].toString(),
                ageRange[1].toString(),
              ),
              onChanged: (RangeValues values) {
                onAgeRangeChanged([
                  values.start.round(),
                  values.end.round(),
                ]);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ProfileSetupChrome.label(
            l10n.profileMaxDistanceLabel(distancePreference),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF9B7CFF),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
              thumbColor: const Color(0xFFDAC8ED),
              overlayColor: const Color(0x339B7CFF),
              valueIndicatorColor: const Color(0xFF5B4B8A),
              valueIndicatorTextStyle: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Slider(
              value: distancePreference.toDouble(),
              min: 5,
              max: 100,
              divisions: 19,
              label: '$distancePreference km',
              onChanged: (double value) {
                onDistanceChanged(value.round());
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: ProfileSetupChrome.fieldFill,
              borderRadius: AppRadii.buttonBorder,
              border: Border.all(color: ProfileSetupChrome.borderIdle),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: ProfileSetupChrome.accentIcon,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.profilePreferencesEditableHint,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
