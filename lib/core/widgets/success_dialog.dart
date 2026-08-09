import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../../l10n/app_localizations.dart';

class SuccessDialog extends StatelessWidget {
  final String icon;
  final String title;
  final String message;
  final VoidCallback? onContinue;

  const SuccessDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: AppRadii.sheetBorder,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: AppRadii.sheetBorder,
              color: const Color(0xFF141A2E).withValues(alpha: 0.72),
              border: Border.all(
                color: AppColors.borderGlow,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.softGold.withValues(alpha: 0.18),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.softGold.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.softGold.withValues(alpha: 0.45),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.softGold.withValues(alpha: 0.28),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: onContinue ?? () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.softGold,
                    foregroundColor: AppColors.cosmicBlack,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadii.buttonBorder,
                    ),
                    textStyle: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.continueAction,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
