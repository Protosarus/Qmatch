import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_support.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import 'legal_document_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _copySupportEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: AppSupport.email));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.supportEmailLabel)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: Text(
          l10n.helpSupportTitle,
          style: GoogleFonts.playfairDisplay(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
          _faq(q: l10n.helpFaqDeleteAccountQ, a: l10n.helpFaqDeleteAccountA),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LegalDocumentScreen(
                    title: l10n.privacyPolicyTitle,
                    body: l10n.privacyPolicyBody,
                  ),
                ),
              );
            },
            child: Text(l10n.openPrivacyPolicy),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LegalDocumentScreen(
                    title: l10n.termsOfUseTitle,
                    body: l10n.termsOfUseBody,
                  ),
                ),
              );
            },
            child: Text(l10n.openTermsOfUse),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
            ),
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
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _copySupportEmail(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.copy_outlined),
                  label: Text(l10n.supportEmailLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _faq({required String q, required String a}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: ExpansionTile(
        collapsedIconColor: AppColors.textSecondary,
        iconColor: AppColors.primary,
        title: Text(
          q,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
    );
  }
}
