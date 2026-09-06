import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_support.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';
import '../../../core/widgets/cosmic/qmatch_cosmic_background.dart';
import '../../../core/widgets/qmatch_primary_action.dart';
import '../../../core/widgets/qmatch_pushed_screen_header.dart';
import '../../../l10n/app_localizations.dart';
import '../services/account_deletion_coordinator.dart';
import '../services/account_deletion_request_service.dart';

/// Settings → Delete account. Confirms, then deletes.
///
/// Apple-linked accounts still revoke Sign in with Apple before the wipe.
class AccountDeletionRequestScreen extends StatefulWidget {
  const AccountDeletionRequestScreen({
    super.key,
    this.coordinator,
    this.debugAppleLinked = false,
  });

  final AccountDeletionCoordinator? coordinator;
  final bool debugAppleLinked;

  @override
  State<AccountDeletionRequestScreen> createState() =>
      _AccountDeletionRequestScreenState();
}

class _AccountDeletionRequestScreenState
    extends State<AccountDeletionRequestScreen> {
  late final AccountDeletionCoordinator _coordinator =
      widget.coordinator ?? AccountDeletionCoordinator();
  final _confirmController = TextEditingController();

  bool _ackIrreversible = false;
  bool _ackTimeline = false;
  bool _submitting = false;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  bool get _appleLinked =>
      widget.debugAppleLinked || _coordinator.isAppleLinked();

  bool get _canSubmit {
    if (_submitting) return false;
    if (!_ackIrreversible || !_ackTimeline) return false;
    return _confirmController.text.trim().toUpperCase() ==
        AccountDeletionRequestService.confirmationToken;
  }

  String _messageFor(AppLocalizations l10n, AccountDeletionResult result) {
    switch (classifyAccountDeletionError(result)) {
      case AccountDeletionUserError.sessionExpired:
        return l10n.accountDeletionErrorSessionExpired;
      case AccountDeletionUserError.network:
        return l10n.accountDeletionErrorNetwork;
      case AccountDeletionUserError.appleRequired:
        return l10n.accountDeletionAppleReauthHint;
      case AccountDeletionUserError.appleRevoke:
        return l10n.accountDeletionErrorAppleRevoke;
      case AccountDeletionUserError.uidMismatch:
        return l10n.accountDeletionErrorUidMismatch;
      case AccountDeletionUserError.server:
        return l10n.accountDeletionErrorServer;
      case AccountDeletionUserError.retry:
        return l10n.accountDeletionErrorGeneric;
    }
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _inlineError = null;
    });

    final result = await _coordinator.deleteAccount();

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.isCancelled) {
      return;
    }
    if (!result.isSuccess) {
      setState(() => _inlineError = _messageFor(l10n, result));
      return;
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true)
        .popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: QMatchCosmicBackground(
        seed: 53,
        child: SafeArea(
          child: Column(
            children: [
              QMatchPushedScreenHeader(
                key: const Key('qmatch-delete-header'),
                title: l10n.accountDeletionTitle,
                backButtonKey: const Key('qmatch-delete-back'),
                titleKey: const Key('qmatch-delete-title'),
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
                      Text(
                        l10n.accountDeletionWarningTitle,
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 22,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.accountDeletionIntro,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _card(
                        title: l10n.accountDeletionWillDeleteTitle,
                        body: l10n.accountDeletionWillDeleteBody,
                      ),
                      const SizedBox(height: 12),
                      _card(
                        title: l10n.accountDeletionMayRetainTitle,
                        body: l10n.accountDeletionMayRetainBody,
                      ),
                      const SizedBox(height: 12),
                      if (_appleLinked) ...[
                        Text(
                          key: const Key('qmatch-delete-apple-hint'),
                          l10n.accountDeletionAppleReauthHint,
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _checkRow(
                        key: const Key('qmatch-delete-ack-irreversible'),
                        value: _ackIrreversible,
                        onChanged: (v) =>
                            setState(() => _ackIrreversible = v ?? false),
                        label: l10n.accountDeletionAckIrreversible,
                      ),
                      _checkRow(
                        key: const Key('qmatch-delete-ack-timeline'),
                        value: _ackTimeline,
                        onChanged: (v) =>
                            setState(() => _ackTimeline = v ?? false),
                        label: l10n.accountDeletionAckTimeline,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.accountDeletionTypeDeleteHint(
                          AccountDeletionRequestService.confirmationToken,
                        ),
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('qmatch-delete-confirm-field'),
                        controller: _confirmController,
                        enabled: !_submitting,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.characters,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: _fieldDecoration(
                          AccountDeletionRequestService.confirmationToken,
                        ),
                      ),
                      if (_inlineError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          key: const Key('qmatch-delete-error'),
                          _inlineError!,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFFB4A8),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      QMatchPrimaryAction(
                        key: const Key('qmatch-delete-submit'),
                        label: l10n.accountDeletionSubmit,
                        onPressed: _canSubmit ? () => _submit(l10n) : null,
                        enabled: _canSubmit,
                        loading: _submitting,
                        tone: QMatchPrimaryActionTone.destructive,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.accountDeletionNotImmediateNote,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.accountDeletionSupportHint(AppSupport.email),
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
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

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.glassSurfaceStrong,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderGlow),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderGlow),
      ),
    );
  }

  Widget _card({required String title, required String body}) {
    return QGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
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

  Widget _checkRow({
    Key? key,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
  }) {
    return CheckboxListTile(
      key: key,
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.softGold,
      checkColor: AppColors.cosmicBlack,
      side: const BorderSide(color: AppColors.borderSubtle),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      ),
    );
  }
}
