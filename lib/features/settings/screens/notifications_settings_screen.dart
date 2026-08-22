import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';
import '../../../core/widgets/cosmic/qmatch_cosmic_background.dart';
import '../../../core/widgets/qmatch_pushed_screen_header.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/notification_prefs_snapshot.dart';
import '../services/notification_prefs_client.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({
    super.key,
    this.client,
  });

  final NotificationPrefsClient? client;

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  late final NotificationPrefsClient _client;
  NotificationPrefsSnapshot _prefs = NotificationPrefsSnapshot.allEnabled;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _client = widget.client ?? NotificationPrefsClient();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await _client.get();
      if (!mounted) return;
      setState(() {
        _prefs = prefs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _prefs = NotificationPrefsSnapshot.allEnabled;
        _loading = false;
      });
      _showError(AppLocalizations.of(context)!.notificationPrefsLoadFailed);
    }
  }

  Future<void> _apply(NotificationPrefsSnapshot next) async {
    if (_saving) return;
    final previous = _prefs;
    setState(() {
      _prefs = next;
      _saving = true;
    });
    try {
      final saved = await _client.set(next);
      if (!mounted) return;
      setState(() {
        _prefs = saved;
        _saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _prefs = previous;
        _saving = false;
      });
      _showError(AppLocalizations.of(context)!.notificationPrefsSaveFailed);
    }
  }

  void _showError(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final masterOn = _prefs.pushMaster;
    final controlsEnabled = !_loading && !_saving;

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
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.md),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    QGlassCard(
                      key: const Key('qmatch-notifications-card'),
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _switch(
                            key: const Key('qmatch-notifications-push'),
                            title: l10n.pushNotifications,
                            subtitle: l10n.pushNotificationsSubtitle,
                            value: _prefs.pushMaster,
                            onChanged: controlsEnabled
                                ? (v) => _apply(
                                      _prefs.copyWith(pushMaster: v),
                                    )
                                : null,
                          ),
                          const Divider(
                            height: 1,
                            color: AppColors.borderSubtle,
                          ),
                          _switch(
                            key: const Key('qmatch-notifications-match'),
                            title: l10n.newMatchNotifications,
                            subtitle: l10n.newMatchNotificationsSubtitle,
                            value: _prefs.matches,
                            onChanged: controlsEnabled && masterOn
                                ? (v) => _apply(
                                      _prefs.copyWith(matches: v),
                                    )
                                : null,
                          ),
                          const Divider(
                            height: 1,
                            color: AppColors.borderSubtle,
                          ),
                          _switch(
                            key: const Key('qmatch-notifications-message'),
                            title: l10n.newMessageNotifications,
                            subtitle: l10n.newMessageNotificationsSubtitle,
                            value: _prefs.messages,
                            onChanged: controlsEnabled && masterOn
                                ? (v) => _apply(
                                      _prefs.copyWith(messages: v),
                                    )
                                : null,
                          ),
                          const Divider(
                            height: 1,
                            color: AppColors.borderSubtle,
                          ),
                          _switch(
                            key: const Key(
                              'qmatch-notifications-super-resonance',
                            ),
                            title: l10n.superResonanceNotifications,
                            subtitle: l10n.superResonanceNotificationsSubtitle,
                            value: _prefs.superResonance,
                            onChanged: controlsEnabled && masterOn
                                ? (v) => _apply(
                                      _prefs.copyWith(superResonance: v),
                                    )
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
