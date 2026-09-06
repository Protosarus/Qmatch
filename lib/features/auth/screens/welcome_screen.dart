import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/navigation/auth_navigation.dart';
import '../../../core/services/auth_provider_resolver.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/pending_provider_link.dart';
import '../../../core/theme/app_radii.dart';
import '../../../l10n/app_localizations.dart';
import '../apple_sign_in_flow.dart';
import '../google_sign_in_flow.dart';
import '../provider_link_flow.dart';
import 'email_signup_screen.dart';
import 'login_screen.dart';
import 'phone_signup_screen.dart';
import 'provider_collision_screen.dart';

typedef WelcomeGoogleSignIn = Future<GoogleSignInAttempt> Function();
typedef WelcomeAppleSignIn = Future<AppleSignInAttempt> Function();

/// Welcome — layered cosmic assets + Flutter UI.
/// Locked to reference composition; responsive across phone sizes.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    this.authService,
    this.signInWithGoogle,
    this.signInWithApple,
    this.showAppleButton,
  });

  final AuthService? authService;
  final WelcomeGoogleSignIn? signInWithGoogle;
  final WelcomeAppleSignIn? signInWithApple;

  /// Test / platform override. Production leaves null and gates to iOS/macOS.
  final bool? showAppleButton;

  static const Key googleButtonKey = Key('qmatch-welcome-google');
  static const Key googleErrorKey = Key('qmatch-welcome-google-error');
  static const Key appleButtonKey = Key('qmatch-welcome-apple');
  static const Key appleErrorKey = Key('qmatch-welcome-apple-error');
  static const Key heroKey = Key('qmatch-welcome-hero');

  static const _maxContentWidth = 430.0;

  /// Last pass already applied 0.82 to the original budget. This pass reduces
  /// that current size by another ~18% so the couple stays secondary.
  static const double _heroFromOriginal = 0.82 * 0.82;

  @visibleForTesting
  static double resolveHeroSize({
    required double safeHeight,
    required double contentWidth,
  }) {
    final tiny = safeHeight < 640;
    final short = safeHeight < 720;
    final budget = safeHeight *
        (tiny
            ? 0.36
            : short
                ? 0.40
                : 0.45) *
        _heroFromOriginal;
    final maxExtent =
        ((math.min(contentWidth, _maxContentWidth) * 0.96).clamp(220.0, 390.0)) *
            _heroFromOriginal;
    return budget.clamp(140.0, maxExtent);
  }

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

enum _AuthLoadingProvider {
  // Phone CTA has no in-button spinner today.
  // ignore: unused_field
  phone,
  google,
  apple,
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const _errorHold = Duration(milliseconds: 1500);
  static const _errorFadeOut = Duration(milliseconds: 200);

  _AuthLoadingProvider? _loadingProvider;
  bool _socialLocked = false;
  String? _googleError;
  String? _appleError;
  bool _errorFading = false;
  Timer? _errorDismissTimer;
  late bool _showApple;

  AuthService get _auth => widget.authService ?? AuthService();

  bool get _busy => _loadingProvider != null;

  @override
  void initState() {
    super.initState();
    _showApple =
        widget.showAppleButton ?? AppleSignInFlow.isNativeApplePlatform;
  }

  @override
  void dispose() {
    _errorDismissTimer?.cancel();
    super.dispose();
  }

  void _cancelErrorDismiss() {
    _errorDismissTimer?.cancel();
    _errorDismissTimer = null;
  }

  void _presentWelcomeError({String? google, String? apple}) {
    _cancelErrorDismiss();
    if (!mounted) return;
    setState(() {
      _googleError = google;
      _appleError = apple;
      _errorFading = false;
    });
    _errorDismissTimer = Timer(_errorHold, () {
      if (!mounted) return;
      setState(() => _errorFading = true);
      _errorDismissTimer = Timer(_errorFadeOut, () {
        if (!mounted) return;
        setState(() {
          _googleError = null;
          _appleError = null;
          _errorFading = false;
        });
      });
    });
  }

