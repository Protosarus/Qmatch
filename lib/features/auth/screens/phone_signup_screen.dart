import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

import '../../../core/navigation/auth_wrapper.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/widgets/elegant_warning.dart';
import '../../../core/widgets/qmatch_glass_icon_button.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/auth_world_map_accent.dart';

class PhoneSignupScreen extends StatefulWidget {
  const PhoneSignupScreen({super.key});

  @override
  State<PhoneSignupScreen> createState() => _PhoneSignupScreenState();
}

class _PhoneSignupScreenState extends State<PhoneSignupScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _codeFocus = FocusNode();
  final _authService = AuthService();

  String? _verificationId;
  String? _e164Phone;
  String _dialCode = '+90';
  String _nationalNumber = '';

  bool _codeSent = false;
  bool _isLoading = false;
  bool _didTimeout = false;
  bool _sendInFlight = false;
  bool _phoneFocused = false;
  bool _codeFocused = false;
  String? _error;

  late final String _initialIsoCode;

  @override
  void initState() {
    super.initState();
    _initialIsoCode = _detectDefaultIsoCode();
    _dialCode = _dialCodeForIso(_initialIsoCode);
    _phoneFocus.addListener(() {
      if (!mounted) return;
      setState(() => _phoneFocused = _phoneFocus.hasFocus);
    });
    _codeFocus.addListener(() {
      if (!mounted) return;
      setState(() => _codeFocused = _codeFocus.hasFocus);
    });
  }

  /// Prefer device locale country; fall back to TR (then allow change).
  String _detectDefaultIsoCode() {
    try {
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      final code = locale.countryCode?.trim().toUpperCase();
      if (code != null &&
          code.length == 2 &&
          countries.any((c) => c.code == code)) {
        return code;
      }
    } catch (_) {}
    return 'TR';
  }

  String _dialCodeForIso(String iso) {
    try {
      final country = countries.firstWhere((c) => c.code == iso);
      return '+${country.dialCode}';
    } catch (_) {
      return '+90';
    }
  }

  /// Build E.164 from selected dial code + national number, or full "+" input.
  String? _buildE164({
    required String dialCode,
    required String nationalNumber,
    String? completeFromField,
  }) {
    // Prefer full international value if the user typed one starting with +.
    final typed = (completeFromField ?? _phoneController.text).trim();
    if (typed.startsWith('+')) {
      final cleaned = typed
          .replaceAll(RegExp(r'[\s\-\(\)]'), '')
          .replaceAll(RegExp(r'[^0-9+]'), '');
      final normalized = '+${cleaned.substring(1).replaceAll('+', '')}';
      return _isValidE164(normalized) ? normalized : null;
    }

    var dial = dialCode.trim();
    if (dial.isEmpty) return null;
    if (!dial.startsWith('+')) dial = '+$dial';
    dial = '+${dial.substring(1).replaceAll(RegExp(r'[^0-9]'), '')}';

    var local = nationalNumber.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    local = local.replaceAll(RegExp(r'[^0-9]'), '');
    if (local.isEmpty) return null;

    // Avoid duplicate country code: local "90555..." while dial is "+90".
    final dialDigits = dial.substring(1);
    if (local.startsWith(dialDigits)) {
      local = local.substring(dialDigits.length);
    }
    // Strip a single leading trunk 0 (common in many countries).
    if (local.startsWith('0')) {
      local = local.substring(1);
    }
    if (local.isEmpty) return null;

    final e164 = '$dial$local';
    return _isValidE164(e164) ? e164 : null;
  }

  bool _isValidE164(String phone) {
    if (!phone.startsWith('+')) return false;
    final digits = phone.substring(1);
    if (!RegExp(r'^[0-9]+$').hasMatch(digits)) return false;
    // E.164: country code + subscriber number, max 15 digits total.
    return digits.length >= 8 && digits.length <= 15;
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    required bool focused,
  }) {
    // Idle: soft violet. Focused: violet → gold glow edge.
    final idleBorder = const Color(0x77A890D8);
    final focusBorder = focused ? AppColors.softGold : idleBorder;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      // Floating label idle = muted violet-gray (not gold).
      labelStyle: GoogleFonts.inter(
        color: const Color(0xFF9A90B8),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: GoogleFonts.inter(
        color: focused ? AppColors.softGold : const Color(0xFFB8AED8),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      // Placeholder: gray-purple (never gold).
      hintStyle: GoogleFonts.inter(
        color: const Color(0xFF8A82A8),
        fontSize: 15,
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
      counterText: '',
    );
  }

  void _setError(String message, {bool showSnack = true}) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _error = message;
    });
    if (showSnack) {
      showElegantWarning(context, message);
    }
  }

  void _onPhoneChanged(PhoneNumber phone) {
    // countryCode from package already includes "+" (e.g. "+90").
    _dialCode = phone.countryCode.startsWith('+')
        ? phone.countryCode
        : '+${phone.countryCode}';
    _nationalNumber = phone.number;
    final complete = phone.completeNumber.trim();
    _e164Phone = _buildE164(
      dialCode: _dialCode,
      nationalNumber: _nationalNumber,
      completeFromField: complete.startsWith('+') ? complete : null,
    );
    if (_error != null && mounted) {
      setState(() => _error = null);
    }
  }

  @override
  void dispose() {
    _phoneFocus.dispose();
    _codeFocus.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// Shared by Send code / Continue and keyboard Enter / Done.
  Future<void> _sendCode() async {
    if (_isLoading || _sendInFlight) return;

    final l10n = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();

    // Resend uses the same finalized E.164 from the first successful send.
    final phone = (_codeSent && _e164Phone != null && _isValidE164(_e164Phone!))
        ? _e164Phone!
        : (_buildE164(
              dialCode: _dialCode,
              nationalNumber: _nationalNumber.isNotEmpty
                  ? _nationalNumber
                  : _phoneController.text,
            ) ??
            _e164Phone);

    if (phone == null || !_isValidE164(phone)) {
      _setError(l10n.phoneSignupErrorInvalidPhone);
      return;
    }

    _sendInFlight = true;
    if (!mounted) {
      _sendInFlight = false;
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _didTimeout = false;
      _e164Phone = phone;
    });

    debugPrint(
      'PhoneSignupScreen: sending code to ${AuthService.maskPhoneForLog(phone)}',
    );

    try {
      await _authService.startPhoneVerification(
        phoneNumber: phone,
        onCodeSent: (verificationId) {
          _sendInFlight = false;
          if (!mounted) return;
          if (verificationId.trim().isEmpty) {
            _setError(l10n.phoneSignupErrorSmsFailed);
            return;
          }
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
            _error = null;
          });
        },
        onAutoVerified: (_) {
          _sendInFlight = false;
          if (!mounted) return;
          setState(() => _isLoading = false);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (route) => false,
          );
        },
        onFailed: (message) {
          _sendInFlight = false;
          if (!mounted) return;
          final text =
              message.trim().isEmpty ? l10n.phoneSignupErrorSmsFailed : message;
          _setError(text);
        },
        onTimeout: () {
          if (!mounted) return;
          setState(() => _didTimeout = true);
        },
      );
    } on FirebaseAuthException catch (e) {
      _sendInFlight = false;
      if (!mounted) return;
      _setError(
        e.code == 'invalid-phone-number'
            ? l10n.phoneSignupErrorPhoneLooksInvalid
            : l10n.phoneSignupErrorSmsFailed,
      );
    } on PlatformException catch (e) {
      _sendInFlight = false;
      debugPrint('PhoneSignupScreen PlatformException: ${e.code}');
      if (!mounted) return;
      _setError(l10n.phoneSignupErrorSmsFailed);
    } catch (e) {
      _sendInFlight = false;
      debugPrint('PhoneSignupScreen._sendCode error: $e');
      if (!mounted) return;
      _setError(l10n.phoneSignupErrorSmsFailed);
    }
  }

  Future<void> _verifyCode() async {
    if (_isLoading) return;

    final l10n = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();

    final verificationId = _verificationId?.trim();
    final smsCode = _codeController.text.trim();

    if (verificationId == null || verificationId.isEmpty) {
      _setError(l10n.phoneSignupErrorVerificationExpired);
      return;
    }
    if (smsCode.isEmpty || smsCode.length < 4) {
      _setError(l10n.phoneSignupErrorEnterSmsCode, showSnack: false);
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authService.verifySmsCode(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'invalid-verification-code' ||
        'invalid-verification-id' =>
          l10n.phoneSignupErrorIncorrectCode,
        'session-expired' => l10n.phoneSignupErrorVerificationExpired,
        _ => l10n.phoneSignupErrorVerificationFailed,
      };
      _setError(message);
    } catch (e) {
      debugPrint('PhoneSignupScreen._verifyCode error: $e');
      if (!mounted) return;
      _setError(l10n.phoneSignupErrorVerificationFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const accent = AppColors.softGold;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final displayedPhone = _e164Phone ?? '';

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
            const _PhoneCosmicBackdrop(),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
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
                                      _codeSent
                                          ? l10n.phoneSignupTitleEnterCode
                                          : l10n.phoneSignupTitleAskNumber,
                                      style: GoogleFonts.playfairDisplay(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w600,
                                        height: 1.15,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _codeSent
                                          ? l10n.phoneSignupSubtitleCodeSent
                                          : l10n.phoneSignupSubtitleSendCode,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFFC8C0E0),
                                        fontSize: 14,
                                        height: 1.45,
                                      ),
                                    ),
                                    if (_codeSent &&
                                        displayedPhone.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        displayedPhone,
                                        style: GoogleFonts.inter(
                                          color: AppColors.resonanceViolet
                                              .withValues(alpha: 0.95),
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 28),
                                    if (_error != null) ...[
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
                                          _error!,
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
                                    if (!_codeSent) ...[
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        decoration: BoxDecoration(
                                          borderRadius: AppRadii.cardBorder,
                                          boxShadow: _phoneFocused
                                              ? [
                                                  BoxShadow(
                                                    color: AppColors
                                                        .resonanceViolet
                                                        .withValues(
                                                            alpha: 0.45),
                                                    blurRadius: 16,
                                                  ),
                                                  BoxShadow(
                                                    color: AppColors.softGold
                                                        .withValues(
                                                            alpha: 0.28),
                                                    blurRadius: 14,
                                                    offset: const Offset(2, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Theme(
                                          data: Theme.of(context).copyWith(
                                            brightness: Brightness.dark,
                                            colorScheme: Theme.of(context)
                                                .colorScheme
                                                .copyWith(
                                                  brightness: Brightness.dark,
                                                  onSurface: Colors.white,
                                                ),
                                            textTheme: Theme.of(context)
                                                .textTheme
                                                .apply(
                                                  bodyColor: Colors.white,
                                                  displayColor: Colors.white,
                                                ),
                                          ),
                                          child: IntlPhoneField(
                                            controller: _phoneController,
                                            focusNode: _phoneFocus,
                                            initialCountryCode: _initialIsoCode,
                                            keyboardType: TextInputType.phone,
                                            textInputAction:
                                                TextInputAction.done,
                                            onSubmitted: (_) => _sendCode(),
                                            onChanged: _onPhoneChanged,
                                            onCountryChanged: (country) {
                                              _dialCode =
                                                  '+${country.dialCode}';
                                              _e164Phone = _buildE164(
                                                dialCode: _dialCode,
                                                nationalNumber:
                                                    _nationalNumber.isNotEmpty
                                                        ? _nationalNumber
                                                        : _phoneController.text,
                                              );
                                              if (mounted) setState(() {});
                                            },
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 16,
                                              letterSpacing: 0.3,
                                            ),
                                            dropdownTextStyle:
                                                GoogleFonts.inter(
                                              color: accent,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            flagsButtonPadding:
                                                const EdgeInsets.only(
                                              left: 12,
                                              right: 4,
                                            ),
                                            dropdownIcon: Icon(
                                              Icons.arrow_drop_down,
                                              color: accent.withValues(
                                                  alpha: 0.95),
                                            ),
                                            disableLengthCheck: true,
                                            showDropdownIcon: true,
                                            decoration: _fieldDecoration(
                                              label: l10n.phoneNumber,
                                              hint: l10n.mobileNumberHint,
                                              focused: _phoneFocused,
                                            ),
                                            pickerDialogStyle:
                                                PickerDialogStyle(
                                              backgroundColor:
                                                  AppColors.midnightNavy,
                                              countryCodeStyle:
                                                  GoogleFonts.inter(
                                                color: accent,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              countryNameStyle:
                                                  GoogleFonts.inter(
                                                color: Colors.white,
                                              ),
                                              searchFieldCursorColor: accent,
                                              searchFieldInputDecoration:
                                                  InputDecoration(
                                                hintText: l10n.searchCountry,
                                                hintStyle: GoogleFonts.inter(
                                                  color:
                                                      const Color(0xFF9A90B8),
                                                ),
                                                prefixIcon: const Icon(
                                                  Icons.search,
                                                  color: Color(0xFF9A90B8),
                                                ),
                                                enabledBorder:
                                                    UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: AppColors
                                                        .resonanceViolet
                                                        .withValues(
                                                            alpha: 0.35),
                                                  ),
                                                ),
                                                focusedBorder:
                                                    UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: AppColors.softGold
                                                        .withValues(alpha: 0.9),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            autovalidateMode:
                                                AutovalidateMode.disabled,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        l10n.phoneSignupCountryHint,
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFFB0A8C8),
                                          fontSize: 12.5,
                                          height: 1.35,
                                        ),
                                      ),
                                    ] else ...[
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        decoration: BoxDecoration(
                                          borderRadius: AppRadii.cardBorder,
                                          boxShadow: _codeFocused
                                              ? [
                                                  BoxShadow(
                                                    color: AppColors
                                                        .resonanceViolet
                                                        .withValues(
                                                            alpha: 0.45),
                                                    blurRadius: 16,
                                                  ),
                                                  BoxShadow(
                                                    color: AppColors.softGold
                                                        .withValues(
                                                            alpha: 0.28),
                                                    blurRadius: 14,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: TextFormField(
                                          controller: _codeController,
                                          focusNode: _codeFocus,
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) =>
                                              _verifyCode(),
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(6),
                                          ],
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 20,
                                            letterSpacing: 6,
                                          ),
                                          decoration: _fieldDecoration(
                                            label: l10n.verificationCode,
                                            hint: '••••••',
                                            focused: _codeFocused,
                                          ),
                                          maxLength: 6,
                                          onChanged: (_) {
                                            if (_error != null && mounted) {
                                              setState(() => _error = null);
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          TextButton(
                                            onPressed: _isLoading
                                                ? null
                                                : () {
                                                    if (!mounted) return;
                                                    setState(() {
                                                      _codeSent = false;
                                                      _error = null;
                                                      _verificationId = null;
                                                      _codeController.clear();
                                                    });
                                                  },
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 4,
                                                vertical: 8,
                                              ),
                                              minimumSize: Size.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: Text(
                                              l10n.changeNumber,
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFFC4B0FF),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                decoration:
                                                    TextDecoration.underline,
                                                decorationColor: const Color(
                                                  0x99C4B0FF,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          TextButton(
                                            onPressed:
                                                _isLoading ? null : _sendCode,
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 4,
                                                vertical: 8,
                                              ),
                                              minimumSize: Size.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: Text(
                                              l10n.resendCode,
                                              style: GoogleFonts.inter(
                                                color: _didTimeout
                                                    ? accent
                                                    : accent.withValues(
                                                        alpha: 0.75,
                                                      ),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                IgnorePointer(
                                  child: AuthWorldMapAccent(),
                                ),
                                Column(
                                  children: [
                                    _CosmicCtaButton(
                                      loading: _isLoading,
                                      label: _codeSent
                                          ? l10n.verify
                                          : l10n.sendCode,
                                      onPressed: _isLoading
                                          ? null
                                          : (_codeSent
                                              ? _verifyCode
                                              : _sendCode),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      l10n.phoneSignupSmsDisclaimer,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFFA8A0C0),
                                        fontSize: 11.5,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ],
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

class _PhoneCosmicBackdrop extends StatelessWidget {
  const _PhoneCosmicBackdrop();

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
          // Soft nebula washes (calmer Welcome cousin).
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
