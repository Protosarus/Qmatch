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
import '../services/account_deletion_request_service.dart';

/// Settings → Account → Delete Account — submits a **request**, does not wipe data.
class AccountDeletionRequestScreen extends StatefulWidget {
  const AccountDeletionRequestScreen({super.key});

  @override
  State<AccountDeletionRequestScreen> createState() =>
      _AccountDeletionRequestScreenState();
}

class _AccountDeletionRequestScreenState
    extends State<AccountDeletionRequestScreen> {
  final _service = AccountDeletionRequestService();
  final _confirmController = TextEditingController();

  bool _ackIrreversible = false;
  bool _ackTimeline = false;
  bool _submitting = false;
  bool _alreadyPending = false;
  bool _pendingLoaded = false;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(() => setState(() {}));
    _loadPending();
  }

  Future<void> _loadPending() async {
    final pending = await _service.isAccountDeletionPending();
    if (!mounted) return;
    setState(() {
      _alreadyPending = pending;
      _pendingLoaded = true;
    });
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_submitting || _alreadyPending || !_pendingLoaded) return false;
    if (!_ackIrreversible || !_ackTimeline) return false;
    return _confirmController.text.trim().toUpperCase() ==
        AccountDeletionRequestService.confirmationToken;
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _inlineError = null;
    });

    final result = await _service.submitRequest(
      localeLanguageCode: Localizations.localeOf(context).languageCode,
      appVersion: l10n.aboutVersion,
    );

    if (!mounted) return;

    setState(() => _submitting = false);

    if (!result.ok) {
      setState(() {
        _inlineError = result.errorMessage == 'not_signed_in'
            ? l10n.loginRequired
            : l10n.accountDeletionRequestError;
      });
      return;
    }

    if (result.alreadyRequested) {
      setState(() => _alreadyPending = true);
      return;
    }

    setState(() => _alreadyPending = true);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          title: Text(
            l10n.accountDeletionSuccessTitle,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            l10n.accountDeletionSuccessBody(AppSupport.email),
            style: GoogleFonts.inter(color: Colors.white, height: 1.45),
          ),
          actions: [
            SizedBox(
              width: 170,
              child: QMatchPrimaryAction(
                label: l10n.accountDeletionSuccessAction,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      },
    );
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
                child: !_pendingLoaded
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.softGold,
                          ),
                        ),
                      )
                    : (_alreadyPending
                        ? _buildPendingBody(l10n)
                        : _buildRequestBody(l10n)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingBody(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        Text(
          l10n.accountDeletionPendingTitle,
          style: GoogleFonts.inter(
            color: AppColors.softGold,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.accountDeletionPendingBody(AppSupport.email),
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        _card(
          title: l10n.accountDeletionTimelineTitle,
          body: l10n.accountDeletionTimelineBody,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.accountDeletionSupportHint(AppSupport.email),
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.accountDeletionPendingNoResubmit,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestBody(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        Text(
          l10n.accountDeletionWarningTitle,
          style: GoogleFonts.inter(
            color: Colors.redAccent,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.accountDeletionIntro,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
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
        _card(
          title: l10n.accountDeletionTimelineTitle,
          body: l10n.accountDeletionTimelineBody,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.accountDeletionSupportHint(AppSupport.email),
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        _checkRow(
          value: _ackIrreversible,
          onChanged: (v) => setState(() => _ackIrreversible = v ?? false),
          label: l10n.accountDeletionAckIrreversible,
        ),
        _checkRow(
          value: _ackTimeline,
          onChanged: (v) => setState(() => _ackTimeline = v ?? false),
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
          controller: _confirmController,
          enabled: !_submitting,
          autocorrect: false,
          textCapitalization: TextCapitalization.characters,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: AccountDeletionRequestService.confirmationToken,
            hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.glassSurfaceStrong,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.borderGlow,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.borderGlow,
              ),
            ),
          ),
        ),
        if (_inlineError != null) ...[
          const SizedBox(height: 12),
          Text(
            _inlineError!,
            style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13),
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
      ],
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
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
  }) {
    return CheckboxListTile(
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
