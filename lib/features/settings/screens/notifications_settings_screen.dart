import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';
import '../../../core/widgets/cosmic/qmatch_cosmic_background.dart';
import '../../../core/widgets/qmatch_pushed_screen_header.dart';
import '../../../l10n/app_localizations.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _push = true;
  bool _newMatch = true;
  bool _newMessage = true;
  bool _dailyFrequency = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: QMatchCosmicBackground(
        seed: 31,
        child: SafeArea(
          child: Column(
            children: [
              QMatchPushedScreenHeader(
                key: const Key('qmatch-notifications-header'),
                title: l10n.notificationsSettingsTitle,
                backButtonKey: const Key('qmatch-notifications-back'),
                titleKey: const Key('qmatch-notifications-title'),
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
                    QGlassCard(
                      key: const Key('qmatch-notifications-card'),
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _switch(
                            key: const Key('qmatch-notifications-push'),
                            title: l10n.pushNotifications,
                            subtitle: l10n.pushNotificationsSubtitle,
                            value: _push,
                            onChanged: (v) => setState(() => _push = v),
                          ),
                          const Divider(
                              height: 1, color: AppColors.borderSubtle),
                          _switch(
                            key: const Key('qmatch-notifications-match'),
                            title: l10n.newMatchNotifications,
                            subtitle: l10n.newMatchNotificationsSubtitle,
                            value: _newMatch,
                            onChanged: _push
                                ? (v) => setState(() => _newMatch = v)
                                : null,
                          ),
                          const Divider(
                              height: 1, color: AppColors.borderSubtle),
                          _switch(
                            key: const Key('qmatch-notifications-message'),
                            title: l10n.newMessageNotifications,
                            subtitle: l10n.newMessageNotificationsSubtitle,
                            value: _newMessage,
                            onChanged: _push
                                ? (v) => setState(() => _newMessage = v)
                                : null,
                          ),
                          const Divider(
                              height: 1, color: AppColors.borderSubtle),
                          _switch(
                            key: const Key('qmatch-notifications-frequency'),
                            title: l10n.frequencyDailySuggestions,
                            subtitle: l10n.frequencyDailySuggestionsSubtitle,
                            value: _dailyFrequency,
                            onChanged: _push
                                ? (v) => setState(() => _dailyFrequency = v)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    QGlassCard(
                      child: Text(
                        l10n.settingsMvpNotificationsNote,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.45,
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

  Widget _switch({
    Key? key,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
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
                      color: Colors.white,
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
