import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: Text(
          l10n.notificationsSettingsTitle,
          style: GoogleFonts.playfairDisplay(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          _card(
            child: Column(
              children: [
                _switch(
                  title: l10n.pushNotifications,
                  subtitle: l10n.pushNotificationsSubtitle,
                  value: _push,
                  onChanged: (v) => setState(() => _push = v),
                ),
                const Divider(height: 1),
                _switch(
                  title: l10n.newMatchNotifications,
                  subtitle: l10n.newMatchNotificationsSubtitle,
                  value: _newMatch,
                  onChanged: _push ? (v) => setState(() => _newMatch = v) : null,
                ),
                const Divider(height: 1),
                _switch(
                  title: l10n.newMessageNotifications,
                  subtitle: l10n.newMessageNotificationsSubtitle,
                  value: _newMessage,
                  onChanged:
                      _push ? (v) => setState(() => _newMessage = v) : null,
                ),
                const Divider(height: 1),
                _switch(
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
          const SizedBox(height: 16),
          Text(
            l10n.settingsMvpNotificationsNote,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: child,
    );
  }

  Widget _switch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
      inactiveThumbColor: Colors.grey.shade700,
      inactiveTrackColor: Colors.grey.shade900,
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 12,
          height: 1.3,
        ),
      ),
    );
  }
}
