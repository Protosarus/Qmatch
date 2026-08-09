import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/navigation/auth_wrapper.dart';
import '../../../l10n/app_localizations.dart';
import '../models/frequency_model.dart';
import '../utils/assessment_language.dart';
import '../utils/assessment_result_display_resolver.dart';
import 'frequency_intro_screen.dart';

class FrequencyResultScreen extends StatelessWidget {
  final FrequencyResult result;

  const FrequencyResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = AssessmentLanguage.languageUsed(
      languageCode: Localizations.maybeLocaleOf(context)?.languageCode,
    );
    final incomplete = !result.isComplete;
    final incompleteTitle = languageCode.startsWith('tr')
        ? 'Frekans profili tamamlanamadı'
        : 'Frequency profile is incomplete';
    final incompleteDescription = languageCode.startsWith('tr')
        ? 'Tüm Frekans boyutları için yeterli yanıt yok. Bu bir tip adı değildir; profil henüz sınıflandırılmadı.'
        : 'Not enough answers for every Frequency dimension. This is a status message, not a stored Frequency type.';

    final typeDisplay = incomplete || result.type == null
        ? null
        : AssessmentResultDisplayResolver.resolveFrequencyType(
            result.type!,
            languageCode: languageCode,
          );
    final tagLabels = incomplete
        ? const <String>[]
        : AssessmentResultDisplayResolver.localizeFrequencyTags(
            result.tags.take(4),
            languageCode: languageCode,
          );

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
                l10n.yourFrequency,
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.primary,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                incomplete ? incompleteTitle : (typeDisplay?.title ?? ''),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              if (!incomplete)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child:
                            const Icon(Icons.waves, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.frequencyScore,
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${result.scoreTotal.round()} / 100',
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
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Text(
                    languageCode.startsWith('tr')
                        ? 'Eksik boyutlar: ${result.missingDimensions.length}'
                        : 'Missing dimensions: ${result.missingDimensions.length}',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                incomplete
                    ? incompleteDescription
                    : (typeDisplay?.description ?? ''),
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (tagLabels.isNotEmpty) ...[
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tagLabels
                      .map(
                        (label) => Chip(
                          label: Text(
                            label,
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.35),
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
                    if (incomplete) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const FrequencyIntroScreen(),
                        ),
                        (route) => false,
                      );
                    } else {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const AuthWrapper(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    incomplete
                        ? (languageCode.startsWith('tr')
                            ? 'Tekrar dene'
                            : 'Try again')
                        : l10n.assessmentContinue,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
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
