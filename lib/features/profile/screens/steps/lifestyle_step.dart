import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../utils/profile_option_labels.dart';
import '../../widgets/profile_setup_chrome.dart';
import '../../widgets/profile_setup_select_field.dart';

class LifestyleStep extends StatelessWidget {
  final String? occupation;
  final String? drinking;
  final String? smoking;
  final String? pets;
  final String? children;
  final String? religion;
  final String? animalLove;
  final Function(String?) onOccupationChanged;
  final Function(String?) onDrinkingChanged;
  final Function(String?) onSmokingChanged;
  final Function(String?) onPetsChanged;
  final Function(String?) onChildrenChanged;
  final Function(String?) onReligionChanged;
  final Function(String?) onAnimalLoveChanged;

  const LifestyleStep({
    super.key,
    required this.occupation,
    required this.drinking,
    required this.smoking,
    required this.pets,
    required this.children,
    required this.religion,
    required this.animalLove,
    required this.onOccupationChanged,
    required this.onDrinkingChanged,
    required this.onSmokingChanged,
    required this.onPetsChanged,
    required this.onChildrenChanged,
    required this.onReligionChanged,
    required this.onAnimalLoveChanged,
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
            l10n.profileLifestyleTitle,
            style: ProfileSetupChrome.stepTitleStyle(),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.profileLifestyleSubtitle,
            style: ProfileSetupChrome.stepSubtitleStyle(),
          ),
          const SizedBox(height: AppSpacing.xl),
          ProfileSetupChrome.label(l10n.profileOccupation),
          TextField(
            onChanged: onOccupationChanged,
            style: ProfileSetupChrome.fieldTextStyle(),
            cursorColor: ProfileSetupChrome.accentLabel,
            decoration: ProfileSetupChrome.fieldDecoration(
              l10n.profileOccupationHint,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ProfileSetupChrome.label(l10n.profileDrinking),
          ProfileSetupSelectField<String>(
            value: drinking,
            hint: l10n.profileSelectOption,
            options: [
              for (final v in const [
                'Kullanmıyorum',
                'Sosyal',
                'Sık sık',
                'Özel Günlerde',
              ])
                ProfileSetupSelectOption(
                  value: v,
                  label: ProfileOptionLabels.label(l10n, v),
                ),
            ],
            onChanged: (v) => onDrinkingChanged(v),
          ),
          const SizedBox(height: AppSpacing.lg),
          ProfileSetupChrome.label(l10n.profileSmoking),
          ProfileSetupSelectField<String>(
            value: smoking,
            hint: l10n.profileSelectOption,
            options: [
              for (final v in const [
                'Kullanmıyorum',
                'Bazen',
                'Düzenli',
                'Bırakmaya Çalışıyorum',
              ])
                ProfileSetupSelectOption(
                  value: v,
                  label: ProfileOptionLabels.label(l10n, v),
                ),
            ],
            onChanged: (v) => onSmokingChanged(v),
          ),
          const SizedBox(height: AppSpacing.lg),
          ProfileSetupChrome.label(l10n.profilePets),
          ProfileSetupSelectField<String>(
            value: pets,
            hint: l10n.profileSelectOption,
            options: [
              for (final v in const ['Var', 'Yok', 'İstiyorum', 'Alerji'])
                ProfileSetupSelectOption(
                  value: v,
                  label: ProfileOptionLabels.petsLabel(l10n, v),
                ),
            ],
            onChanged: (v) => onPetsChanged(v),
          ),
          const SizedBox(height: AppSpacing.lg),
          ProfileSetupChrome.label(l10n.profileAnimalLove),
          ProfileSetupSelectField<String>(
            value: animalLove,
            hint: l10n.profileSelectOption,
            options: [
              for (final v in const [
                'Çok Seviyorum',
                'Seviyorum',
                'Nötr',
                'Pek Sevmem',
              ])
                ProfileSetupSelectOption(
                  value: v,
                  label: ProfileOptionLabels.label(l10n, v),
                ),
            ],
            onChanged: (v) => onAnimalLoveChanged(v),
          ),
          const SizedBox(height: AppSpacing.lg),
          ProfileSetupChrome.label(l10n.profileChildren),
          ProfileSetupSelectField<String>(
            value: children,
            hint: l10n.profileSelectOption,
            options: [
              for (final v in const [
                'Var',
                'Yok Ama İstiyorum',
                'Yok ve İstemiyorum',
                'Kararsızım',
                'Belki İleride',
              ])
                ProfileSetupSelectOption(
                  value: v,
                  label: ProfileOptionLabels.childrenLabel(l10n, v),
                ),
            ],
            onChanged: (v) => onChildrenChanged(v),
          ),
          const SizedBox(height: AppSpacing.lg),
          ProfileSetupChrome.label(l10n.profileReligion),
          ProfileSetupSelectField<String>(
            value: religion,
            hint: l10n.profileSelectOption,
            options: [
              for (final v in const [
                'Müslüman',
                'Hristiyan',
                'Yahudi',
                'Budist',
                'Hindu',
                'Agnostik',
                'Ateist',
                'Manevi',
                'Diğer',
                'Belirtmek İstemiyorum',
              ])
                ProfileSetupSelectOption(
                  value: v,
                  label: ProfileOptionLabels.label(l10n, v),
                ),
            ],
            onChanged: (v) => onReligionChanged(v),
          ),
        ],
      ),
    );
  }
}
