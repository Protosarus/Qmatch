import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radii.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/eq_question_chrome.dart';
import 'eq_test_screen.dart';

/// Cosmic EQ intro — presentation only; navigation unchanged.
///
/// Layers: cosmic bg → soft readabilty wash → Q → transparent hero → copy → CTA.
class EQTestIntroScreen extends StatelessWidget {
  final int iqScore;

  const EQTestIntroScreen({
    super.key,
    this.iqScore = 0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    final size = media.size;
    final h = size.height;
    final w = size.width;
    final pad = media.padding;

    // Breakpoints for phone heights (logical px).
    final tiny = h < 640;
    final short = h < 720;
    final tall = h >= 860;

    final qSize = tiny ? 48.0 : 56.0;
    final horizontal = (w * 0.06).clamp(20.0, 28.0);

    // Hero scales with viewport; stays within safe visual range on all phones.
    final heroH = tiny
        ? (h * 0.32).clamp(220.0, 300.0)
        : short
            ? (h * 0.38).clamp(300.0, 360.0)
            : tall
                ? (h * 0.42).clamp(400.0, 460.0)
                : (h * 0.40).clamp(340.0, 420.0);

    final body = Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal),
      child: Column(
        children: [
          SizedBox(height: tiny ? 2 : 8),
          SizedBox(
            width: qSize,
            height: qSize,
            child: Image.asset(
              'assets/images/welcome_q_glow.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          SizedBox(height: tiny ? 4 : 8),
          SizedBox(
            height: heroH,
            width: double.infinity,
            child: const EqMindHeartFigure(),
          ),
          SizedBox(height: tiny ? 8 : 12),
          _EqIntroCopyBlock(
            lead: l10n.eqIntroHeadlineLead,
            emphasis: l10n.eqIntroHeadlineEmphasis,
            label: l10n.eqIntroLabel,
            meta: l10n.eqIntroMeta,
            compact: short,
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
          SizedBox(height: tiny ? 12 : 20),
        ],
      ),
    );

    final safeBody = SafeArea(
      child: tiny
          ? LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(child: body),
                  ),
                );
              },
            )
          : body,
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
            // Ensure content never sits under home indicator incorrectly.
            MediaQuery(
              data: media.copyWith(
                // Keep bottom padding for CTA; already in SafeArea.
                padding: pad,
              ),
              child: safeBody,
            ),
          ],
        ),
      ),
    );
  }
}

/// Headline + subtitles with a soft radial scrim for readability.
class _EqIntroCopyBlock extends StatelessWidget {
  const _EqIntroCopyBlock({
    required this.lead,
    required this.emphasis,
    required this.label,
    required this.meta,
    this.compact = false,
  });

  final String lead;
  final String emphasis;
  final String label;
  final String meta;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -28,
          right: -28,
          top: -18,
          bottom: -14,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.95,
                colors: [
                  const Color(0x66100818),
                  const Color(0x33100818),
                  const Color(0x00000000),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _EqIntroHeadline(
              lead: lead,
              emphasis: emphasis,
              compact: compact,
            ),
            SizedBox(height: compact ? 10 : 14),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFFE4DAFA),
                fontSize: compact ? 13.5 : 14.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.15,
                height: 1.2,
              ),
            ),
            SizedBox(height: compact ? 8 : 10),
            Text(
              meta,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFFD0C8E0),
                fontSize: compact ? 12.5 : 13,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.1,
                height: 1.35,
              ),
            ),
          ],
        ),
      ],
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
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Text(
              emphasis,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                color: AppColors.vizEq.withValues(alpha: 0.14),
                fontSize: emphasisSize,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                height: 1.0,
                letterSpacing: 0.2,
                shadows: [
                  Shadow(
                    color: AppColors.vizEq.withValues(alpha: 0.22),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
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
          // Same cosmic atmosphere as the EQ reference (UI-free photo).
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
