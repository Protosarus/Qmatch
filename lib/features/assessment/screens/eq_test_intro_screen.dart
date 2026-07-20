import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radii.dart';
import '../../../l10n/app_localizations.dart';
import 'eq_test_screen.dart';

/// Cosmic EQ intro — presentation only; navigation unchanged.
class EQTestIntroScreen extends StatelessWidget {
  final int iqScore;

  const EQTestIntroScreen({
    super.key,
    this.iqScore = 0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final h = size.height;
    final compact = h < 700;
    final veryShort = h < 580;
    // Standard phones: 340–410 px hero; only shrink on very short screens.
    final heroH = veryShort
        ? (h * 0.34).clamp(260.0, 340.0)
        : (h * (compact ? 0.38 : 0.40)).clamp(340.0, 410.0);

    final body = Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
      child: Column(
        children: [
          SizedBox(height: compact ? 4 : 8),
          SizedBox(
            width: 56,
            height: 56,
            child: Image.asset(
              'assets/images/welcome_q_glow.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          SizedBox(height: compact ? 6 : 10),
          SizedBox(
            height: heroH,
            width: double.infinity,
            child: const _EqIntroHeroImage(),
          ),
          SizedBox(height: compact ? 10 : 16),
          _EqIntroHeadline(
            lead: l10n.eqIntroHeadlineLead,
            emphasis: l10n.eqIntroHeadlineEmphasis,
            compact: compact,
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            l10n.eqIntroLabel,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFFC4B4E8),
              fontSize: compact ? 13.5 : 14.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.15,
              height: 1.2,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            l10n.eqIntroMeta,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF8E86A8),
              fontSize: compact ? 12.5 : 13,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
              height: 1.35,
            ),
          ),
          const Spacer(),
          _EqStartButton(
            label: l10n.eqIntroStart,
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => EQTestScreen(iqScore: iqScore),
                ),
              );
            },
          ),
          SizedBox(height: compact ? 14 : 20),
        ],
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF06030C),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _EqIntroBackdrop(),
            SafeArea(
              child: veryShort
                  ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: SizedBox(
                        height: h - MediaQuery.paddingOf(context).vertical,
                        child: body,
                      ),
                    )
                  : body,
            ),
          ],
        ),
      ),
    );
  }
}

/// Single transparent EQ hero — figure, brain/heart glow, orbits, symbols only.
class _EqIntroHeroImage extends StatelessWidget {
  const _EqIntroHeroImage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ShaderMask(
        shaderCallback: (bounds) {
          return RadialGradient(
            center: const Alignment(0, -0.02),
            radius: 0.70,
            colors: [
              Colors.white,
              Colors.white.withValues(alpha: 0.90),
              Colors.white.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.60, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: Image.asset(
          'assets/images/eq_intro_hero.png',
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}

class _EqIntroHeadline extends StatelessWidget {
  const _EqIntroHeadline({
    required this.lead,
    required this.emphasis,
    this.compact = false,
  });

  final String lead;
  final String emphasis;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final leadSize = compact ? 30.0 : 34.0;
    final emphasisSize = compact ? 38.0 : 44.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          lead,
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFF2EEE6),
            fontSize: leadSize,
            fontWeight: FontWeight.w500,
            height: 1.05,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 2),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF9B7CFF),
                Color(0xFFC8B0FF),
                Color(0xFFE8D4A8),
              ],
              stops: [0.0, 0.50, 1.0],
            ).createShader(bounds);
          },
          child: Text(
            emphasis,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: emphasisSize,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              height: 1.0,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _EqStartButton extends StatelessWidget {
  const _EqStartButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: AppRadii.pillBorder,
        gradient: AppGradients.cosmicCtaGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.vizEq.withValues(alpha: 0.34),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.softGold.withValues(alpha: 0.20),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadii.pillBorder,
          child: SizedBox(
            height: 56,
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
      ),
    );
  }
}

class _EqIntroBackdrop extends StatelessWidget {
  const _EqIntroBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/welcome_cosmic_background.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.high,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0, 0.25),
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x0C060812),
                  Color(0x33040810),
                  Color(0x6603060C),
                ],
                stops: [0.0, 0.42, 0.72, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
