import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ne Arıyorsun?',
            style: GoogleFonts.playfairDisplay(
              color: AppColors.primary,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tercihlerin eşleşmeni etkiler',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          
          // İlişki Tipi
          _buildLabel('İlişki Tipi *'),
          DropdownButtonFormField<String>(
            initialValue: lookingFor,
            decoration: _buildInputDecoration('Ne arıyorsun?'),
            dropdownColor: Colors.grey.shade900,
            style: GoogleFonts.inter(color: Colors.white),
            items: const [
              DropdownMenuItem(
                value: 'Ciddi İlişki',
                child: Text('💍 Ciddi İlişki'),
              ),
              DropdownMenuItem(
                value: 'Uzun Vadeli İlişki',
                child: Text('❤️ Uzun Vadeli İlişki'),
              ),
              DropdownMenuItem(
                value: 'Evlilik',
                child: Text('💒 Evlilik'),
              ),
              DropdownMenuItem(
                value: 'Arkadaşlık',
                child: Text('🤝 Arkadaşlık'),
              ),
              DropdownMenuItem(
                value: 'Yakın Arkadaşlık',
                child: Text('👫 Yakın Arkadaşlık'),
              ),
              DropdownMenuItem(
                value: 'Tanışma',
                child: Text('☕ Tanışma / Sohbet'),
              ),
              DropdownMenuItem(
                value: 'Henüz Emin Değilim',
                child: Text('🤔 Henüz Emin Değilim'),
              ),
              DropdownMenuItem(
                value: 'Akışına Bırakıyorum',
                child: Text('�� Akışına Bırakıyorum'),
              ),
            ],
            onChanged: onLookingForChanged,
          ),
          const SizedBox(height: 32),
          
          // Yaş Aralığı
          _buildLabel('Yaş Aralığı: ${ageRange[0]} - ${ageRange[1]}'),
          RangeSlider(
            values: RangeValues(
              ageRange[0].toDouble(),
              ageRange[1].toDouble(),
            ),
            min: 18,
            max: 80,
            divisions: 62,
            activeColor: AppColors.primary,
            inactiveColor: Colors.grey.shade800,
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
          const SizedBox(height: 24),
          
          // Mesafe Tercihi
          _buildLabel('Maksimum Mesafe: $distancePreference km'),
          Slider(
            value: distancePreference.toDouble(),
            min: 5,
            max: 100,
            divisions: 19,
            activeColor: AppColors.primary,
            inactiveColor: Colors.grey.shade800,
            label: '$distancePreference km',
            onChanged: (double value) {
              onDistanceChanged(value.round());
            },
          ),
          const SizedBox(height: 16),
          
          // Bilgilendirme
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bu tercihler istediğin zaman değiştirilebilir',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
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
