import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/debug/debug_access.dart';
import '../../../core/navigation/auth_wrapper.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';
import '../../../core/widgets/cosmic/qmatch_cosmic_background.dart';
import '../../../core/widgets/qmatch_pushed_screen_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../debug/debug_home_screen.dart';
import '../../discover/domain/discover_passport_snapshot.dart';
import '../../discover/domain/passport_destination_catalog.dart';
import '../../discover/screens/passport_destination_picker_screen.dart';
import '../../discover/services/discover_passport_client.dart';
import '../../iap/domain/resonance_paywall_feature.dart';
import '../../iap/screens/resonance_paywall_screen.dart';
import '../../who_liked_you/navigation/who_liked_you_entry.dart';
import '../services/account_deletion_request_service.dart';
import 'about_screen.dart';
import 'account_deletion_request_screen.dart';
import 'blocked_users_screen.dart';
import 'help_support_screen.dart';
import 'notifications_settings_screen.dart';
import 'privacy_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.debugForceDebugRow,
    this.animateBackground,
    this.deletionService,
    this.debugDeletionPending,
    this.whoLikedYouEntry,
    this.passportClient,
    this.openPaywall,
  });

  /// Test override: when non-null, forces Debug row visibility.
  final bool? debugForceDebugRow;

  /// Goldens: pass false to freeze cosmic animation.
  final bool? animateBackground;

  final AccountDeletionRequestService? deletionService;

  /// When non-null, skips Firestore and uses this pending flag (tests).
  final bool? debugDeletionPending;

  /// UX routing for Resonance → Who Liked You. Tests inject a fake.
  final WhoLikedYouEntry? whoLikedYouEntry;

  final DiscoverPassportClient? passportClient;

  final Future<bool> Function(
    BuildContext context,
    ResonancePaywallFeature feature,
  )? openPaywall;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AccountDeletionRequestService _deletionService =
      widget.deletionService ?? AccountDeletionRequestService();
  late final DiscoverPassportClient _passportClient =
      widget.passportClient ?? DiscoverPassportClient();
  bool _deletionPending = false;
  bool _deletionPendingLoaded = false;
  DiscoverPassportSnapshot _passport = DiscoverPassportSnapshot.worldwide;

  bool get _showDebug => widget.debugForceDebugRow ?? DebugAccess.isAllowed;

  bool get _showPasswordReset {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || (user.email ?? '').trim().isEmpty) return false;

      return user.providerData.any(
        (provider) => provider.providerId == 'password',
      );
    } catch (_) {
      // Widget tests and isolated previews may not initialize Firebase.
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDeletionPending();
    _loadPassport();
  }

  void _showPasswordResetNotice(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          backgroundColor: const Color(0xF5111629),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 105),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: (isError ? AppColors.error : AppColors.resonanceViolet)
                  .withValues(alpha: 0.55),
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: Row(
              children: [
                Icon(
                  isError
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  color: isError ? AppColors.error : const Color(0xFFDAC8ED),
                  size: 21,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFF3EFFA),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  Future<void> _sendPasswordReset() async {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email?.trim();

    if (!_showPasswordReset || email == null || email.isEmpty) {
      return;
    }

    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsResetPasswordConfirmTitle),
        content: Text(l10n.settingsResetPasswordConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('qmatch-settings-reset-password-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.sendResetLink),
          ),
        ],
      ),
    );

    if (shouldSend != true || !mounted) return;

    try {
      await AuthService().sendPasswordResetEmail(email);

      if (!mounted) return;
      _showPasswordResetNotice(l10n.resetPasswordSent);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      final message = switch (error.code) {
        'too-many-requests' => l10n.resetPasswordTooManyRequests,
        'network-request-failed' => l10n.resetPasswordNetworkError,
        _ => l10n.resetPasswordFailed,
      };

      _showPasswordResetNotice(message, isError: true);
    } catch (_) {
      if (!mounted) return;
      _showPasswordResetNotice(
        l10n.resetPasswordFailed,
        isError: true,
      );
    }
  }

  Future<void> _loadDeletionPending() async {
    if (widget.debugDeletionPending != null) {
      if (!mounted) return;
      setState(() {
        _deletionPending = widget.debugDeletionPending!;
        _deletionPendingLoaded = true;
      });
      return;
    }
    final pending = await _deletionService.isAccountDeletionPending();
    if (!mounted) return;
    setState(() {
      _deletionPending = pending;
      _deletionPendingLoaded = true;
    });
  }

  Future<void> _loadPassport() async {
    try {
      final snap = await _passportClient.get();
      if (!mounted) return;
      setState(() => _passport = snap);
    } catch (_) {
      if (!mounted) return;
      setState(() => _passport = DiscoverPassportSnapshot.worldwide);
    }
  }

  String _passportSubtitle(AppLocalizations l10n) {
    if (!_passport.resonanceAccess) {
      return l10n.settingsPassportSubtitleLocked;
    }
    if (_passport.passportEnabled) {
      final turkish = Localizations.localeOf(context).languageCode == 'tr';
      return l10n.settingsPassportSubtitleActive(
        PassportDestinationCatalog.displayCity(
          country: _passport.passportCountry,
          citySlug: _passport.passportCity,
          turkish: turkish,
        ),
      );
    }
    return l10n.settingsPassportSubtitleWorldwide;
  }

  Future<void> _openPassport() async {
    await PassportDestinationPickerScreen.open(
      context,
      client: _passportClient,
      initial: _passport,
      openPaywall: widget.openPaywall ??
          (ctx, feature) => ResonancePaywallScreen.open(
                ctx,
                feature: feature,
              ),
      animateBackground: widget.animateBackground != false,
    );
    if (!mounted) return;
    await _loadPassport();
  }

  Future<void> _openResonance() async {
    final entry = widget.whoLikedYouEntry ?? WhoLikedYouEntry();
    await entry.openFromSettings(context);
  }

  Future<void> _openDeleteAccount() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AccountDeletionRequestScreen(),
      ),
    );
    if (mounted) await _loadDeletionPending();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          title: Text(
            l10n.settingsLogoutConfirmTitle,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            l10n.settingsLogoutConfirmBody,
            style: GoogleFonts.inter(color: AppColors.textSecondary),
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
                backgroundColor: AppColors.danger,
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
      backgroundColor: Colors.transparent,
      body: QMatchCosmicBackground(
        key: const Key('qmatch-settings-cosmic'),
        seed: 17,
        animate: widget.animateBackground,
        child: SafeArea(
          child: Column(
            children: [
              QMatchPushedScreenHeader(
                title: l10n.settingsTitle,
                backButtonKey: const Key('qmatch-settings-back'),
                titleKey: const Key('qmatch-settings-title'),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_deletionPending) ...[
                        QGlassCard(
                          key: const Key('qmatch-settings-deletion-banner'),
                          child: Text(
                            l10n.settingsDeleteAccountPendingBanner,
                            style: GoogleFonts.inter(
                              color: AppColors.softGold,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      _SettingsGroup(
                        title: l10n.settingsGroupPreferences,
                        children: [
                          QMatchSettingsTile(
                            key: const Key('qmatch-settings-resonance'),
                            icon: Icons.auto_awesome_outlined,
                            title: l10n.settingsResonance,
                            subtitle: l10n.settingsResonanceSubtitle,
                            onTap: _openResonance,
                          ),
                          QMatchSettingsTile(
                            key: const Key('qmatch-settings-passport'),
                            icon: Icons.public_outlined,
                            title: l10n.settingsPassport,
                            subtitle: _passportSubtitle(l10n),
                            showLock: !_passport.resonanceAccess,
                            onTap: _openPassport,
                          ),
                          QMatchSettingsTile(
                            key: const Key('qmatch-settings-notifications'),
                            icon: Icons.notifications_outlined,
                            title: l10n.settingsNotifications,
                            subtitle: l10n.settingsNotificationsHonestSubtitle,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const NotificationsSettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SettingsGroup(
                        title: l10n.settingsGroupPrivacySafety,
                        children: [
                          QMatchSettingsTile(
                            key: const Key('qmatch-settings-privacy'),
                            icon: Icons.privacy_tip_outlined,
                            title: l10n.settingsPrivacy,
                            subtitle: l10n.settingsPrivacyHonestSubtitle,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PrivacySettingsScreen(),
                                ),
                              );
                            },
                          ),
                          QMatchSettingsTile(
                            key: const Key('qmatch-settings-blocked'),
                            icon: Icons.block_outlined,
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
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SettingsGroup(
                        title: l10n.settingsGroupHelp,
                        children: [
                          QMatchSettingsTile(
                            key: const Key('qmatch-settings-help'),
                            icon: Icons.help_outline,
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
                          QMatchSettingsTile(
                            key: const Key('qmatch-settings-about'),
                            icon: Icons.info_outline,
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
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SettingsGroup(
                        title: l10n.settingsGroupAccount,
                        children: [
                          if (_showPasswordReset)
                            QMatchSettingsTile(
                              key: const Key('qmatch-settings-reset-password'),
                              icon: Icons.lock_reset_outlined,
                              title: l10n.settingsResetPassword,
                              subtitle: l10n.settingsResetPasswordSubtitle,
                              onTap: _sendPasswordReset,
                            ),
                          QMatchSettingsTile(
                            key: const Key('qmatch-settings-delete'),
                            icon: Icons.delete_forever_outlined,
                            title: deleteTitle,
                            subtitle: deleteSubtitle,
                            destructive: true,
                            onTap: _openDeleteAccount,
                          ),
                        ],
                      ),
                      if (_showDebug) ...[
                        const SizedBox(height: AppSpacing.md),
                        _SettingsGroup(
                          title: l10n.settingsGroupDeveloper,
                          children: [
                            QMatchSettingsTile(
                              key: const Key('qmatch-settings-debug'),
                              icon: Icons.bug_report_outlined,
                              title: l10n.settingsDebug,
                              subtitle: l10n.settingsDebugSubtitle,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const DebugHomeScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      QMatchSettingsTile(
                        key: const Key('qmatch-settings-logout'),
                        icon: Icons.logout,
                        title: l10n.settingsLogout,
                        subtitle: l10n.settingsLogoutSubtitle,
                        destructive: true,
                        emphasized: true,
                        onTap: () async => _confirmLogout(context),
                      ),
                    ],
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

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xxs,
            bottom: AppSpacing.xs,
          ),
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
        QGlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    color: AppColors.borderSubtle,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Modern Settings row (presentation only).
class QMatchSettingsTile extends StatelessWidget {
  const QMatchSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
    this.emphasized = false,
    this.enabled = true,
    this.showLock = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;
  final bool emphasized;
  final bool enabled;
  final bool showLock;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? AppColors.textMuted
        : (destructive ? AppColors.danger : AppColors.textPrimary);
    final iconBg = destructive
        ? AppColors.danger.withValues(alpha: 0.12)
        : AppColors.resonanceViolet.withValues(alpha: 0.16);

    return Material(
      color: emphasized ? AppColors.glassSurfaceStrong : Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showLock)
                  Icon(
                    Icons.lock_outline,
                    color: AppColors.textMuted,
                  )
                else if (enabled)
                  Icon(
                    Icons.chevron_right,
                    color: destructive
                        ? AppColors.danger.withValues(alpha: 0.7)
                        : AppColors.textMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
