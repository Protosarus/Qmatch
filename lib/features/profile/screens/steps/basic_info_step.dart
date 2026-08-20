import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/home_geography.dart';
import '../../utils/profile_option_labels.dart';
import '../../widgets/profile_setup_chrome.dart';
import '../../widgets/profile_setup_select_field.dart';

class BasicInfoStep extends StatefulWidget {
  final int? age;
  final String? gender;
  final String? education;
  final Position? location;
  final String? locationText;
  final Function(int?) onAgeChanged;
  final Function(String?) onGenderChanged;
  final Function(String?) onEducationChanged;
  final void Function(Position?, String?, HomeGeography?) onLocationChanged;

  const BasicInfoStep({
    super.key,
    required this.age,
    required this.gender,
    required this.education,
    this.location,
    this.locationText,
    required this.onAgeChanged,
    required this.onGenderChanged,
    required this.onEducationChanged,
    required this.onLocationChanged,
  });

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  bool _loadingLocation = false;

  Future<void> _getCurrentLocation() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _loadingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw l10n.profileLocationPermissionDenied;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw l10n.profileLocationPermissionPermanentlyDenied;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final locationText =
            '${place.subAdministrativeArea ?? place.locality}, ${place.administrativeArea}';
        final homeGeography = HomeGeographyNormalizer.fromPlacemark(
          HomeGeographyPlacemarkInput(
            isoCountryCode: place.isoCountryCode,
            locality: place.locality,
            administrativeArea: place.administrativeArea,
            subAdministrativeArea: place.subAdministrativeArea,
          ),
        );

        widget.onLocationChanged(position, locationText, homeGeography);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.profileLocationSuccess(locationText)),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final msg = e is String ? e : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.profileLocationError(msg),
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      setState(() => _loadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.profileBasicInfoTitle,
            style: ProfileSetupChrome.stepTitleStyle(),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.profileBasicInfoSubtitle,
            style: ProfileSetupChrome.stepSubtitleStyle(),
          ),
          const SizedBox(height: AppSpacing.xl),
          ProfileSetupChrome.label(l10n.profileFieldAgeLabel),
          ProfileSetupSelectField<int>(
            value: widget.age,
            hint: l10n.profileSelectAge,
            options: [
              for (final age in List.generate(63, (i) => i + 18))
                ProfileSetupSelectOption(value: age, label: '$age'),
            ],
            onChanged: (v) => widget.onAgeChanged(v),
          ),
          const SizedBox(height: AppSpacing.lg),
          ProfileSetupChrome.label(l10n.profileFieldGenderLabel),
          ProfileSetupSelectField<String>(
            value: widget.gender,
            hint: l10n.profileSelectGender,
            options: [
              for (final v in const ['Erkek', 'Kadın'])
                ProfileSetupSelectOption(
                  value: v,
                  label: ProfileOptionLabels.label(l10n, v),
                ),
            ],
            onChanged: (v) => widget.onGenderChanged(v),
          ),
          const SizedBox(height: AppSpacing.lg),
          ProfileSetupChrome.label(l10n.profileFieldLocationLabel),
          GestureDetector(
            onTap: _loadingLocation ? null : _getCurrentLocation,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: ProfileSetupChrome.glassFieldDecoration(
                emphasized: widget.location != null,
              ),
              child: Row(
                children: [
                  Icon(
                    widget.location != null
                        ? Icons.location_on
                        : Icons.location_off,
                    color: widget.location != null
                        ? ProfileSetupChrome.accentIcon
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _loadingLocation
                          ? l10n.profileLocationLoading
                          : widget.locationText ?? l10n.profileShareLocation,
                      style: GoogleFonts.inter(
                        color: widget.location != null
                            ? AppColors.textPrimary
                            : const Color(0xFFC4C4D4),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (_loadingLocation)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ProfileSetupChrome.accentLabel,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.profileLocationHint,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ProfileSetupChrome.label(l10n.profileFieldEducationLabel),
          ProfileSetupSelectField<String>(
            value: widget.education,
            hint: l10n.profileSelectEducation,
            options: [
              for (final v in const [
                'Lise',
                'Ön Lisans',
                'Lisans',
                'Yüksek Lisans',
                'Doktora',
              ])
                ProfileSetupSelectOption(
                  value: v,
                  label: ProfileOptionLabels.label(l10n, v),
                ),
            ],
            onChanged: (v) => widget.onEducationChanged(v),
          ),
        ],
      ),
    );
  }
}
