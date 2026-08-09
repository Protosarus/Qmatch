import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/navigation/auth_wrapper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/cosmic/q_glass_card.dart';
import '../../core/widgets/cosmic/qmatch_cosmic_background.dart';
import '../../core/widgets/qmatch_primary_action.dart';
import '../../core/widgets/qmatch_pushed_screen_header.dart';
import '../../l10n/app_localizations.dart';
import '../assessment/screens/frequency_test_screen.dart';
import 'screens/assessment_admin_screen.dart';
import 'screens/persona_result_preview_screen.dart';

/// Debug hub. Not for production — refuses when [kDebugMode] is false.
class DebugHomeScreen extends StatelessWidget {
  const DebugHomeScreen({super.key});

  static const String routeName = '/debug';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!kDebugMode) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: QMatchCosmicBackground(
          seed: 59,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.debugModeUnavailable,
                style: GoogleFonts.inter(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: QMatchCosmicBackground(
        seed: 61,
        child: SafeArea(
          child: Column(
            children: [
              QMatchPushedScreenHeader(
                key: const Key('qmatch-debug-header'),
                title: l10n.settingsDebug,
                backButtonKey: const Key('qmatch-debug-back'),
                titleKey: const Key('qmatch-debug-title'),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        QGlassCard(
                          emphasized: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.debugHomeTitle,
                                style: GoogleFonts.playfairDisplay(
                                  color: AppColors.textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                l10n.debugHomeSubtitle,
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _toolCard(
                          label: l10n.debugAssessmentAdmin,
                          icon: Icons.tune_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AssessmentAdminScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _toolCard(
                          label: l10n.debugPersonaPreview,
                          icon: Icons.auto_awesome_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PersonaResultPreviewScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _toolCard(
                          label: l10n.debugFrequencyPreview,
                          icon: Icons.quiz_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FrequencyTestScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        QMatchPrimaryAction(
                          key: const Key('qmatch-debug-auth-wrapper'),
                          label: l10n.debugGoToAuthWrapper,
                          icon: Icons.login_outlined,
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AuthWrapper(),
                              ),
                            );
                          },
                        ),
                      ],
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

  Widget _toolCard({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return QGlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.resonanceViolet.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.softGold, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
