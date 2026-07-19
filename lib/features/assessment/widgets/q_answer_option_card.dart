import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';

/// Selectable MCQ answer row (A/B/C/D). Selection owned by host via [onTap].
class QAnswerOptionCard extends StatelessWidget {
  const QAnswerOptionCard({
    super.key,
    required this.index,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final letter = String.fromCharCode(65 + index);
    final borderColor = selected
        ? AppColors.resonanceViolet
        : const Color(0x55B07CFF);
    final fill = selected
        ? const Color(0x55401A78)
        : AppColors.glassSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.cardBorder,
        splashColor: AppColors.resonanceViolet.withValues(alpha: 0.18),
        highlightColor: AppColors.resonanceViolet.withValues(alpha: 0.08),
        child: ClipRRect(
          borderRadius: AppRadii.cardBorder,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
              decoration: BoxDecoration(
                borderRadius: AppRadii.cardBorder,
                color: fill,
                border: Border.all(
                  color: borderColor,
                  width: selected ? 1.4 : 0.9,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color:
                              AppColors.resonanceViolet.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? AppColors.resonanceViolet.withValues(alpha: 0.85)
                          : const Color(0x33101828),
                      border: Border.all(
                        color: selected
                            ? AppColors.softGold.withValues(alpha: 0.7)
                            : const Color(0x66B07CFF),
                      ),
                    ),
                    child: Text(
                      letter,
                      style: GoogleFonts.inter(
                        color: selected ? Colors.white : AppColors.vizEq,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(
                          alpha: selected ? 1.0 : 0.92,
                        ),
                        fontSize: 14.5,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        height: 1.35,
                      ),
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: AppColors.softGold.withValues(alpha: 0.9),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
