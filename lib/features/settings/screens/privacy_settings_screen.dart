import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: Text(
          l10n.privacySettingsTitle,
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
          _sectionTitle(l10n.privacyVisibilitySection),
          const SizedBox(height: 10),
          _card(
            child: Column(
              children: [
                _switch(
                  title: l10n.showProfileInDiscover,
                  subtitle: l10n.showProfileInDiscoverSubtitle,
                  value: _showInDiscover,
                  onChanged: (v) => setState(() => _showInDiscover = v),
                ),
                const Divider(height: 1),
                _switch(
                  title: l10n.showApproximateLocation,
                  subtitle: l10n.showApproximateLocationSubtitle,
                  value: _showApproxLocation,
                  onChanged: (v) => setState(() => _showApproxLocation = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle(l10n.privacyDataSecuritySection),
          const SizedBox(height: 10),
          _card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.settingsMvpPrivacyNote,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: AppColors.primary,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
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
    required ValueChanged<bool> onChanged,
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
