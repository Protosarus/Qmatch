import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/navigation/auth_wrapper.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/widgets/elegant_warning.dart';
import '../../../core/widgets/qmatch_glass_icon_button.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/auth_world_map_accent.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _emailFocused = false;
  bool _passwordFocused = false;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (!mounted) return;
      setState(() => _emailFocused = _emailFocus.hasFocus);
    });
    _passwordFocus.addListener(() {
      if (!mounted) return;
      setState(() => _passwordFocused = _passwordFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Cosmic lavender — matches Frequency / profile setup accents (not softGold).
  static const Color _accentLavender = Color(0xFFDAC8ED);

  InputDecoration _fieldDecoration({
    required String label,
    required bool focused,
    Widget? suffixIcon,
  }) {
    final idleBorder = const Color(0x77A890D8);
    final focusBorder = focused ? _accentLavender : idleBorder;
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(
        color: const Color(0xFF9A90B8),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: GoogleFonts.inter(
        color: focused ? _accentLavender : const Color(0xFFB8AED8),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadii.cardBorder,
        borderSide: BorderSide(color: idleBorder, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadii.cardBorder,
        borderSide: BorderSide(color: focusBorder, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadii.cardBorder,
        borderSide: BorderSide(
          color: AppColors.error.withValues(alpha: 0.7),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadii.cardBorder,
        borderSide: BorderSide(
          color: AppColors.error.withValues(alpha: 0.9),
          width: 1.5,
        ),
      ),
      filled: true,
      fillColor: const Color(0xAA141A2E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffixIcon,
    );
  }

  Future<void> _handleLogin() async {
    final l10n = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();
    setState(() => _inlineError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          errorMessage = l10n.loginErrorIncorrectCredentials;
          break;
        case 'invalid-email':
          errorMessage = l10n.loginErrorValidEmailAddress;
          break;
        default:
          errorMessage = l10n.loginErrorFailed;
      }
      if (mounted) {
        setState(() => _inlineError = errorMessage);
        showElegantWarning(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showResetNotice(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          backgroundColor: const Color(0xF5111629),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 105),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: (isError ? AppColors.error : AppColors.resonanceViolet)
                  .withValues(alpha: 0.55),
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: Row(
              children: [
                Icon(
                  isError
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  color: isError ? AppColors.error : _accentLavender,
                  size: 21,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFF3EFFA),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  Future<void> _showForgotPasswordDialog() async {
    final l10n = AppLocalizations.of(context)!;
    var resetEmail = _emailController.text.trim();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var sending = false;
        String? inlineError;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final email = resetEmail.trim().toLowerCase();

              if (email.isEmpty ||
                  !email.contains('@') ||
                  !email.split('@').last.contains('.')) {
                setDialogState(
                  () => inlineError = l10n.resetPasswordInvalidEmail,
                );
                return;
              }

              setDialogState(() {
                sending = true;
                inlineError = null;
              });

              try {
                await AuthService().sendPasswordResetEmail(email);

                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();

                if (!mounted) return;
                _showResetNotice(l10n.resetPasswordSent);
              } on FirebaseAuthException catch (error) {
                if (!dialogContext.mounted) return;

                final message = switch (error.code) {
                  'invalid-email' => l10n.resetPasswordInvalidEmail,
                  'too-many-requests' => l10n.resetPasswordTooManyRequests,
                  'network-request-failed' => l10n.resetPasswordNetworkError,
                  _ => l10n.resetPasswordFailed,
                };

                setDialogState(() {
                  sending = false;
                  inlineError = message;
                });
              } catch (_) {
                if (!dialogContext.mounted) return;
                setDialogState(() {
                  sending = false;
                  inlineError = l10n.resetPasswordFailed;
                });
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xF5111629),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(
                  color: AppColors.resonanceViolet.withValues(alpha: 0.32),
                ),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              title: Text(
                l10n.resetPasswordTitle,
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFF3ECFF),
                  fontSize: 30,
                  height: 1.08,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  shadows: [
                    Shadow(
                      color: AppColors.resonanceViolet.withValues(alpha: 0.30),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.resetPasswordBody,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFD0C9DF),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.55,
                        letterSpacing: 0.05,
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextFormField(
                      key: const Key('qmatch-reset-password-email'),
                      initialValue: resetEmail,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: (value) => resetEmail = value,
                      onFieldSubmitted: sending ? null : (_) => submit(),
                      style: GoogleFonts.inter(
                        color: const Color(0xFFF5F2FA),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      cursorColor: _accentLavender,
                      decoration: InputDecoration(
                        labelText: l10n.email,
                        labelStyle: GoogleFonts.inter(
                          color: const Color(0xFFB8AECF),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        floatingLabelStyle: GoogleFonts.inter(
                          color: _accentLavender,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        errorText: inlineError,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: _accentLavender,
                  ),
                  onPressed:
                      sending ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    l10n.cancel,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FilledButton(
                  key: const Key('qmatch-reset-password-send'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.resonanceViolet,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.resonanceViolet.withValues(alpha: 0.45),
                    disabledForegroundColor:
                        Colors.white.withValues(alpha: 0.70),
                  ),
                  onPressed: sending ? null : submit,
                  child: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.sendResetLink,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _glowField({
    required bool focused,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: AppRadii.cardBorder,
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.resonanceViolet.withValues(alpha: 0.45),
                  blurRadius: 16,
                ),
                BoxShadow(
                  color: _accentLavender.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(2, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
            const _LoginCosmicBackdrop(),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: QMatchGlassIconButton(
                        icon: Icons.arrow_back_ios_new,
                        iconSize: 18,
                        circular: true,
                        tooltip:
                            MaterialLocalizations.of(context).backButtonTooltip,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final padH =
                            (constraints.maxWidth * 0.06).clamp(20.0, 28.0);
                        return SingleChildScrollView(
                          padding: EdgeInsets.only(
                            left: padH,
                            right: padH,
                            bottom: bottomInset + 16,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: math.max(
                                0.0,
                                constraints.maxHeight - bottomInset,
                              ),
                              maxWidth: 430,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: 44,
                                        height: 44,
                                        child: Image.asset(
                                          'assets/images/welcome_q_glow.png',
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.high,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        l10n.loginWelcomeBack,
                                        style: GoogleFonts.playfairDisplay(
                                          color: Colors.white,
                                          fontSize: 30,
                                          fontWeight: FontWeight.w600,
                                          height: 1.15,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        l10n.loginSubtitle,
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFFC8C0E0),
                                          fontSize: 14,
                                          height: 1.45,
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      if (_inlineError != null) ...[
                                        Container(
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
                                            _inlineError!,
                                            style: GoogleFonts.inter(
                                              color: AppColors.error
                                                  .withValues(alpha: 0.95),
                                              fontSize: 13,
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                      ],
                                      _glowField(
                                        focused: _emailFocused,
                                        child: TextFormField(
                                          controller: _emailController,
                                          focusNode: _emailFocus,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          cursorColor: _accentLavender,
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                          decoration: _fieldDecoration(
                                            label: l10n.email,
                                            focused: _emailFocused,
                                          ),
                                          onChanged: (_) {
                                            if (_inlineError != null) {
                                              setState(
                                                () => _inlineError = null,
                                              );
                                            }
                                          },
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return l10n.loginErrorEnterEmail;
                                            }
                                            if (!value.contains('@')) {
                                              return l10n.loginErrorValidEmail;
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _glowField(
                                        focused: _passwordFocused,
                                        child: TextFormField(
                                          controller: _passwordController,
                                          focusNode: _passwordFocus,
                                          obscureText: _obscurePassword,
                                          textInputAction: TextInputAction.done,
                                          cursorColor: _accentLavender,
                                          onFieldSubmitted: (_) =>
                                              _handleLogin(),
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                          decoration: _fieldDecoration(
                                            label: l10n.password,
                                            focused: _passwordFocused,
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons
                                                        .visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                color: const Color(0xFF9A90B8),
                                                size: 22,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword =
                                                      !_obscurePassword;
                                                });
                                              },
                                            ),
                                          ),
                                          onChanged: (_) {
                                            if (_inlineError != null) {
                                              setState(
                                                () => _inlineError = null,
                                              );
                                            }
                                          },
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return l10n
                                                  .loginErrorEnterPassword;
                                            }
                                            if (value.length < 6) {
                                              return l10n
                                                  .loginErrorPasswordMinLength;
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          key: const Key(
                                            'qmatch-login-forgot-password',
                                          ),
                                          onPressed: _isLoading
                                              ? null
                                              : _showForgotPasswordDialog,
                                          child: Text(
                                            l10n.forgotPassword,
                                            style: GoogleFonts.inter(
                                              color: _accentLavender,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const IgnorePointer(
                                    child: AuthWorldMapAccent(),
                                  ),
                                  Column(
                                    children: [
                                      _CosmicCtaButton(
                                        loading: _isLoading,
                                        label: l10n.logIn,
                                        onPressed:
                                            _isLoading ? null : _handleLogin,
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        l10n.loginPreferPhoneHint,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFFA8A0C0),
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                                ],
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
          ],
        ),
      ),
    );
  }
}

class _LoginCosmicBackdrop extends StatelessWidget {
  const _LoginCosmicBackdrop();

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
          Positioned(
            bottom: 60,
            left: -40,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 140,
            right: -20,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.softGold.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          const CustomPaint(painter: _StarFieldPainter()),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x440A0F1C),
                  Color(0x180A0F1C),
                  Color(0x880C0C0C),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
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
