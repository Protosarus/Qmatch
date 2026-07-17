import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../utils/profile_option_labels.dart';

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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.profileLifestyleTitle,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.primary,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.profileLifestyleSubtitle,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          _buildLabel(l10n.profileOccupation),
          TextField(
            onChanged: onOccupationChanged,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: _buildInputDecoration(l10n.profileOccupationHint),
          ),
          const SizedBox(height: 24),
          _buildLabel(l10n.profileDrinking),
          DropdownButtonFormField<String>(
            initialValue: drinking,
            decoration: _buildInputDecoration(l10n.profileSelectOption),
            dropdownColor: Colors.grey.shade900,
            style: GoogleFonts.inter(color: Colors.white),
            items: [
              for (final v in const [
                'Kullanmıyorum',
                'Sosyal',
                'Sık sık',
                'Özel Günlerde',
              ])
                DropdownMenuItem(
                  value: v,
                  child: Text(ProfileOptionLabels.label(l10n, v)),
                ),
            ],
            onChanged: onDrinkingChanged,
          ),
          const SizedBox(height: 24),
          _buildLabel(l10n.profileSmoking),
          DropdownButtonFormField<String>(
            initialValue: smoking,
            decoration: _buildInputDecoration(l10n.profileSelectOption),
            dropdownColor: Colors.grey.shade900,
            style: GoogleFonts.inter(color: Colors.white),
            items: [
              for (final v in const [
                'Kullanmıyorum',
                'Bazen',
                'Düzenli',
                'Bırakmaya Çalışıyorum',
              ])
                DropdownMenuItem(
                  value: v,
                  child: Text(ProfileOptionLabels.label(l10n, v)),
                ),
            ],
            onChanged: onSmokingChanged,
          ),
          const SizedBox(height: 24),
          _buildLabel(l10n.profilePets),
          DropdownButtonFormField<String>(
            initialValue: pets,
            decoration: _buildInputDecoration(l10n.profileSelectOption),
            dropdownColor: Colors.grey.shade900,
            style: GoogleFonts.inter(color: Colors.white),
            items: [
              for (final v in const ['Var', 'Yok', 'İstiyorum', 'Alerji'])
                DropdownMenuItem(
                  value: v,
                  child: Text(ProfileOptionLabels.petsLabel(l10n, v)),
                ),
            ],
            onChanged: onPetsChanged,
          ),
          const SizedBox(height: 24),
          _buildLabel(l10n.profileAnimalLove),
          DropdownButtonFormField<String>(
            initialValue: animalLove,
            decoration: _buildInputDecoration(l10n.profileSelectOption),
            dropdownColor: Colors.grey.shade900,
            style: GoogleFonts.inter(color: Colors.white),
            items: [
              for (final v in const [
                'Çok Seviyorum',
                'Seviyorum',
                'Nötr',
                'Pek Sevmem',
              ])
                DropdownMenuItem(
                  value: v,
                  child: Text(ProfileOptionLabels.label(l10n, v)),
                ),
            ],
            onChanged: onAnimalLoveChanged,
          ),
          const SizedBox(height: 24),
          _buildLabel(l10n.profileChildren),
          DropdownButtonFormField<String>(
            initialValue: children,
            decoration: _buildInputDecoration(l10n.profileSelectOption),
            dropdownColor: Colors.grey.shade900,
            style: GoogleFonts.inter(color: Colors.white),
            items: [
              for (final v in const [
                'Var',
                'Yok Ama İstiyorum',
                'Yok ve İstemiyorum',
                'Kararsızım',
                'Belki İleride',
              ])
                DropdownMenuItem(
                  value: v,
                  child: Text(ProfileOptionLabels.childrenLabel(l10n, v)),
                ),
            ],
            onChanged: onChildrenChanged,
          ),
          const SizedBox(height: 24),
          _buildLabel(l10n.profileReligion),
          DropdownButtonFormField<String>(
            initialValue: religion,
            decoration: _buildInputDecoration(l10n.profileSelectOption),
            dropdownColor: Colors.grey.shade900,
            style: GoogleFonts.inter(color: Colors.white),
            items: [
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
                DropdownMenuItem(
                  value: v,
                  child: Text(ProfileOptionLabels.label(l10n, v)),
                ),
            ],
            onChanged: onReligionChanged,
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
