import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/navigation/auth_navigation.dart';
import '../../../core/services/auth_provider_resolver.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/pending_provider_link.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radii.dart';
import '../../../l10n/app_localizations.dart';
import '../apple_sign_in_flow.dart';
import '../google_sign_in_flow.dart';
import '../provider_link_flow.dart';
import '../widgets/auth_world_map_accent.dart';
import 'login_screen.dart';

/// Safe collision recovery: authenticate the existing QMatch account, then
/// link the memory-only pending OAuth credential to that same Firebase UID.
class ProviderCollisionScreen extends StatefulWidget {
  const ProviderCollisionScreen({
    super.key,
    required this.attemptedProvider,
    this.emailHint,
    this.showAppleButton,
    this.authService,
    this.signInWithGoogle,
    this.signInWithApple,
    this.completePendingLink,
  });

  final String attemptedProvider;
  final String? emailHint;
  final bool? showAppleButton;
  final AuthService? authService;
  final Future<GoogleSignInAttempt> Function()? signInWithGoogle;
  final Future<AppleSignInAttempt> Function()? signInWithApple;
  final Future<ProviderLinkAttempt> Function()? completePendingLink;

  static const Key emailButtonKey = Key('qmatch-collision-continue-email');
  static const Key googleButtonKey = Key('qmatch-collision-continue-google');
  static const Key appleButtonKey = Key('qmatch-collision-continue-apple');
  static const Key cancelButtonKey = Key('qmatch-collision-cancel');
  static const Key errorKey = Key('qmatch-collision-error');
  static const Key emailHintKey = Key('qmatch-collision-email-hint');

  @override
  State<ProviderCollisionScreen> createState() =>
      _ProviderCollisionScreenState();
}

class _ProviderCollisionScreenState extends State<ProviderCollisionScreen> {
  static const Color _accentLavender = Color(0xFFDAC8ED);

  bool _busy = false;
  String? _error;
  late bool _showApple;

  AuthService get _auth => widget.authService ?? AuthService();

  @override
  void initState() {
    super.initState();
    _showApple =
        widget.showAppleButton ?? AppleSignInFlow.isNativeApplePlatform;
  }

  bool get _attemptedGoogle =>
      widget.attemptedProvider == AuthProviderResolver.googleProviderId;

  bool get _attemptedApple =>
      widget.attemptedProvider == AuthProviderResolver.appleProviderId;

  Future<ProviderLinkAttempt> _linkPending() {
    return (widget.completePendingLink ?? _auth.linkPendingCredential)();
  }

  Future<void> _finishExistingAuth() async {
    final l10n = AppLocalizations.of(context)!;
    final linked = await _linkPending();
    if (!mounted) return;
    if (linked.isFailed) {
      setState(() {
        _error = linked.error == null
            ? l10n.providerLinkErrorFailed
            : ProviderLinkFlow.mapAuthError(l10n, linked.error!);
      });
    }
    if (!mounted) return;
    AuthNavigation.completeAuthentication(context);
  }

  void _cancel() {
    PendingProviderLinkStore.clear();
    if (mounted) Navigator.of(context).maybePop();
  }

  void _continueEmail() {
    if (_busy) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(
          initialEmail: widget.emailHint,
          completePendingLink: widget.completePendingLink,
        ),
      ),
    );
  }

  Future<void> _continueGoogle() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final signIn = widget.signInWithGoogle ?? _auth.signInWithGoogle;
      final attempt = await signIn();
      if (!mounted) return;
      if (attempt.isCancelled) return;
      if (attempt.isCollision) {
        setState(() {
          _error = AppLocalizations.of(context)!.providerLinkErrorFailed;
        });
        return;
      }
      if (attempt.isSuccess) {
        await _finishExistingAuth();
        return;
      }
      final error = attempt.error;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _error = error == null
            ? l10n.googleSignInErrorFailed
            : GoogleSignInFlow.mapAuthError(l10n, error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.googleSignInErrorFailed;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continueApple() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final signIn = widget.signInWithApple ?? _auth.signInWithApple;
      final attempt = await signIn();
      if (!mounted) return;
      if (attempt.isCancelled) return;
      if (attempt.isCollision) {
        setState(() {
          _error = AppLocalizations.of(context)!.providerLinkErrorFailed;
        });
        return;
      }
      if (attempt.isSuccess) {
        await _finishExistingAuth();
        return;
      }
      final error = attempt.error;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _error = error == null
            ? l10n.appleSignInErrorFailed
            : AppleSignInFlow.mapAuthError(l10n, error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.appleSignInErrorFailed;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hint = widget.emailHint?.trim() ?? '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.midnightNavy,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _CollisionCosmicBackdrop(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final padH = (constraints.maxWidth * 0.06).clamp(20.0, 28.0);
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
                                  l10n.providerCollisionTitle,
                                  style: GoogleFonts.playfairDisplay(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w600,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l10n.providerCollisionBody,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFC8C0E0),
                                    fontSize: 14,
                                    height: 1.45,
                                  ),
                                ),
                                if (hint.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    hint,
                                    key: ProviderCollisionScreen.emailHintKey,
                                    style: GoogleFonts.inter(
                                      color: _accentLavender,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                if (_error != null) ...[
                                  Container(
                                    key: ProviderCollisionScreen.errorKey,
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: AppRadii.buttonBorder,
                                      color: AppColors.error
                                          .withValues(alpha: 0.12),
                                      border: Border.all(
                                        color: AppColors.error
                                            .withValues(alpha: 0.45),
                                      ),
                                    ),
                                    child: Text(
                                      _error!,
                                      style: GoogleFonts.inter(
                                        color: AppColors.error
                                            .withValues(alpha: 0.95),
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
                              _CollisionCta(
                                key: ProviderCollisionScreen.emailButtonKey,
                                label: l10n.providerCollisionContinueEmail,
                                loading: false,
                                onPressed: _busy ? null : _continueEmail,
                              ),
                              if (!_attemptedGoogle) ...[
                                const SizedBox(height: 10),
                                _CollisionCta(
                                  key: ProviderCollisionScreen.googleButtonKey,
                                  label: l10n.providerCollisionContinueGoogle,
                                  loading: _busy,
                                  onPressed: _busy ? null : _continueGoogle,
                                ),
                              ],
                              if (_showApple && !_attemptedApple) ...[
                                const SizedBox(height: 10),
                                _CollisionCta(
                                  key: ProviderCollisionScreen.appleButtonKey,
                                  label: l10n.providerCollisionContinueApple,
                                  loading: _busy,
                                  onPressed: _busy ? null : _continueApple,
                                ),
                              ],
                              TextButton(
                                key: ProviderCollisionScreen.cancelButtonKey,
                                onPressed: _busy ? null : _cancel,
                                child: Text(
                                  l10n.providerCollisionCancel,
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
    );
  }
}

class _CollisionCosmicBackdrop extends StatelessWidget {
  const _CollisionCosmicBackdrop();

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

class _CollisionCta extends StatelessWidget {
  const _CollisionCta({
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