  void _goPhone() {
    if (_busy) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PhoneSignupScreen()),
    );
  }

  void _goLogin() {
    if (_busy) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _openCollision(String attemptedProvider) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProviderCollisionScreen(
          attemptedProvider: attemptedProvider,
          emailHint: PendingProviderLinkStore.current?.emailHint,
          showAppleButton: _showApple,
          authService: widget.authService,
          signInWithGoogle: widget.signInWithGoogle,
          signInWithApple: widget.signInWithApple,
        ),
      ),
    );
  }

  Future<void> _completeExistingAuth() async {
    final l10n = AppLocalizations.of(context)!;
    final linked = await _auth.linkPendingCredential();
    if (!mounted) return;
    if (linked.isFailed) {
      final message = linked.error == null
          ? l10n.providerLinkErrorFailed
          : ProviderLinkFlow.mapAuthError(l10n, linked.error!);
      _presentWelcomeError(google: message);
    }
    AuthNavigation.completeAuthentication(context);
  }

  void _goEmailSignup() {
    if (_busy) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmailSignupScreen()),
    );
  }

  Future<void> _handleGoogle() async {
    if (_socialLocked || _loadingProvider != null) return;
    _socialLocked = true;
    _cancelErrorDismiss();
    setState(() {
      _loadingProvider = _AuthLoadingProvider.google;
      _googleError = null;
      _appleError = null;
      _errorFading = false;
    });
    try {
      final signIn = widget.signInWithGoogle ?? _auth.signInWithGoogle;
      final attempt = await signIn();
      if (!mounted) return;
      if (attempt.isCancelled) return;
      if (attempt.isCollision ||
          attempt.error?.code == 'account-exists-with-different-credential') {
        await _openCollision(AuthProviderResolver.googleProviderId);
        return;
      }
      if (attempt.isSuccess) {
        await _completeExistingAuth();
        return;
      }
      final error = attempt.error;
      final l10n = AppLocalizations.of(context)!;
      _presentWelcomeError(
        google: error == null
            ? l10n.googleSignInErrorFailed
            : GoogleSignInFlow.mapAuthError(l10n, error),
      );
    } catch (_) {
      if (!mounted) return;
      _presentWelcomeError(
        google: AppLocalizations.of(context)!.googleSignInErrorFailed,
      );
    } finally {
      _socialLocked = false;
      if (mounted) {
        setState(() => _loadingProvider = null);
      }
    }
  }

  Future<void> _handleApple() async {
    if (_socialLocked || _loadingProvider != null) return;
    _socialLocked = true;
    _cancelErrorDismiss();
    setState(() {
      _loadingProvider = _AuthLoadingProvider.apple;
      _googleError = null;
      _appleError = null;
      _errorFading = false;
    });
    try {
      final signIn = widget.signInWithApple ?? _auth.signInWithApple;
      final attempt = await signIn();
      if (!mounted) return;
      if (attempt.isCancelled) return;
      if (attempt.isCollision ||
          attempt.error?.code == 'account-exists-with-different-credential') {
        await _openCollision(AuthProviderResolver.appleProviderId);
        return;
      }
      if (attempt.isSuccess) {
        await _completeExistingAuth();
        return;
      }
      final error = attempt.error;
      final l10n = AppLocalizations.of(context)!;
      _presentWelcomeError(
        apple: error == null
            ? l10n.appleSignInErrorFailed
            : AppleSignInFlow.mapAuthError(l10n, error),
      );
    } catch (_) {
      if (!mounted) return;
      _presentWelcomeError(
        apple: AppLocalizations.of(context)!.appleSignInErrorFailed,
      );
    } finally {
      _socialLocked = false;
      if (mounted) {
        setState(() => _loadingProvider = null);
      }
    }
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
                  final contentW = math.min(w, WelcomeScreen._maxContentWidth);
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
                  final heroSize = WelcomeScreen.resolveHeroSize(
                    safeHeight: h,
                    contentWidth: contentW,
                  );

                  final gapBrandCues = dense ? 8.0 : 10.0;
                  final gapCuesHero = 0.0;
                  final gapHeroCta = dense ? 8.0 : 12.0;
                  final gapCtaEmail = dense ? 8.0 : 10.0;
                  final gapStackEmail = dense ? 12.0 : 14.0;
                  final gapEmailLegal = dense ? 10.0 : 12.0;

                  final stack = <Widget>[
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
                    if (heroSize >= 140)
                      _Hero(
                        key: WelcomeScreen.heroKey,
                        size: heroSize,
                      ),
                    SizedBox(height: gapHeroCta),
                    _Cta(
                      label: l10n.welcomeContinueWithPhone,
                      height: ctaH,
                      enabled: !_busy,
                      onTap: _goPhone,
                    ),
                    SizedBox(height: gapCtaEmail),
                    _GoogleCta(
                      key: WelcomeScreen.googleButtonKey,
                      label: l10n.welcomeContinueWithGoogle,
                      height: ctaH,
                      loading:
                          _loadingProvider == _AuthLoadingProvider.google,
                      enabled: !_busy,
                      onTap: _handleGoogle,
                    ),
                    if (_showApple) ...[
                      SizedBox(height: gapCtaEmail),
                      _AppleCta(
                        key: WelcomeScreen.appleButtonKey,
                        label: l10n.welcomeContinueWithApple,
                        height: ctaH,
                        loading:
                            _loadingProvider == _AuthLoadingProvider.apple,
                        enabled: !_busy,
                        onTap: _handleApple,
                      ),
                    ],
                    if (_googleError != null) ...[
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        opacity: _errorFading ? 0 : 1,
                        duration: _errorFadeOut,
                        curve: Curves.easeOutCubic,
                        child: _AuthErrorBanner(
                          key: WelcomeScreen.googleErrorKey,
                          message: _googleError!,
                        ),
                      ),
                    ],
                    if (_appleError != null) ...[
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        opacity: _errorFading ? 0 : 1,
                        duration: _errorFadeOut,
                        curve: Curves.easeOutCubic,
                        child: _AuthErrorBanner(
                          key: WelcomeScreen.appleErrorKey,
                          message: _appleError!,
                        ),
                      ),
                    ],
                    SizedBox(height: gapStackEmail),
                    _LoginLink(
                      key: const Key('qmatch-welcome-email-signup'),
                      label: l10n.welcomeSignUpWithEmail,
                      enabled: !_busy,
                      onTap: _goEmailSignup,
                    ),
                    _LoginLink(
                      key: const Key('qmatch-welcome-email-login'),
                      label: l10n.welcomeLogInWithEmail,
                      enabled: !_busy,
                      onTap: _goLogin,
                    ),
                    SizedBox(height: gapEmailLegal),
                    _LegalFooter(
                      prefix: l10n.welcomeLegalPrefix,
                      terms: l10n.welcomeTermsOfService,
                      andWord: l10n.welcomeLegalAnd,
                      privacy: l10n.welcomePrivacyPolicy,
                      suffix: l10n.welcomeLegalSuffix,
                    ),
                  ];

                  // SafeArea owns the home-indicator inset. Only a light
                  // content pad remains so we do not double-count the bottom.
                  final pad = EdgeInsets.fromLTRB(
                    padH,
                    dense ? 2 : 6,
                    padH,
                    4,
                  );

                  return Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentW),
                        child: Padding(
                          padding: pad,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: stack,
                          ),
                        ),
                      ),
                    ),
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
          'QMatch',
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

