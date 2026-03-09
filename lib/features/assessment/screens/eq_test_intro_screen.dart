import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'eq_test_screen.dart';

class EQTestIntroScreen extends StatelessWidget {
  final int iqScore;

  const EQTestIntroScreen({
    super.key,
    this.iqScore = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              // Emoji
              Center(
                child: Text(
                  '❤️',
                  style: const TextStyle(fontSize: 120),
                ),
              ),

              const SizedBox(height: 40),

              // Title
              Text(
                'Emotional Intelligence',
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.primary,
                  fontSize: 42,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 20),

              // Description
              Text(
                'Your emotional quotient (EQ) measures your ability to understand and manage emotions - both yours and others\'.',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 30),

              // Info bullets
              _buildInfoBullet('10 scenario-based questions'),
              const SizedBox(height: 12),
              _buildInfoBullet('Measures empathy & self-awareness'),
              const SizedBox(height: 12),
              _buildInfoBullet('Takes about 5 minutes'),

              const Spacer(),

              // Start Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EQTestScreen(iqScore: iqScore),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'BEGIN EQ TEST',
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBullet(String text) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
