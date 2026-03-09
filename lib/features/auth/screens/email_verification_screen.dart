import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import '../../assessment/screens/iq_test_intro_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _authService = AuthService();
  Timer? _timer;
  bool _isResending = false;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Her 3 saniyede bir email doğrulanmış mı kontrol et
  void _startVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      bool isVerified = await _authService.isEmailVerified();
      if (isVerified && mounted) {
        _timer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const IQTestIntroScreen()),
        );
      }
    });
  }

  // Doğrulama emailini tekrar gönder
  Future<void> _resendEmail() async {
    if (_resendCooldown > 0) return;

    setState(() {
      _isResending = true;
    });

    try {
      await _authService.resendVerificationEmail();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent!'),
            backgroundColor: Color(0xFFE8D978),
          ),
        );

        // 60 saniye cooldown
        setState(() {
          _resendCooldown = 60;
        });

        Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_resendCooldown > 0) {
            setState(() {
              _resendCooldown--;
            });
          } else {
            timer.cancel();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const luxuryGold = Color(0xFFE8D978);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),

              // Title
              Text(
                'Verify Email',
                style: GoogleFonts.playfairDisplay(
                  color: luxuryGold,
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 20),

              // Description
              Text(
                'We sent a verification link to:\n${widget.email}',
                style: GoogleFonts.inter(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 30),

              // Instructions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: luxuryGold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Steps:',
                      style: GoogleFonts.inter(
                        color: luxuryGold,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStep('1', 'Check your email inbox'),
                    const SizedBox(height: 8),
                    _buildStep('2', 'Click the verification link'),
                    const SizedBox(height: 8),
                    _buildStep('3', 'Return to this app'),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Checking status
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: luxuryGold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Waiting for verification...',
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Resend Button
              Center(
                child: TextButton(
                  onPressed: _resendCooldown > 0 || _isResending
                      ? null
                      : _resendEmail,
                  child: _isResending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: luxuryGold,
                          ),
                        )
                      : Text(
                          _resendCooldown > 0
                              ? 'Resend in ${_resendCooldown}s'
                              : 'Resend Email',
                          style: GoogleFonts.inter(
                            color: _resendCooldown > 0
                                ? Colors.grey
                                : luxuryGold,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),

              const Spacer(),

              // Spam folder notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: luxuryGold, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Check your spam folder if you don\'t see the email',
                        style: GoogleFonts.inter(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFE8D978).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.inter(
                color: const Color(0xFFE8D978),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.inter(color: Colors.grey.shade300, fontSize: 14),
        ),
      ],
    );
  }
}