class _Hero extends StatefulWidget {
  const _Hero({super.key, required this.size});
  final double size;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with SingleTickerProviderStateMixin {
  /// Open nebula couple — no center black disc.
  static const _asset = 'assets/images/welcome_couple_v3.png';

  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations == true;

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
          // Point spark only — no circular disc/ring overlay.
          if (!reduceMotion)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _breath,
                builder: (context, _) {
                  final t = Curves.easeInOut.transform(_breath.value);
                  return CustomPaint(
                    size: Size(size, size),
                    painter: _CenterSparkPainter(t: t),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CenterSparkPainter extends CustomPainter {
  _CenterSparkPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    // Hot core — tiny; breath = brightness only.
    final coreR = size.shortestSide * 0.012;
    final glowR = size.shortestSide * 0.028;

    final glow = Paint()
      ..color = Color.fromRGBO(255, 236, 180, 0.20 + t * 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(c, glowR, glow);

    final core = Paint()
      ..color = Color.fromRGBO(255, 252, 245, 0.35 + t * 0.60)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawCircle(c, coreR, core);

    // Soft rays — fade at ends, no ring.
    final ray = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.0 + t * 0.5
      ..color = Color.fromRGBO(255, 248, 230, 0.18 + t * 0.50)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    final arm = size.shortestSide * 0.045;
    canvas.drawLine(c.translate(-arm, 0), c.translate(arm, 0), ray);
    canvas.drawLine(c.translate(0, -arm), c.translate(0, arm), ray);

    ray
      ..strokeWidth = 0.7 + t * 0.35
      ..color = Color.fromRGBO(255, 230, 160, 0.10 + t * 0.32);
    final diag = arm * 0.55;
    canvas.drawLine(
      c.translate(-diag, -diag),
      c.translate(diag, diag),
      ray,
    );
    canvas.drawLine(
      c.translate(-diag, diag),
      c.translate(diag, -diag),
      ray,
    );
  }

  @override
  bool shouldRepaint(covariant _CenterSparkPainter oldDelegate) =>
      oldDelegate.t != t;
}

/// Shared geometry so Phone / Google / Apple CTAs stay aligned.
class _AuthCtaLayout {
  static const double horizontalPadding = 10;
  static const double labelSize = 15.5;
  static const double iconSize = 18;
  static const double trailingSlot = 22;

  static double leadingSlot(double height) => height - 14;
}

class _AuthCtaRow extends StatelessWidget {
  const _AuthCtaRow({
    required this.height,
    required this.leading,
    required this.label,
    required this.labelColor,
    this.trailing,
  });

  final double height;
  final Widget leading;
  final String label;
  final Color labelColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final slot = _AuthCtaLayout.leadingSlot(height);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _AuthCtaLayout.horizontalPadding,
        ),
        child: Row(
          children: [
            SizedBox(
              width: slot,
              height: slot,
              child: leading,
            ),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    color: labelColor,
                    fontSize: _AuthCtaLayout.labelSize,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _AuthCtaLayout.trailingSlot,
              child: trailing,
            ),
          ],
        ),
      ),
    );
  }
}

