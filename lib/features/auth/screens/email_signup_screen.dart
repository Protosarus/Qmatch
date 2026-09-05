import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/navigation/auth_navigation.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/widgets/elegant_warning.dart';
import '../../../core/widgets/qmatch_glass_icon_button.dart';
import '../../../l10n/app_localizations.dart';
import '../email_signup_flow.dart';
import '../widgets/auth_keyboard_dismiss.dart';
import '../widgets/auth_world_map_accent.dart';
import 'login_screen.dart';

typedef EmailSignupRegister = Future<void> Function({
  required String email,
  required String password,
});

class EmailSignupScreen extends StatefulWidget {
  const EmailSignupScreen({
    super.key,
    this.authService,
    this.register,
  });

  /// Production AuthService. Ignored when [register] is provided.
  final AuthService? authService;

  /// Test seam so widget tests never touch Firebase.
  final EmailSignupRegister? register;

  static const Key emailFieldKey = Key('qmatch-email-signup-email');
  static const Key passwordFieldKey = Key('qmatch-email-signup-password');
  static const Key confirmFieldKey = Key('qmatch-email-signup-confirm');
  static const Key submitKey = Key('qmatch-email-signup-submit');
  static const Key goLoginKey = Key('qmatch-email-signup-go-login');
  static const Key errorBannerKey = Key('qmatch-email-signup-error');

  @override
  State<EmailSignupScreen> createState() => _EmailSignupScreenState();
}

class _EmailSignupScreenState extends State<EmailSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isLoading = false;
  bool _submitLocked = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _emailFocused = false;
  bool _passwordFocused = false;
  bool _confirmFocused = false;
  String? _inlineError;

  static const Color _accentLavender = Color(0xFFDAC8ED);

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
    _confirmFocus.addListener(() {
      if (!mounted) return;
      setState(() => _confirmFocused = _confirmFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

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

  Future<void> _handleSignup() async {
    if (_submitLocked || _isLoading) return;
    final l10n = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();
    setState(() => _inlineError = null);
    if (!_formKey.currentState!.validate()) return;

    _submitLocked = true;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final register = widget.register;
      if (register != null) {
        await register(email: email, password: password);
      } else {
        await EmailSignupFlow.register(
          authService: widget.authService ?? AuthService(),
          email: email,
          password: password,
        );
      }

      if (mounted) {
        AuthNavigation.completeAuthentication(context);
      }
    } on FirebaseAuthException catch (error) {
      final message = EmailSignupFlow.mapAuthError(l10n, error);
      if (mounted) {
        setState(() => _inlineError = message);
        showElegantWarning(context, message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _inlineError = l10n.emailSignupErrorFailed);
        showElegantWarning(context, l10n.emailSignupErrorFailed);
      }
    } finally {
      _submitLocked = false;
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goLogin() {
    if (_isLoading) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  void _clearInlineError() {
    if (_inlineError == null) return;
    setState(() => _inlineError = null);
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
      child: AuthKeyboardDismiss(
        child: Scaffold(
          backgroundColor: AppColors.midnightNavy,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const _SignupCosmicBackdrop(),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final padH =
                        (constraints.maxWidth * 0.06).clamp(20.0, 28.0);
                    return Form(
                      key: _formKey,
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
                                tooltip: MaterialLocalizations.of(context)
                                    .backButtonTooltip,
                                onPressed: _isLoading
                                    ? null
                                    : () => Navigator.of(context).maybePop(),
                              ),
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.fromLTRB(padH, 0, padH, 16),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 430,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      l10n.emailSignupTitle,
                                      style: GoogleFonts.playfairDisplay(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w600,
                                        height: 1.15,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      l10n.emailSignupSubtitle,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFFC8C0E0),
                                        fontSize: 14,
                                        height: 1.45,
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    if (_inlineError != null) ...[
                                      Container(
                                        key: EmailSignupScreen.errorBannerKey,
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
                                        key: EmailSignupScreen.emailFieldKey,
                                        controller: _emailController,
                                        focusNode: _emailFocus,
                                        enabled: !_isLoading,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        autocorrect: false,
                                        enableSuggestions: false,
                                        cursorColor: _accentLavender,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                        decoration: _fieldDecoration(
                                          label: l10n.email,
                                          focused: _emailFocused,
                                        ),
                                        onChanged: (_) => _clearInlineError(),
                                        validator: (value) =>
                                            EmailSignupFlow.validateEmail(
                                          value,
                                          l10n,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _glowField(
                                      focused: _passwordFocused,
                                      child: TextFormField(
                                        key: EmailSignupScreen.passwordFieldKey,
                                        controller: _passwordController,
                                        focusNode: _passwordFocus,
                                        enabled: !_isLoading,
                                        obscureText: _obscurePassword,
                                        textInputAction: TextInputAction.next,
                                        cursorColor: _accentLavender,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                        decoration: _fieldDecoration(
                                          label: l10n.password,
                                          focused: _passwordFocused,
                                          suffixIcon: IconButton(
                                            key: const Key(
                                              'qmatch-email-signup-password-visibility',
                                            ),
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
                                        onChanged: (_) => _clearInlineError(),
                                        validator: (value) =>
                                            EmailSignupFlow.validatePassword(
                                          value,
                                          l10n,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _glowField(
                                      focused: _confirmFocused,
                                      child: TextFormField(
                                        key: EmailSignupScreen.confirmFieldKey,
                                        controller: _confirmController,
                                        focusNode: _confirmFocus,
                                        enabled: !_isLoading,
                                        obscureText: _obscureConfirm,
                                        textInputAction: TextInputAction.done,
                                        cursorColor: _accentLavender,
                                        onFieldSubmitted: (_) =>
                                            _handleSignup(),
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                        decoration: _fieldDecoration(
                                          label:
                                              l10n.emailSignupConfirmPassword,
                                          focused: _confirmFocused,
                                          suffixIcon: IconButton(
                                            key: const Key(
                                              'qmatch-email-signup-confirm-visibility',
                                            ),
                                            icon: Icon(
                                              _obscureConfirm
                                                  ? Icons
                                                      .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: const Color(0xFF9A90B8),
                                              size: 22,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscureConfirm =
                                                    !_obscureConfirm;
                                              });
                                            },
                                          ),
                                        ),
                                        onChanged: (_) => _clearInlineError(),
                                        validator: (value) => EmailSignupFlow
                                            .validateConfirmation(
                                          value,
                                          _passwordController.text,
                                          l10n,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
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
                                    key: EmailSignupScreen.submitKey,
                                    loading: _isLoading,
                                    label: l10n.welcomeSignUpWithEmail,
                                    onPressed:
                                        _isLoading ? null : _handleSignup,
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        l10n.emailSignupAlreadyHaveAccount,
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFFA8A0C0),
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                      TextButton(
                                        key: EmailSignupScreen.goLoginKey,
                                        onPressed: _isLoading ? null : _goLogin,
                                        child: Text(
                                          l10n.logIn,
                                          style: GoogleFonts.inter(
                                            color: _accentLavender,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _SignupCosmicBackdrop extends StatelessWidget {
  const _SignupCosmicBackdrop();

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
