import 'package:flutter/material.dart';
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

  String _normalizePhone(String input) {
    final raw = input.trim().replaceAll(' ', '').replaceAll('-', '');
    final cleaned = raw.replaceAll(RegExp(r'[^0-9+]'), '');

    if (cleaned.startsWith('+')) return cleaned;

    // MVP normalization for Turkish numbers.
    final digits = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 11 && digits.startsWith('0')) {
      return '+90${digits.substring(1)}';
    }
    if (digits.length == 10 && digits.startsWith('5')) {
      return '+90$digits';
    }
    return cleaned;
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
    if (phone.isEmpty || !phone.startsWith('+') || phone.length < 10) {
      setState(() {
        _isLoading = false;
        _error =
            'Please enter a valid phone number in E.164 format (e.g. +905551112233).';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios, color: gold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 36),
              Text(
                _codeSent ? 'Enter the code' : 'Enter your phone number',
                style: GoogleFonts.playfairDisplay(
                  color: gold,
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _codeSent
                    ? 'We sent a verification code to ${_normalizePhone(_phoneController.text)}.'
                    : 'We\'ll send you a code to verify your number.',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 26),
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    _error!,
                    style: GoogleFonts.inter(
                      color: Colors.redAccent,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              if (!_codeSent) ...[
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Phone number',
                    hintText: '+90 555 111 22 33',
                    labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                    hintStyle: GoogleFonts.inter(
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: gold.withValues(alpha: 0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: gold, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
              ] else ...[
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    labelText: 'SMS code',
                    hintText: '123456',
                    labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                    hintStyle: GoogleFonts.inter(
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: gold.withValues(alpha: 0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: gold, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  maxLength: 6,
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() {
                                _codeSent = false;
                                _error = null;
                              }),
                      child: Text(
                        'Change number',
                        style: GoogleFonts.inter(
                          color: gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _isLoading ? null : _startVerification,
                      child: Text(
                        'Resend code',
                        style: GoogleFonts.inter(
                          color: _didTimeout ? gold : gold.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_codeSent ? _verifyCode : _startVerification),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
                          _codeSent ? 'Verify' : 'Continue',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'By continuing, you may receive an SMS for verification. Message and data rates may apply.',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 26),
            ],
          ),
        ),
      ),
    );
  }
}