class _Cta extends StatelessWidget {
  const _Cta({
    required this.label,
    required this.height,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final double height;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadii.pillBorder,
          gradient: const LinearGradient(
            colors: [
              Color(0xFF5A2BEA),
              Color(0xFF8B4CF6),
              Color(0xFFE9B83F),
            ],
            stops: [0.0, 0.46, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE9B83F).withValues(alpha: 0.26),
              blurRadius: 18,
              offset: const Offset(6, 4),
            ),
            BoxShadow(
              color: const Color(0xFF8B4CF6).withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(-4, 4),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: AppRadii.pillBorder,
            child: _AuthCtaRow(
              height: height,
              label: label,
              labelColor: Colors.white,
              leading: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.28),
                  border: Border.all(color: Colors.white30),
                ),
                child: const Icon(
                  Icons.phone_rounded,
                  color: Colors.white,
                  size: _AuthCtaLayout.iconSize,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: _AuthCtaLayout.iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleCta extends StatelessWidget {
  const _GoogleCta({
    super.key,
    required this.label,
    required this.height,
    required this.onTap,
    required this.loading,
    required this.enabled,
  });

  final String label;
  final double height;
  final VoidCallback onTap;
  final bool loading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.pillBorder,
        color: const Color.fromRGBO(17, 12, 35, 0.88),
        border: Border.all(
          color: const Color.fromRGBO(190, 151, 255, 0.55),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled && !loading ? onTap : null,
          borderRadius: AppRadii.pillBorder,
          child: _AuthCtaRow(
            height: height,
            label: label,
            labelColor: const Color(0xFFF6F2FF),
            leading: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              alignment: Alignment.center,
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF4285F4),
                        ),
                      ),
                    )
                  : const _GoogleMark(),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.18;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.square;
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.2, 1.6, false, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 1.4, 1.3, false, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.7, 1.0, false, paint);
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.7, 1.4, false, paint);
    final bar = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.50),
      Offset(size.width - stroke / 2, size.height * 0.50),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AuthErrorBanner extends StatelessWidget {
  const _AuthErrorBanner({
    super.key,
    required this.message,
  });

  final String message;

  static const _background = Color.fromRGBO(74, 15, 35, 0.78);
  static const _border = Color.fromRGBO(255, 92, 115, 0.75);
  static const _foreground = Color(0xFFFF7488);
  static const _glow = Color.fromRGBO(255, 75, 105, 0.18);
  static const _entry = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: ClipRect(
        child: TweenAnimationBuilder<double>(
          duration: _entry,
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, t, child) {
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 6 * (1 - t)),
                child: child,
              ),
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadii.buttonBorder,
              color: _background,
              border: Border.all(color: _border, width: 1.1),
              boxShadow: const [
                BoxShadow(
                  color: _glow,
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ExcludeSemantics(
                    child: Icon(
                      Icons.error_outline_rounded,
                      color: _foreground,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      textAlign: TextAlign.start,
                      softWrap: true,
                      style: GoogleFonts.inter(
                        color: _foreground,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppleCta extends StatelessWidget {
  const _AppleCta({
    super.key,
    required this.label,
    required this.height,
    required this.onTap,
    required this.loading,
    required this.enabled,
  });

  final String label;
  final double height;
  final VoidCallback onTap;
  final bool loading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.pillBorder,
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled && !loading ? onTap : null,
          borderRadius: AppRadii.pillBorder,
          child: _AuthCtaRow(
            height: height,
            label: label,
            labelColor: Colors.white,
            leading: loading
                ? const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : const _AppleMark(),
          ),
        ),
      ),
    );
  }
}

class _AppleMark extends StatelessWidget {
  const _AppleMark();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.apple,
      color: Colors.white,
      size: 22,
    );
  }
}


class _LoginLink extends StatelessWidget {
  const _LoginLink({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
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
      color: Colors.white.withValues(alpha: 0.58),
      fontSize: 9,
      height: 1.35,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            Icons.shield_outlined,
            size: 11,
            color: Colors.white.withValues(alpha: 0.58),
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
