import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../assessment/screens/iq_test_intro_screen.dart';

enum VerificationType { email, phone }

class VerificationScreen extends StatefulWidget {
  final VerificationType verificationType;
  final String contact;

  const VerificationScreen({
    super.key,
    required this.verificationType,
    required this.contact,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handleVerify() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const IQTestIntroScreen()),
    );
  }

  void _resendCode() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.verificationType == VerificationType.email
              ? 'Verification code sent to email'
              : 'Verification code sent via SMS',
        ),
        backgroundColor: const Color(0xFFD4B87E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 80),
                  Text(
                    'Verification',
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFD4B87E),
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.verificationType == VerificationType.email
                        ? 'Enter the code sent to\n${widget.contact}'
                        : 'Enter the SMS code sent to\n${widget.contact}',
                    style: GoogleFonts.inter(
                      color: Colors.grey,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 50),
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      hintText: '------',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 24,
                        letterSpacing: 8,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFD4B87E),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFD4B87E),
                          width: 2,
                        ),
                      ),
                    ),
                    maxLength: 6,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: _resendCode,
                      child: Text(
                        'Resend Code',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFD4B87E),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _handleVerify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4B87E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Verify',
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Color(0xFFD4B87E),
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
