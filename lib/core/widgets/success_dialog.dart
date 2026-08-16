import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_radii.dart';

/// Cosmic success sheet — cool glass + lavender accent + violet→gold CTA.
///
/// Shared celebration dialog (profile ready, etc.). Not a Persona reveal.
class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onContinue;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.onContinue,
    @Deprecated('Emoji icon replaced by lavender auto_awesome mark')
    String? icon,
  });

  static const Color _lavender = Color(0xFFDAC8ED);
  static const Color _title = Color(0xFFF2EEF7);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titleParts = _splitTitle(title);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: ClipRRect(
        borderRadius: AppRadii.sheetBorder,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            decoration: BoxDecoration(
              borderRadius: AppRadii.sheetBorder,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1A1630).withValues(alpha: 0.88),
                  const Color(0xFF0C0C14).withValues(alpha: 0.92),
                ],
              ),
              border: Border.all(
                color: _lavender.withValues(alpha: 0.38),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7A4DDF).withValues(alpha: 0.28),
                  blurRadius: 32,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _lavender.withValues(alpha: 0.12),
                    border: Border.all(
                      color: _lavender.withValues(alpha: 0.55),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7A4DDF).withValues(alpha: 0.35),
                        blurRadius: 22,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: _lavender,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 22),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: titleParts.$1,
                        style: GoogleFonts.playfairDisplay(
                          color: _title,
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                          height: 1.15,
                        ),
                      ),
                      TextSpan(
                        text: titleParts.$2,
                        style: GoogleFonts.playfairDisplay(
                          color: _lavender,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 15,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 26),
                _CosmicContinueButton(
                  label: l10n.continueAction,
                  onPressed: onContinue ?? () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Split into (lead, emphasis) for Playfair hierarchy.
  /// Falls back to full title as lead when no trailing word.
  static (String, String) _splitTitle(String title) {
    final trimmed = title.trim();
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length < 2) return (trimmed, '');
    final emphasis = parts.last;
    final lead = parts.sublist(0, parts.length - 1).join(' ');
    return ('$lead ', emphasis);
  }
}

class _CosmicContinueButton extends StatelessWidget {
  const _CosmicContinueButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: AppRadii.pillBorder,
        gradient: AppGradients.cosmicCtaGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.resonanceViolet.withValues(alpha: 0.34),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.softGold.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadii.pillBorder,
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
