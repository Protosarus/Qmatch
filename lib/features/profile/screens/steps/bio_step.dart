import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hakkında',
            style: GoogleFonts.playfairDisplay(
              color: AppColors.primary,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kendini ifade et, dikkat çek!',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          
          TextField(
            maxLines: 8,
            maxLength: 500,
            onChanged: onBioChanged,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Kendini tanıt... Hobilerinden, tutkularından, hayallerinden bahset.',
              hintStyle: GoogleFonts.inter(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.grey.shade900,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
}
