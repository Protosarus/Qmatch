import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/navigation/auth_wrapper.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';

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
  bool _codeSent = false;
  bool _isLoading = false;
  bool _didTimeout = false;
  String? _error;

  /// Keeps Firebase E.164 formatting intact.
  /// Accepts full +E.164, or local TR numbers with the +90 prefix chip.
  String _normalizePhone(String input) {
    final raw = input.trim().replaceAll(' ', '').replaceAll('-', '');
    final cleaned = raw.replaceAll(RegExp(r'[^0-9+]'), '');

    if (cleaned.startsWith('+')) return cleaned;

    final digits = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 11 && digits.startsWith('0')) {
      return '+90${digits.substring(1)}';
    }
    if (digits.length == 10 && digits.startsWith('5')) {
      return '+90$digits';
    }
    if (digits.length >= 8 && digits.length <= 15) {
      return '+90$digits';
    }
    return cleaned;
  }

  bool _isPhoneTooShort(String normalized) {
    final digits = normalized.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length < 10;
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    Widget? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
      hintStyle: GoogleFonts.inter(
        color: AppColors.textSecondary.withValues(alpha: 0.55),
      ),
      prefixIcon: prefix,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
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
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      counterText: '',
    );
  }

  Widget _countryPrefixChip() {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          '+90',
          style: GoogleFonts.inter(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _startVerification() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _didTimeout = false;
    });

    final phone = _normalizePhone(_phoneController.text);
    if (phone.isEmpty ||
        !phone.startsWith('+') ||
        _isPhoneTooShort(phone)) {
      setState(() {
        _isLoading = false;
        _error = 'Enter a valid phone number (e.g. 555 000 0000).';
      });
      return;
    }

    await _authService.startPhoneVerification(
      phoneNumber: phone,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
          _isLoading = false;
        });
      },
      onAutoVerified: (_) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      },
      onFailed: (message) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = message;
        });
      },
      onTimeout: () {
        if (!mounted) return;
        setState(() => _didTimeout = true);
      },
    );
  }

  Future<void> _verifyCode() async {
    final verificationId = _verificationId;
    final smsCode = _codeController.text.trim();

    if (verificationId == null || verificationId.isEmpty) {
      setState(() {
        _error = 'Verification expired. Please request a new code.';
      });
      return;
    }
    if (smsCode.isEmpty || smsCode.length < 4) {
      setState(() {
        _error = 'Please enter the SMS code.';
      });
      return;
    }

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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Verification failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const gold = AppColors.primary;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                        _codeSent ? 'Enter the code' : 'What’s your number?',
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
                            ? 'We sent a verification code to your phone.'
                            : 'We’ll send a verification code to confirm it’s you.',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      if (_codeSent) ...[
                        const SizedBox(height: 6),
                        Text(
                          _normalizePhone(_phoneController.text),
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
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (!_isLoading) _startVerification();
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9+\s-]'),
                            ),
                          ],
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            letterSpacing: 0.4,
                          ),
                          decoration: _fieldDecoration(
                            label: 'Phone number',
                            hint: '555 000 0000',
                            prefix: _countryPrefixChip(),
                          ),
                          onChanged: (_) {
                            if (_error != null) {
                              setState(() => _error = null);
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Use your mobile number. Country code +90 is applied automatically.',
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
                          onFieldSubmitted: (_) {
                            if (!_isLoading) _verifyCode();
                          },
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
                            label: 'Verification code',
                            hint: '••••••',
                          ),
                          maxLength: 6,
                          onChanged: (_) {
                            if (_error != null) {
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
                                  : () => setState(() {
                                        _codeSent = false;
                                        _error = null;
                                        _codeController.clear();
                                      }),
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
                                'Change number',
                                style: GoogleFonts.inter(
                                  color: gold,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed:
                                  _isLoading ? null : _startVerification,
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
                                'Resend code',
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
                              : (_codeSent
                                  ? _verifyCode
                                  : _startVerification),
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
                                  _codeSent ? 'Verify' : 'Send code',
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
                        'By continuing, you may receive an SMS for verification. Message and data rates may apply.',
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
