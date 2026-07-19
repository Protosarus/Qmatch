import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_radii.dart';
import '../../../l10n/app_localizations.dart';
import 'login_screen.dart';
import 'phone_signup_screen.dart';

/// Welcome — layered cosmic assets + Flutter UI.
/// Locked to reference composition; responsive across phone sizes.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _maxContentWidth = 430.0;

  void _goPhone(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PhoneSignupScreen()),
    );
  }

  void _goLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF05040C),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _Backdrop(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final h = constraints.maxHeight;
                  final w = constraints.maxWidth;
                  final contentW = math.min(w, _maxContentWidth);
                  final padH = (w * 0.055).clamp(16.0, 24.0);

                  // Scale map for phone heights (logical px).
                  final scale = (h / 780).clamp(0.78, 1.08);
                  final tiny = h < 640;
                  final short = h < 720;
                  final dense = tiny || short;

                  final brandQ = (72.0 * scale).clamp(52.0, 84.0);
                  final wordmark = (34.0 * scale).clamp(26.0, 38.0);
                  final cueIcon = (40.0 * scale).clamp(32.0, 44.0);
                  final ctaH = (52.0 * scale).clamp(46.0, 56.0);
                  final heroBudget = h * (tiny ? 0.36 : short ? 0.40 : 0.45);
                  final heroMax = (contentW * 0.96).clamp(220.0, 390.0);

                  final gapBrandCues = dense ? 8.0 : 12.0;
                  final gapCuesHero = dense ? 2.0 : 4.0;
                  final gapHeroCta = dense ? 8.0 : 12.0;
                  final gapCtaEmail = dense ? 8.0 : 10.0;
                  final gapEmailCards = dense ? 12.0 : 16.0;
                  final gapCardsLegal = dense ? 10.0 : 12.0;

                  Widget body = Padding(
                    padding: EdgeInsets.fromLTRB(
                      padH,
                      dense ? 2 : 6,
                      padH,
                      dense ? 8 : 12,
                    ),
                    child: Column(
                      children: [
                        _Brand(
                          qSize: brandQ,
                          wordmarkSize: wordmark,
                          dense: dense,
                          tagline: l10n.welcomeTagline,
                        ),
                        SizedBox(height: gapBrandCues),
                        _Cues(
                          iconSize: cueIcon,
                          a: l10n.welcomeCueIntelligent,
                          b: l10n.welcomeCueEmotional,
                          c: l10n.welcomeCueVibrational,
                        ),
                        SizedBox(height: gapCuesHero),
                        Expanded(
                          child: Center(
                            child: LayoutBuilder(
                              builder: (_, box) {
                                final size = math
                                    .min(
                                      heroBudget,
                                      math.min(heroMax, box.maxHeight),
                                    )
                                    .clamp(160.0, heroMax);
                                if (size < 140) {
                                  return const SizedBox.shrink();
                                }
                                return _Hero(size: size);
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: gapHeroCta),
                        _Cta(
                          label: l10n.welcomeContinueWithPhone,
                          height: ctaH,
                          onTap: () => _goPhone(context),
                        ),
                        SizedBox(height: gapCtaEmail),
                        _LoginLink(
                          label: l10n.welcomeLogInWithEmail,
                          onTap: () => _goLogin(context),
                        ),
                        SizedBox(height: gapEmailCards),
                        _TrustRow(
                          compact: dense,
                          t1: l10n.welcomeTrustPrivateTitle,
                          b1: l10n.welcomeTrustPrivateBody,
                          t2: l10n.welcomeTrustScienceTitle,
                          b2: l10n.welcomeTrustScienceBody,
                          t3: l10n.welcomeTrustMatchesTitle,
                          b3: l10n.welcomeTrustMatchesBody,
                        ),
                        SizedBox(height: gapCardsLegal),
                        _LegalFooter(
                          prefix: l10n.welcomeLegalPrefix,
                          terms: l10n.welcomeTermsOfService,
                          andWord: l10n.welcomeLegalAnd,
                          privacy: l10n.welcomePrivacyPolicy,
                          suffix: l10n.welcomeLegalSuffix,
                        ),
                      ],
                    ),
                  );

                  body = ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentW),
                    child: body,
                  );

                  if (tiny) {
                    return Align(
                      alignment: Alignment.topCenter,
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: SizedBox(
                          height: math.max(h, 700),
                          width: contentW,
                          child: body,
                        ),
                      ),
                    );
                  }

                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(width: contentW, child: body),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF05040C)),
          Image.asset(
            'assets/images/welcome_cosmic_background.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
          // Soft vignette so brand / CTA remain readable on all crops.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x6605040C),
                  Color(0x1405040C),
                  Color(0x9905040C),
                ],
                stops: [0.0, 0.42, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({
    required this.qSize,
    required this.wordmarkSize,
    required this.dense,
    required this.tagline,
  });

  final double qSize;
  final double wordmarkSize;
  final bool dense;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: qSize,
          height: qSize,
          child: Image.asset(
            'assets/images/welcome_q_glow.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            // Preserve PNG alpha — never bake a white/black box.
            gaplessPlayback: true,
          ),
        ),
        SizedBox(height: dense ? 0 : 2),
        Text(
          'Qmatch',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontSize: wordmarkSize,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
        ),
        SizedBox(height: dense ? 5 : 7),
        Text(
          tagline,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: const Color(0xFFD4B06A),
            fontSize: dense ? 8.5 : 9.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.4,
          ),
        ),
      ],
    );
  }
}

