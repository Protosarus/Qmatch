import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/navigation/auth_wrapper.dart';
import '../../debug/debug_home_screen.dart';
import 'about_screen.dart';
import 'account_deletion_request_screen.dart';
import 'blocked_users_screen.dart';
import 'help_support_screen.dart';
import 'notifications_settings_screen.dart';
import 'privacy_settings_screen.dart';
import '../services/account_deletion_request_service.dart';
import '../../../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _deletionService = AccountDeletionRequestService();
  bool _deletionPending = false;
  bool _deletionPendingLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadDeletionPending();
  }

  Future<void> _loadDeletionPending() async {
    final pending = await _deletionService.isAccountDeletionPending();
    if (!mounted) return;
    setState(() {
      _deletionPending = pending;
      _deletionPendingLoaded = true;
    });
  }

  Future<void> _openDeleteAccount() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AccountDeletionRequestScreen(),
      ),
    );
    // Refresh status after returning (e.g. user just submitted).
    if (mounted) await _loadDeletionPending();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            l10n.settingsLogoutConfirmTitle,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            l10n.settingsLogoutConfirmBody,
            style: GoogleFonts.inter(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                l10n.cancel,
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                l10n.settingsLogout,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    await AuthService().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final deleteTitle = _deletionPending
        ? l10n.settingsDeleteAccountPendingStatus
        : l10n.settingsDeleteAccount;
    final deleteSubtitle = !_deletionPendingLoaded
        ? l10n.settingsDeleteAccountSubtitle
        : (_deletionPending
            ? l10n.settingsDeleteAccountPendingSubtitle
            : l10n.settingsDeleteAccountSubtitle);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text(
                    l10n.settingsTitle,
                    style: GoogleFonts.playfairDisplay(
                      color: AppColors.primary,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  if (_deletionPending) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        l10n.settingsDeleteAccountPendingBanner,
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                  _buildSettingItem(
                    icon: Icons.notifications,
                    title: l10n.settingsNotifications,
                    subtitle: l10n.settingsNotificationsSubtitle,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingItem(
                    icon: Icons.privacy_tip,
                    title: l10n.settingsPrivacy,
                    subtitle: l10n.settingsPrivacySubtitle,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PrivacySettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingItem(
                    icon: Icons.block,
                    title: l10n.settingsBlocked,
                    subtitle: l10n.settingsBlockedSubtitle,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BlockedUsersScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingItem(
                    icon: Icons.help,
                    title: l10n.settingsHelpSupport,
                    subtitle: l10n.settingsHelpSupportSubtitle,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingItem(
                    icon: Icons.info,
                    title: l10n.settingsAbout,
                    subtitle: l10n.settingsAboutSubtitle,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingItem(
                    icon: Icons.delete_forever_outlined,
                    title: deleteTitle,
                    subtitle: deleteSubtitle,
                    isDestructive: true,
                    onTap: _openDeleteAccount,
                  ),
                  if (kDebugMode)
                    _buildSettingItem(
                      icon: Icons.bug_report_outlined,
                      title: 'Debug',
                      subtitle: 'Assessment Admin / tools (debug only)',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DebugHomeScreen(),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                  _buildSettingItem(
                    icon: Icons.logout,
                    title: l10n.settingsLogout,
                    subtitle: l10n.settingsLogoutSubtitle,
                    isDestructive: true,
                    onTap: () async {
                      await _confirmLogout(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withValues(alpha: 0.1)
                : AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: isDestructive ? Colors.red : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDestructive ? Colors.red : AppColors.textSecondary,
        ),
      ),
    );
  }
}
