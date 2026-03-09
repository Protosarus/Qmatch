import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'iq_test_screen.dart';

class IQTestIntroScreen extends StatelessWidget {
  const IQTestIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // QMatch Logo
              ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  AppColors.primary,
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/images/logo_white.png',
                  width: 280,
                  height: 180,
                  filterQuality: FilterQuality.high,
                ),
              ),

              const SizedBox(height: 40),

              // IQ Test Title
              Text(
                'IQ Test',
                style: GoogleFonts.cinzel(
                  color: AppColors.primary,
                  fontSize: 64,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3,
                  height: 1.0,
                ),
              ),

              const Spacer(flex: 2),

              // START IQ TEST Button
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const IQTestScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'START IQ TEST',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
