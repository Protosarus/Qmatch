import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';
import '../../../core/widgets/cosmic/qmatch_cosmic_background.dart';
import '../../../core/widgets/qmatch_pushed_screen_header.dart';
import '../../../l10n/app_localizations.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _showInDiscover = true;
  bool _showApproxLocation = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: QMatchCosmicBackground(
        seed: 23,
        child: SafeArea(
          child: Column(
            children: [
              QMatchPushedScreenHeader(
                key: const Key('qmatch-privacy-header'),
                title: l10n.privacySettingsTitle,
                backButtonKey: const Key('qmatch-privacy-back'),
                titleKey: const Key('qmatch-privacy-title'),
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
                    _sectionTitle(l10n.privacyVisibilitySection),
                    const SizedBox(height: AppSpacing.xs),
                    QGlassCard(
                      key: const Key('qmatch-privacy-card'),
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _switch(
                            key: const Key('qmatch-privacy-discover'),
                            title: l10n.showProfileInDiscover,
                            subtitle: l10n.showProfileInDiscoverSubtitle,
                            value: _showInDiscover,
                            onChanged: (v) =>
                                setState(() => _showInDiscover = v),
                          ),
                          const Divider(
                              height: 1, color: AppColors.borderSubtle),
                          _switch(
                            key: const Key('qmatch-privacy-location'),
                            title: l10n.showApproximateLocation,
                            subtitle: l10n.showApproximateLocationSubtitle,
                            value: _showApproxLocation,
                            onChanged: (v) =>
                                setState(() => _showApproxLocation = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _sectionTitle(l10n.privacyDataSecuritySection),
                    const SizedBox(height: AppSpacing.xs),
                    QGlassCard(
                      child: Text(
                        l10n.settingsMvpPrivacyNote,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
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

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: AppColors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _switch({
    Key? key,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                key: key,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.softGold,
              activeTrackColor:
                  AppColors.resonanceViolet.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}
