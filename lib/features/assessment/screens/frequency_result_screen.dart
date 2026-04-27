import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/navigation/auth_wrapper.dart';
import '../models/frequency_model.dart';

class FrequencyResultScreen extends StatelessWidget {
  final FrequencyResult result;

  const FrequencyResultScreen({super.key, required this.result});

  String _descriptionFor(String type) {
    switch (type) {
      case 'Deep Connector':
        return 'You build connection through meaning, trust, and emotional depth.';
      case 'Social Spark':
        return 'You connect through energy, playfulness, and shared momentum.';
      case 'Slow Burner':
        return 'You prefer trust to grow gradually and intentionally.';
      case 'Emotional Explorer':
        return 'You connect through honesty, emotional openness, and reflection.';
      case 'Open Current':
        return 'You connect through flow, spontaneity, and emotional availability.';
      default:
        return 'You adapt your connection style depending on the person and context.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = result.scoreTotal.round();
    final tags = result.tags.take(4).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your frequency',
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.primary,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                result.type,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: const Icon(Icons.waves, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Score',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$score / 100',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _descriptionFor(result.type),
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map(
                        (t) => Chip(
                          label: Text(
                            t,
                            style: GoogleFonts.inter(color: Colors.black, fontSize: 12),
                          ),
                          backgroundColor: AppColors.primary.withValues(alpha: 0.35),
                        ),
                      )
                      .toList(),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    // Continue onboarding via AuthWrapper (profile -> main).
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AuthWrapper()),
                      (route) => false,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

