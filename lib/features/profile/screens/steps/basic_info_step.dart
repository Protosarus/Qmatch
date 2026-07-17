import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../utils/profile_option_labels.dart';

class BasicInfoStep extends StatefulWidget {
  final int? age;
  final String? gender;
  final String? education;
  final Position? location;
  final String? locationText;
  final Function(int?) onAgeChanged;
  final Function(String?) onGenderChanged;
  final Function(String?) onEducationChanged;
  final Function(Position?, String?) onLocationChanged;

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

        widget.onLocationChanged(position, locationText);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.profileLocationSuccess(locationText)),
              backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.profileBasicInfoTitle,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.primary,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.profileBasicInfoSubtitle,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          _buildLabel(l10n.profileFieldAgeLabel),
          DropdownButtonFormField<int>(
            initialValue: widget.age,
            decoration: _buildInputDecoration(l10n.profileSelectAge),
            dropdownColor: Colors.grey.shade900,
            style: GoogleFonts.inter(color: Colors.white),
            items: List.generate(63, (index) => index + 18)
                .map((age) => DropdownMenuItem(
                      value: age,
                      child: Text('$age'),
                    ))
                .toList(),
            onChanged: widget.onAgeChanged,
          ),
          const SizedBox(height: 24),
          _buildLabel(l10n.profileFieldGenderLabel),
          DropdownButtonFormField<String>(
            initialValue: widget.gender,
            decoration: _buildInputDecoration(l10n.profileSelectGender),
            dropdownColor: Colors.grey.shade900,
            style: GoogleFonts.inter(color: Colors.white),
            items: [
              DropdownMenuItem(
                value: 'Erkek',
                child: Text(ProfileOptionLabels.label(l10n, 'Erkek')),
              ),
              DropdownMenuItem(
                value: 'Kadın',
                child: Text(ProfileOptionLabels.label(l10n, 'Kadın')),
              ),
              DropdownMenuItem(
                value: 'Diğer',
                child: Text(ProfileOptionLabels.label(l10n, 'Diğer')),
              ),
            ],
            onChanged: widget.onGenderChanged,
          ),
          const SizedBox(height: 24),
          _buildLabel(l10n.profileFieldLocationLabel),
          GestureDetector(
            onTap: _loadingLocation ? null : _getCurrentLocation,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.location != null
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.location != null
                        ? Icons.location_on
                        : Icons.location_off,
                    color: widget.location != null
                        ? AppColors.primary
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _loadingLocation
                          ? l10n.profileLocationLoading
                          : widget.locationText ?? l10n.profileShareLocation,
                      style: GoogleFonts.inter(
                        color: widget.location != null
                            ? Colors.white
                            : Colors.grey.shade600,
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
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.profileLocationHint,
            style: GoogleFonts.inter(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
          _buildLabel(l10n.profileFieldEducationLabel),
          DropdownButtonFormField<String>(
            initialValue: widget.education,
            decoration: _buildInputDecoration(l10n.profileSelectEducation),
            dropdownColor: Colors.grey.shade900,
            style: GoogleFonts.inter(color: Colors.white),
            items: [
              for (final v in const [
                'Lise',
                'Ön Lisans',
                'Lisans',
                'Yüksek Lisans',
                'Doktora',
              ])
                DropdownMenuItem(
                  value: v,
                  child: Text(ProfileOptionLabels.label(l10n, v)),
                ),
            ],
            onChanged: widget.onEducationChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.grey.shade900,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
