import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

/// Reference-locked, full-screen assessment result reveal.
///
/// The fixed cosmic scene (frame, shield, light, particles and CTA plate) is
/// one decorative layer. The persona symbol and every word remain replaceable
/// Flutter layers.
class AssessmentResultFrame extends StatelessWidget {
  const AssessmentResultFrame({
    super.key,
    required this.title,
    required this.description,
    required this.ctaLabel,
    required this.onCta,
    this.tags = const [],
    this.personaAsset = _defaultPersonaAsset,
    this.statusLabel,
  });

  static const _shellAsset =
      'assets/images/assessment_result_fixed_shell_wide.png';
  static const _defaultPersonaAsset =
      'assets/images/assessment_persona_executor_reward_sparse.png';

  final String title;
  final String description;
  final List<String> tags;
  final String? statusLabel;
  final String personaAsset;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isTurkish = Localizations.localeOf(context).languageCode == 'tr';
    final displayTitle = isTurkish
        ? title.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase()
        : title.toUpperCase();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: const Color(0xFF080205),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              final scale = (width / 390).clamp(0.82, 1.18);
              final bottomSafe = media.padding.bottom;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Fixed reference layer. BoxFit.fill deliberately maps the
                  // complete frame to every phone without cropping its edges.
                  Image.asset(
                    _shellAsset,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                  ),

                  // Shared ambient light prevents clean persona cutouts from
                  // looking pasted onto the shield's dark interior. Its edges
                  // fade fully to transparent, so it never forms another ring.
                  Positioned(
                    top: height * 0.125,
                    left: width * 0.205,
                    right: width * 0.205,
                    height: height * 0.27,
                    child: const IgnorePointer(
                      child: _PersonaAtmosphere(),
                    ),
                  ),

                  // Variable persona symbol, centered inside the fixed shield.
                  Positioned(
                    top: height * 0.092,
                    left: width * 0.17,
                    right: width * 0.17,
                    height: height * 0.345,
                    child: Image.asset(
                      personaAsset,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                    ),
                  ),

                  Positioned(
                    top: height * 0.485,
                    left: width * 0.14,
                    right: width * 0.14,
                    height: height * 0.052,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        displayTitle,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cinzel(
                          color: const Color(0xFFFFD967),
                          fontSize: 27 * scale,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
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

                  if (tags.isNotEmpty)
                    Positioned(
                      top: height * 0.545,
                      left: width * 0.12,
                      right: width * 0.12,
                      child: Row(
                        children: [
                          const Expanded(child: _GoldDivider()),
                          SizedBox(width: 9 * scale),
                          Flexible(
                            flex: 4,
                            child: Text(
                              tags.take(3).join(' · '),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: const Color(0xFFFFDE78),
                                fontSize: 14.5 * scale,
                                fontWeight: FontWeight.w500,
                                height: 1.25,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          SizedBox(width: 9 * scale),
                          const Expanded(
                            child: _GoldDivider(reverse: true),
                          ),
                        ],
                      ),
                    ),

                  Positioned(
                    top: height * 0.602,
                    left: width * 0.16,
                    right: width * 0.16,
                    height: height * 0.13,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: width * 0.68,
                        child: Text(
                          description,
                          maxLines: 7,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFF4DFA8),
                            fontSize: 14.5 * scale,
                            fontWeight: FontWeight.w400,
                            height: 1.48,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (statusLabel != null && statusLabel!.trim().isNotEmpty)
                    Positioned(
                      top: height * 0.752,
                      left: width * 0.16,
                      right: width * 0.16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check,
                            size: 16 * scale,
                            color: const Color(0xFFFFD55E),
                          ),
                          SizedBox(width: 6 * scale),
                          Flexible(
                            child: Text(
                              statusLabel!,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: const Color(0xFFEED68F),
                                fontSize: 12.5 * scale,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Interactive Flutter CTA aligned to the blank fixed plate.
                  Positioned(
                    left: width * 0.205,
                    right: width * 0.205,
                    bottom: (height * 0.132).clamp(
                      bottomSafe + 10,
                      height * 0.16,
                    ),
                    height: height * 0.066,
                    child: _ResultCta(
                      label: ctaLabel,
                      onPressed: onCta,
                      scale: scale,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PersonaAtmosphere extends StatelessWidget {
  const _PersonaAtmosphere();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
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
        ),
        Align(
          alignment: const Alignment(0, 0.18),
          child: FractionallySizedBox(
            widthFactor: 0.78,
            heightFactor: 0.72,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.72,
                  stops: const [0, 0.42, 1],
                  colors: const [
                    Color(0x14512771),
                    Color(0x0C591C68),
                    Color(0x006D2478),
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0E713F91),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoldDivider extends StatelessWidget {
  const _GoldDivider({this.reverse = false});

  final bool reverse;

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: reverse,
      child: Row(
        children: [
          const Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x00D18A24),
                    Color(0xBFE5A93C),
                  ],
                ),
              ),
              child: SizedBox(height: 1),
            ),
          ),
          Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFD867),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCta extends StatelessWidget {
  const _ResultCta({
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
                  border: Border.all(
                    color: const Color(0xFFFFD35F),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.diamond_outlined,
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
                      shadows: const [
                        Shadow(
                          color: Color(0xB8864200),
                          blurRadius: 8,
                        ),
                      ],
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