class _Cues extends StatelessWidget {
  const _Cues({
    required this.iconSize,
    required this.a,
    required this.b,
    required this.c,
  });

  final double iconSize;
  final String a;
  final String b;
  final String c;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Cue(Icons.psychology, a, iconSize)),
        Expanded(child: _Cue(Icons.favorite_border_rounded, b, iconSize)),
        Expanded(child: _Cue(Icons.graphic_eq_rounded, c, iconSize)),
      ],
    );
  }
}

class _Cue extends StatelessWidget {
  const _Cue(this.icon, this.label, this.size);
  final IconData icon;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x33101830),
            border: Border.all(color: const Color(0xC4B07CFF), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9B4DFF).withValues(alpha: 0.55),
                blurRadius: 16,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Icon(
            icon,
            size: size * 0.48,
            color: const Color(0xFFE8DCFF),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.96),
            fontSize: 10,
            fontWeight: FontWeight.w500,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.size});
  final double size;

  /// Open nebula couple — no center black disc.
  static const _asset = 'assets/images/welcome_couple_v3.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Soft ambient glow — no hard disc.
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              width: size * 0.48,
              height: size * 0.48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x449B4DFF),
                    Color(0x00000000),
                  ],
                ),
              ),
            ),
          ),
          Image.asset(
            _asset,
            width: size,
            height: size,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          ),
        ],
      ),
    );
  }
}

class _Cta extends StatelessWidget {
  const _Cta({
    required this.label,
    required this.height,
    required this.onTap,
  });

  final String label;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.pillBorder,
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4A1FE0),
            Color(0xFF8B4DFF),
            Color(0xFFE0A84A),
            Color(0xFFF5C94C),
          ],
          stops: [0.0, 0.38, 0.74, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5C94C).withValues(alpha: 0.38),
            blurRadius: 20,
            offset: const Offset(6, 4),
          ),
          BoxShadow(
            color: const Color(0xFF8B4DFF).withValues(alpha: 0.32),
            blurRadius: 16,
            offset: const Offset(-4, 4),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.pillBorder,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Container(
                    width: height - 14,
                    height: height - 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.28),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: const Icon(
                      Icons.phone_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginLink extends StatelessWidget {
  const _LoginLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: const Color(0xFFC4B0FF),
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline,
            decorationColor: const Color(0x99C4B0FF),
          ),
        ),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow({
    required this.compact,
    required this.t1,
    required this.b1,
    required this.t2,
    required this.b2,
    required this.t3,
    required this.b3,
  });

  final bool compact;
  final String t1;
  final String b1;
  final String t2;
  final String b2;
  final String t3;
  final String b3;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Card(
            Icons.verified_user_outlined,
            t1,
            b1,
            const Color(0xFFE8C878),
            compact,
          ),
        ),
        SizedBox(width: compact ? 6.0 : 8.0),
        Expanded(
          child: _Card(
            Icons.hub_outlined,
            t2,
            b2,
            const Color(0xFFB07CFF),
            compact,
          ),
        ),
        SizedBox(width: compact ? 6.0 : 8.0),
        Expanded(
          child: _Card(
            Icons.favorite_border_rounded,
            t3,
            b3,
            const Color(0xFF7EB6FF),
            compact,
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card(this.icon, this.title, this.body, this.color, this.compact);
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pad = compact ? 7.0 : 9.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.fromLTRB(6, pad, 6, pad),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0x55101828),
            border: Border.all(color: const Color(0x99B07CFF), width: 0.9),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: compact ? 15 : 17, color: color),
              SizedBox(height: compact ? 4 : 5),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: compact ? 9.5 : 10,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
              SizedBox(height: compact ? 2 : 3),
              Text(
                body,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFFA8A0C0),
                  fontSize: compact ? 7.5 : 8,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalFooter extends StatelessWidget {
  const _LegalFooter({
    required this.prefix,
    required this.terms,
    required this.andWord,
    required this.privacy,
    required this.suffix,
  });

  final String prefix;
  final String terms;
  final String andWord;
  final String privacy;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4B06A);
    final base = GoogleFonts.inter(
      color: Colors.white.withValues(alpha: 0.42),
      fontSize: 8.5,
      height: 1.3,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            Icons.shield_outlined,
            size: 11,
            color: Colors.white.withValues(alpha: 0.42),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: base,
              children: [
                TextSpan(text: prefix),
                TextSpan(
                  text: terms,
                  style: base.copyWith(
                    color: gold,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(text: andWord),
                TextSpan(
                  text: privacy,
                  style: base.copyWith(
                    color: gold,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(text: suffix),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
