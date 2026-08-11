import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../utils/assessment_persona_reference_catalog.dart';

/// Production Persona reveal — narrative prototype, not a fixed identity.
///
/// Shows [primaryPersonaId] prominently and [secondaryPersonaId] as a subtle
/// supporting pattern. No scores, %, confidence, Δ_D, RVI, or quantum.
///
/// Live post-assessment wiring uses [onContinue] from
/// [PersonaAssignmentGateScreen] into AssessmentFlowComplete / profile flow.
/// Matching/Discover are not coupled here.
class PersonaRevealScreen extends StatelessWidget {
  const PersonaRevealScreen({
    super.key,
    required this.primaryPersonaId,
    required this.secondaryPersonaId,
    this.onContinue,
  }) : assert(primaryPersonaId != secondaryPersonaId);

  final String primaryPersonaId;
  final String secondaryPersonaId;

  /// Optional CTA. When null, no continue control is shown (nav not wired).
  final VoidCallback? onContinue;

  static const _shellAsset =
      'assets/images/assessment_result_fixed_shell_wide.png';

  static const Color _lavender = Color(0xFFDAC8ED);

  @override
  Widget build(BuildContext context) {
    final primary = _requirePersona(primaryPersonaId, 'primary');
    final secondary = _requirePersona(secondaryPersonaId, 'secondary');

    final tr =
        Localizations.localeOf(context).languageCode.toLowerCase().startsWith('tr');
    final media = MediaQuery.of(context);

    final framing = tr
        ? 'Profiline en yakın anlatı prototipi'
        : 'The narrative prototype closest to your pattern';
    final primaryTitle = tr ? primary.titleTr : primary.titleEn;
    final primaryDescription =
        tr ? primary.descriptionTr : primary.descriptionEn;
    final secondaryLabel = tr
        ? 'Yakın destekleyen örüntü · ${secondary.titleTr}'
        : 'A close supporting pattern · ${secondary.titleEn}';
    final ctaLabel = tr ? 'Devam' : 'Continue';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF080205),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final scale = (width / 390).clamp(0.82, 1.18);
            final bottomSafe = media.padding.bottom;
            final showCta = onContinue != null;

            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  _shellAsset,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                ),
                Positioned(
                  top: height * 0.125,
                  left: width * 0.205,
                  right: width * 0.205,
                  height: height * 0.27,
                  child: const IgnorePointer(child: _PersonaAtmosphere()),
                ),
                Positioned(
                  top: height * 0.092,
                  left: width * 0.17,
                  right: width * 0.17,
                  height: height * 0.345,
                  child: Image.asset(
                    primary.asset,
                    key: const Key('persona-reveal-primary-art'),
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                  ),
                ),
                Positioned(
                  top: height * 0.455,
                  left: width * 0.12,
                  right: width * 0.12,
                  child: Text(
                    framing,
                    key: const Key('persona-reveal-prototype-framing'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: _lavender.withValues(alpha: 0.92),
                      fontSize: 12.5 * scale,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.35,
                      height: 1.25,
                    ),
                  ),
                ),
                Positioned(
                  top: height * 0.492,
                  left: width * 0.14,
                  right: width * 0.14,
                  height: height * 0.052,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      primaryTitle,
                      key: const Key('persona-reveal-primary-title'),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFFFFD967),
                        fontSize: 28 * scale,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        shadows: const [
                          Shadow(
                            color: Color(0xD9A64B00),
                            blurRadius: 13,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: height * 0.555,
                  left: width * 0.16,
                  right: width * 0.16,
                  height: height * 0.12,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: width * 0.68,
                      child: Text(
                        primaryDescription,
                        key: const Key('persona-reveal-primary-description'),
                        maxLines: 5,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF4DFA8),
                          fontSize: 14.5 * scale,
                          fontWeight: FontWeight.w400,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: height * (showCta ? 0.70 : 0.72),
                  left: width * 0.14,
                  right: width * 0.14,
                  child: _SecondaryPattern(
                    key: const Key('persona-reveal-secondary'),
                    label: secondaryLabel,
                    asset: secondary.asset,
                    scale: scale,
                  ),
                ),
                if (showCta)
                  Positioned(
                    left: width * 0.205,
                    right: width * 0.205,
                    bottom: (height * 0.132).clamp(
                      bottomSafe + 10,
                      height * 0.16,
                    ),
                    height: height * 0.066,
                    child: _RevealCta(
                      key: const Key('persona-reveal-continue'),
                      label: ctaLabel,
                      onPressed: onContinue!,
                      scale: scale,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static AssessmentPersonaReference _requirePersona(String id, String role) {
    final ref = assessmentPersonaReferenceCatalog[id];
    if (ref == null) {
      throw ArgumentError.value(id, '${role}PersonaId', 'Unknown persona id');
    }
    return ref;
  }
}

class _SecondaryPattern extends StatelessWidget {
  const _SecondaryPattern({
    super.key,
    required this.label,
    required this.asset,
    required this.scale,
  });

  final String label;
  final String asset;
  final double scale;

  static const Color _lavender = Color(0xFFDAC8ED);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scale,
        vertical: 10 * scale,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0x66140A1C),
        border: Border.all(color: _lavender.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              asset,
              key: const Key('persona-reveal-secondary-art'),
              width: 36 * scale,
              height: 36 * scale,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 12.5 * scale,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonaAtmosphere extends StatelessWidget {
  const _PersonaAtmosphere();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, 0.12),
          radius: 0.76,
          stops: [0, 0.28, 0.62, 1],
          colors: [
            Color(0x24A85F24),
            Color(0x18A14E26),
            Color(0x10501863),
            Color(0x005E1C75),
          ],
        ),
      ),
    );
  }
}

class _RevealCta extends StatelessWidget {
  const _RevealCta({
    super.key,
    required this.label,
    required this.onPressed,
    required this.scale,
  });

  final String label;
  final VoidCallback onPressed;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        splashColor: AppColors.softGold.withValues(alpha: 0.16),
        highlightColor: AppColors.softGold.withValues(alpha: 0.08),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12 * scale),
          child: Row(
            children: [
              Container(
                width: 31 * scale,
                height: 31 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x383C0E52),
                  border: Border.all(color: const Color(0xFFFFD35F)),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 16 * scale,
                  color: const Color(0xFFFFD35F),
                ),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFFFE6A2),
                      fontSize: 20 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 31 * scale),
            ],
          ),
        ),
      ),
    );
  }
}
