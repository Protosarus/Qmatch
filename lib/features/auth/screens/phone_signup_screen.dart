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
import '../../../core/widgets/elegant_warning.dart';
import '../../../l10n/app_localizations.dart';

class PhoneSignupScreen extends StatefulWidget {
  const PhoneSignupScreen({super.key});

  @override
  State<PhoneSignupScreen> createState() => _PhoneSignupScreenState();
}

class _PhoneSignupScreenState extends State<PhoneSignupScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _authService = AuthService();

  String? _verificationId;
  String? _e164Phone;
  String _dialCode = '+90';
  String _nationalNumber = '';

  bool _codeSent = false;
  bool _isLoading = false;
  bool _didTimeout = false;
  bool _sendInFlight = false;
  String? _error;

  late final String _initialIsoCode;

  @override
  void initState() {
    super.initState();
    _initialIsoCode = _detectDefaultIsoCode();
    _dialCode = _dialCodeForIso(_initialIsoCode);
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
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
      hintStyle: GoogleFonts.inter(
        color: AppColors.textSecondary.withValues(alpha: 0.55),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.35),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.error.withValues(alpha: 0.7),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.error.withValues(alpha: 0.9),
          width: 1.5,
        ),
      ),
      filled: true,
      fillColor: AppColors.surface,
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
          final text = message.trim().isEmpty
              ? l10n.phoneSignupErrorSmsFailed
              : message;
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
        'invalid-verification-code' || 'invalid-verification-id' =>
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
    const gold = AppColors.primary;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final displayedPhone = _e164Phone ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios, color: gold, size: 22),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 32,
                right: 32,
                bottom: bottomInset + 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - bottomInset,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        _codeSent
                            ? l10n.phoneSignupTitleEnterCode
                            : l10n.phoneSignupTitleAskNumber,
                        style: GoogleFonts.playfairDisplay(
                          color: gold,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _codeSent
                            ? l10n.phoneSignupSubtitleCodeSent
                            : l10n.phoneSignupSubtitleSendCode,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      if (_codeSent && displayedPhone.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          displayedPhone,
                          style: GoogleFonts.inter(
                            color: gold.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),

                      if (_error != null) ...[
                        Text(
                          _error!,
                          style: GoogleFonts.inter(
                            color: AppColors.error.withValues(alpha: 0.9),
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      if (!_codeSent) ...[
                        IntlPhoneField(
                          controller: _phoneController,
                          initialCountryCode: _initialIsoCode,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _sendCode(),
                          onChanged: _onPhoneChanged,
                          onCountryChanged: (country) {
                            _dialCode = '+${country.dialCode}';
                            _e164Phone = _buildE164(
                              dialCode: _dialCode,
                              nationalNumber: _nationalNumber.isNotEmpty
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
                          dropdownTextStyle: GoogleFonts.inter(
                            color: gold,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          flagsButtonPadding:
                              const EdgeInsets.only(left: 12, right: 4),
                          dropdownIcon: const Icon(
                            Icons.arrow_drop_down,
                            color: gold,
                          ),
                          disableLengthCheck: true,
                          showDropdownIcon: true,
                          decoration: _fieldDecoration(
                            label: l10n.phoneNumber,
                            hint: l10n.mobileNumberHint,
                          ),
                          pickerDialogStyle: PickerDialogStyle(
                            backgroundColor: AppColors.surface,
                            countryCodeStyle: GoogleFonts.inter(
                              color: gold,
                              fontWeight: FontWeight.w600,
                            ),
                            countryNameStyle: GoogleFonts.inter(
                              color: Colors.white,
                            ),
                            searchFieldInputDecoration: InputDecoration(
                              hintText: l10n.searchCountry,
                              hintStyle: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.textSecondary,
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: gold),
                              ),
                            ),
                          ),
                          autovalidateMode: AutovalidateMode.disabled,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.phoneSignupCountryHint,
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.7),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _verifyCode(),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
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
                          ),
                          maxLength: 6,
                          onChanged: (_) {
                            if (_error != null && mounted) {
                              setState(() => _error = null);
                            }
                          },
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                l10n.changeNumber,
                                style: GoogleFonts.inter(
                                  color: gold,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _isLoading ? null : _sendCode,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                l10n.resendCode,
                                style: GoogleFonts.inter(
                                  color: _didTimeout
                                      ? gold
                                      : gold.withValues(alpha: 0.75),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const Spacer(),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : (_codeSent ? _verifyCode : _sendCode),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: gold,
                            foregroundColor: AppColors.background,
                            disabledBackgroundColor:
                                gold.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.background,
                                    ),
                                  ),
                                )
                              : Text(
                                  _codeSent ? l10n.verify : l10n.sendCode,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.phoneSignupSmsDisclaimer,
                        style: GoogleFonts.inter(
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.55),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
