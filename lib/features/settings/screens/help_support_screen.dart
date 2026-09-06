import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_support.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';
import '../../../core/widgets/cosmic/qmatch_cosmic_background.dart';
import '../../../core/widgets/qmatch_feedback.dart';
import '../../../core/widgets/qmatch_primary_action.dart';
import '../../../core/widgets/qmatch_pushed_screen_header.dart';
import '../../../l10n/app_localizations.dart';
import 'legal_document_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _copySupportEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: AppSupport.email));
    if (!context.mounted) return;
    QMatchFeedback.show(
      context,
      message: AppLocalizations.of(context)!.supportEmailLabel,
      type: QMatchFeedbackType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: QMatchCosmicBackground(
        seed: 41,
        child: SafeArea(
          child: Column(
            children: [
              QMatchPushedScreenHeader(
                key: const Key('qmatch-help-header'),
                title: l10n.helpSupportTitle,
                backButtonKey: const Key('qmatch-help-back'),
                titleKey: const Key('qmatch-help-title'),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  children: [
                    _faq(q: l10n.helpFaqHowWorksQ, a: l10n.helpFaqHowWorksA),
                    _faq(q: l10n.helpFaqScoresQ, a: l10n.helpFaqScoresA),
                    _faq(q: l10n.helpFaqRankingQ, a: l10n.helpFaqRankingA),
                    _faq(q: l10n.helpFaqFrequencyQ, a: l10n.helpFaqFrequencyA),
                    _faq(q: l10n.helpFaqDataQ, a: l10n.helpFaqDataA),
                    _faq(q: l10n.helpFaqPhotosQ, a: l10n.helpFaqPhotosA),
                    _faq(q: l10n.helpFaqAgeQ, a: l10n.helpFaqAgeA),
                    _faq(q: l10n.helpFaqBlockQ, a: l10n.helpFaqBlockA),
                    _faq(q: l10n.helpFaqReportQ, a: l10n.helpFaqReportA),
                    _faq(q: l10n.helpFaqSafetyQ, a: l10n.helpFaqSafetyA),
                    _faq(
                      q: l10n.helpFaqDeleteAccountQ,
                      a: l10n.helpFaqDeleteAccountA,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    QGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _linkRow(
                            context,
                            label: l10n.openPrivacyPolicy,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => LegalDocumentScreen(
                                    title: l10n.privacyPolicyTitle,
                                    body: l10n.privacyPolicyBody,
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(
                            height: AppSpacing.lg,
                            color: AppColors.borderSubtle,
                          ),
                          _linkRow(
                            context,
                            label: l10n.openTermsOfUse,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => LegalDocumentScreen(
                                    title: l10n.termsOfUseTitle,
                                    body: l10n.termsOfUseBody,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    QGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.helpSupportContact,
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          QMatchPrimaryAction(
                            key: const Key('qmatch-help-copy-email'),
                            label: l10n.supportEmailLabel,
                            icon: Icons.copy_outlined,
                            onPressed: () => _copySupportEmail(context),
                            semanticLabel: l10n.supportEmailLabel,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _faq({required String q, required String a}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: QGlassCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          collapsedIconColor: AppColors.textSecondary,
          iconColor: AppColors.softGold,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          title: Text(
            q,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          children: [
            Text(
              a,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkRow(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
