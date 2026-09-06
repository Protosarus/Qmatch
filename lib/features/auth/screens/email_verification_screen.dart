import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/navigation/auth_routing_refresh.dart';
import '../../../core/services/auth_provider_resolver.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/email_verification_policy.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radii.dart';
import '../../../l10n/app_localizations.dart';
import '../email_verification_flow.dart';
import '../provider_link_flow.dart';
import '../widgets/auth_keyboard_dismiss.dart';
import '../widgets/auth_world_map_accent.dart';

typedef EmailVerificationCheck = Future<bool> Function();
typedef EmailVerificationAction = Future<void> Function();

/// Password-account email-verification gate. Shown by the root [AuthWrapper].
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    this.email,
    this.authService,
    this.checkVerified,
    this.resend,
    this.signOut,
    this.onVerified,
    this.refreshIdToken,
    this.resendCooldown,
    this.completePendingLink,
  });

  final String? email;
  final AuthService? authService;
  final EmailVerificationCheck? checkVerified;
  final EmailVerificationAction? resend;
  final EmailVerificationAction? signOut;
  final VoidCallback? onVerified;
  final EmailVerificationAction? refreshIdToken;
  final Duration? resendCooldown;
  final Future<ProviderLinkAttempt> Function()? completePendingLink;

  static const Key checkKey = Key('qmatch-email-verification-check');
  static const Key resendKey = Key('qmatch-email-verification-resend');
  static const Key signOutKey = Key('qmatch-email-verification-sign-out');
  static const Key bannerKey = Key('qmatch-email-verification-banner');
  static const Key emailKey = Key('qmatch-email-verification-email');

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const Color _accentLavender = Color(0xFFDAC8ED);

  bool _checking = false;
  bool _resending = false;
  bool _signingOut = false;
  String? _banner;
  bool _bannerError = false;
  DateTime? _resendAvailableAt;
  Timer? _cooldownTicker;

  Duration get _cooldown =>
      widget.resendCooldown ?? EmailVerificationFlow.resendCooldown;

  AuthService get _auth => widget.authService ?? AuthService();

  bool get _busy => _checking || _resending || _signingOut;

  int get _cooldownSecondsLeft {
    final until = _resendAvailableAt;
    if (until == null) return 0;
    final leftMs = until.difference(DateTime.now()).inMilliseconds;
    if (leftMs <= 0) return 0;
    return (leftMs / 1000).ceil();
  }

  @override
  void dispose() {
    _cooldownTicker?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _resendAvailableAt = DateTime.now().add(_cooldown);
    _cooldownTicker?.cancel();
    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSecondsLeft <= 0) {
        timer.cancel();
        setState(() => _resendAvailableAt = null);
        return;
      }
      setState(() {});
    });
    setState(() {});
  }

  Future<bool> _defaultCheckVerified() async {
    final auth = _auth;
    await auth.currentUser?.reload();
    final fresh = auth.currentUser;
    if (fresh == null) return false;
    return !EmailVerificationPolicy.requiresEmailVerificationForUser(fresh);
  }

  Future<void> _defaultRefreshIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await EmailVerificationFlow.forceRefreshIdToken(user);
  }

  Future<void> _handleCheck() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _checking = true;
      _banner = null;
    });
    try {
      final check = widget.checkVerified ?? _defaultCheckVerified;
      final verified = await check();
      if (!mounted) return;
      if (verified) {
        final refresh = widget.refreshIdToken ?? _defaultRefreshIdToken;
        await refresh();
        if (!mounted) return;
        final link = widget.completePendingLink ??
            () => _auth.linkPendingCredential(
                  currentSignInProvider:
                      AuthProviderResolver.passwordProviderId,
                  emailVerified: true,
                );
        await link();
        if (!mounted) return;
        final onVerified = widget.onVerified ?? AuthRoutingRefresh.bump;
        onVerified();
        return;
      }
      setState(() {
        _banner = l10n.emailVerificationStillPending;
        _bannerError = true;
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _banner = EmailVerificationFlow.mapAuthError(l10n, error);
        _bannerError = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _banner = l10n.emailVerificationFailed;
        _bannerError = true;
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _handleResend() async {
    if (_busy || _cooldownSecondsLeft > 0) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _resending = true;
      _banner = null;
    });
    try {
      final resend = widget.resend ?? _auth.resendVerificationEmail;
      await resend();
      if (!mounted) return;
      _startCooldown();
      setState(() {
        _banner = l10n.emailVerificationResendSent;
        _bannerError = false;
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _banner = EmailVerificationFlow.mapAuthError(l10n, error);
        _bannerError = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _banner = l10n.emailVerificationFailed;
        _bannerError = true;
      });
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _handleSignOut() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _signingOut = true;
      _banner = null;
    });
    try {
      final signOut = widget.signOut ?? _auth.signOut;
      await signOut();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _banner = EmailVerificationFlow.mapAuthError(l10n, error);
        _bannerError = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _banner = l10n.emailVerificationFailed;
        _bannerError = true;
      });
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final email = widget.email?.trim() ?? '';
    final cooldown = _cooldownSecondsLeft;
    final resendEnabled = !_busy && cooldown <= 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: AuthKeyboardDismiss(
        child: Scaffold(
          backgroundColor: AppColors.midnightNavy,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const _VerificationCosmicBackdrop(),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final padH =
                        (constraints.maxWidth * 0.06).clamp(20.0, 28.0);
                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(padH, 16, padH, 16),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 430),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: Image.asset(
                                      'assets/images/welcome_q_glow.png',
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.emailVerificationTitle,
                                    style: GoogleFonts.playfairDisplay(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w600,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    email.isEmpty
                                        ? l10n.emailVerificationBody
                                        : l10n.emailVerificationBodyWithEmail(
                                            email,
                                          ),
                                    key: EmailVerificationScreen.emailKey,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFC8C0E0),
                                      fontSize: 14,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  if (_banner != null) ...[
                                    Container(
                                      key: EmailVerificationScreen.bannerKey,
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: AppRadii.buttonBorder,
                                        color: (_bannerError
                                                ? AppColors.error
                                                : AppColors.resonanceViolet)
                                            .withValues(alpha: 0.12),
                                        border: Border.all(
                                          color: (_bannerError
                                                  ? AppColors.error
                                                  : _accentLavender)
                                              .withValues(alpha: 0.45),
                                        ),
                                      ),
                                      child: Text(
                                        _banner!,
                                        style: GoogleFonts.inter(
                                          color: _bannerError
                                              ? AppColors.error
                                                  .withValues(alpha: 0.95)
                                              : const Color(0xFFE8E0FF),
                                          fontSize: 13,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                  ],
                                  const IgnorePointer(
                                    child: AuthWorldMapAccent(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(padH, 8, padH, 12),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 430),
                            child: Column(
                              children: [
                                _CosmicCtaButton(
                                  key: EmailVerificationScreen.checkKey,
                                  loading: _checking,
                                  label: l10n.emailVerificationCheck,
                                  onPressed: _busy ? null : _handleCheck,
                                ),
                                const SizedBox(height: 10),
                                TextButton(
                                  key: EmailVerificationScreen.resendKey,
                                  onPressed:
                                      resendEnabled ? _handleResend : null,
                                  child: _resending
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              _accentLavender,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          cooldown > 0
                                              ? l10n
                                                  .emailVerificationResendCooldown(
                                                  cooldown,
                                                )
                                              : l10n.emailVerificationResend,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            color: resendEnabled
                                                ? _accentLavender
                                                : const Color(0xFF8A82A8),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                                TextButton(
                                  key: EmailVerificationScreen.signOutKey,
                                  onPressed: _busy ? null : _handleSignOut,
                                  child: Text(
                                    l10n.emailVerificationSignOut,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFA8A0C0),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationCosmicBackdrop extends StatelessWidget {
  const _VerificationCosmicBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.cosmicBackgroundGradient,
            ),
          ),
          Positioned(
            top: -40,
            left: -30,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.electricBlue.withValues(alpha: 0.14),
                ),
              ),
            ),
          ),
          Positioned(
            top: -70,
            right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.resonanceViolet.withValues(alpha: 0.32),
                ),
              ),
            ),
          ),
          const CustomPaint(painter: _StarFieldPainter()),
        ],
      ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 48; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final r = rnd.nextDouble() * 1.15 + 0.35;
      final a = 0.18 + rnd.nextDouble() * 0.45;
      paint.color = Color.fromRGBO(230, 225, 255, a);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CosmicCtaButton extends StatelessWidget {
  const _CosmicCtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.loading,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.pillBorder,
        gradient: AppGradients.cosmicCtaGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.softGold.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(4, 5),
          ),
          BoxShadow(
            color: AppColors.resonanceViolet.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(-3, 4),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadii.pillBorder,
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
