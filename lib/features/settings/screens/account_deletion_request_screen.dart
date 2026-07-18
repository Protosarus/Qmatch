import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_support.dart';
import '../../../core/theme/app_colors.dart';
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
          backgroundColor: AppColors.surface,
          title: Text(
            l10n.accountDeletionSuccessTitle,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            l10n.accountDeletionSuccessBody(AppSupport.email),
            style: GoogleFonts.inter(color: Colors.white, height: 1.45),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
              child: Text(l10n.accountDeletionSuccessAction),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: Text(
          l10n.accountDeletionTitle,
          style: GoogleFonts.playfairDisplay(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: !_pendingLoaded
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : (_alreadyPending ? _buildPendingBody(l10n) : _buildRequestBody(l10n)),
    );
  }

  Widget _buildPendingBody(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        Text(
          l10n.accountDeletionPendingTitle,
          style: GoogleFonts.inter(
            color: AppColors.primary,
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
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
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
        CheckboxListTile(
          value: _ackIrreversible,
          onChanged: (v) => setState(() => _ackIrreversible = v ?? false),
          activeColor: AppColors.primary,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.accountDeletionAckIrreversible,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          ),
        ),
        CheckboxListTile(
          value: _ackTimeline,
          onChanged: (v) => setState(() => _ackTimeline = v ?? false),
          activeColor: AppColors.primary,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.accountDeletionAckTimeline,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          ),
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
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.25),
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
        FilledButton(
          onPressed: _canSubmit ? () => _submit(l10n) : null,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            disabledBackgroundColor: Colors.red.withValues(alpha: 0.25),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  l10n.accountDeletionSubmit,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
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
    return Container(
      width: double.infinity,
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
}
