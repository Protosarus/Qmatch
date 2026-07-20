import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

/// Floating neon-glass warning — sits above Continue; does not replace the CTA.
void showElegantWarning(BuildContext context, String message) {
  final bottomInset = MediaQuery.paddingOf(context).bottom;
  // Gap between last option and Continue (~54 CTA + scaffold pad).
  final bottomMargin = 70.0 + bottomInset;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.fromLTRB(20, 0, 20, bottomMargin),
      duration: const Duration(seconds: 2),
      content: ClipRRect(
        borderRadius: AppRadii.pillBorder,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 54, maxHeight: 58),
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: AppRadii.pillBorder,
                // Same violet→gold neon language as selected option / Continue.
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color.fromRGBO(75, 31, 224, 0.48),
                    Color.fromRGBO(122, 60, 240, 0.40),
                    Color.fromRGBO(212, 160, 58, 0.44),
                    Color.fromRGBO(240, 198, 90, 0.50),
                  ],
                  stops: [0.0, 0.40, 0.72, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.26),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4B1FE0).withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: const Color(0xFFF0C65A).withValues(alpha: 0.16),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.32),
                      ),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: AppColors.softGold.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.96),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
