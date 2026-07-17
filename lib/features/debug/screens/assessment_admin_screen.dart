import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../helpers/assessment_assignment_reset_helper.dart';
import '../helpers/assessment_sets_preflight_helper.dart';
import '../helpers/upload_assessment_sets_helper.dart';

/// Debug-only Assessment Admin surface.
///
/// Safe actions only:
/// - Firestore Preflight Compare (reads only)
/// - Versioned v2 Sync Dry Run (local convert; no writes)
///
/// Never exposes sync/write/upload/seed/delete actions.
/// Not for production navigation — refuse when [kDebugMode] is false.
class AssessmentAdminScreen extends StatefulWidget {
  const AssessmentAdminScreen({super.key});

  static const String routeName = '/debug/assessment-admin';

  @override
  State<AssessmentAdminScreen> createState() => _AssessmentAdminScreenState();
}

class _AssessmentAdminScreenState extends State<AssessmentAdminScreen> {
  bool _preflightLoading = false;
  String? _preflightError;
  AssessmentSetsPreflightReport? _preflightReport;

  bool _v2DryRunLoading = false;
  String? _v2DryRunError;
  AssessmentFirestoreSyncReport? _v2DryRunReport;

  bool _resetLoading = false;
  String? _resetError;
  AssessmentAssignmentResetReport? _resetReport;

  bool _fullResetLoading = false;
  String? _fullResetError;
  AssessmentFullStateResetReport? _fullResetReport;

  bool get _busy =>
      _preflightLoading || _v2DryRunLoading || _resetLoading || _fullResetLoading;

  Future<void> _runPreflight() async {
    if (!kDebugMode) return;
    setState(() {
      _preflightLoading = true;
      _preflightError = null;
    });
    try {
      final report =
          await AssessmentSetsPreflightHelper.compareBundledAssetsWithFirestore();
      if (!mounted) return;
      setState(() {
        _preflightReport = report;
        _preflightLoading = false;
        if (report.refused) {
          _preflightError = report.refusalReason ?? 'Preflight refused';
        } else if (report.errors.isNotEmpty && !report.firestoreReadsPerformed) {
          _preflightError = report.errors.join('\n');
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _preflightLoading = false;
        _preflightError = e.toString();
      });
    }
  }

  Future<void> _runV2SyncDryRun() async {
    if (!kDebugMode) return;
    setState(() {
      _v2DryRunLoading = true;
      _v2DryRunError = null;
    });
    try {
      // Dry-run only — never pass dryRun:false or write confirmation.
      final report =
          await UploadAssessmentSetsHelper.dryRunVersionedV2AssessmentSync();
      if (!mounted) return;
      setState(() {
        _v2DryRunReport = report;
        _v2DryRunLoading = false;
        if (report.errors.isNotEmpty && report.docsConsidered == 0) {
          _v2DryRunError = report.errors.join('\n');
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _v2DryRunLoading = false;
        _v2DryRunError = e.toString();
      });
    }
  }

  Future<void> _runAssignmentReset(
    Future<AssessmentAssignmentResetReport> Function() action,
  ) async {
    if (!kDebugMode) return;
    setState(() {
      _resetLoading = true;
      _resetError = null;
    });
    try {
      final report = await action();
      if (!mounted) return;
      setState(() {
        _resetReport = report;
        _resetLoading = false;
        if (report.refused) {
          _resetError = report.refusalReason ?? 'Reset refused';
        } else if (report.errors.isNotEmpty && report.docsDeleted == 0) {
          _resetError = report.errors.join('\n');
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resetLoading = false;
        _resetError = e.toString();
      });
    }
  }

  Future<void> _runFullStateReset() async {
    if (!kDebugMode) return;
    setState(() {
      _fullResetLoading = true;
      _fullResetError = null;
    });
    try {
      final report =
          await AssessmentAssignmentResetHelper.resetCurrentUserFullAssessmentState();
      if (!mounted) return;
      setState(() {
        _fullResetReport = report;
        _fullResetLoading = false;
        if (report.refused) {
          _fullResetError = report.refusalReason ?? 'Full reset refused';
        } else if (report.errors.isNotEmpty && !report.writesPerformed) {
          _fullResetError = report.errors.join('\n');
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fullResetLoading = false;
        _fullResetError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.primary,
          title: Text(
            'Assessment Admin',
            style: GoogleFonts.playfairDisplay(color: AppColors.primary),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Assessment Admin is available only in debug builds.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        title: Text(
          'Assessment Admin',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Localized Sets Status',
              style: GoogleFonts.playfairDisplay(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Debug-only safe tools. No sync, upload, or write actions on this screen.',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),

            // --- Preflight (read-only Firestore) ---
            Text(
              'Firestore Preflight Compare',
              style: GoogleFonts.playfairDisplay(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reads Firestore assessment_sets and compares with bundled assets. '
              'Reads only — no writes.',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _runPreflight,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                _preflightLoading
                    ? 'Running preflight…'
                    : 'Run Firestore Preflight Compare',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
            if (_preflightLoading) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ],
            if (_preflightError != null) ...[
              const SizedBox(height: 12),
              Text(
                _preflightError!,
                style: GoogleFonts.inter(color: AppColors.error, height: 1.4),
              ),
            ],
            if (_preflightReport != null) ...[
              const SizedBox(height: 16),
              _PreflightReportPanel(report: _preflightReport!),
            ],

            const SizedBox(height: 32),
            Divider(color: AppColors.primary.withValues(alpha: 0.2)),
            const SizedBox(height: 24),

            // --- v2 Sync Dry Run (local only) ---
            Text(
              'Versioned v2 Sync Dry Run',
              style: GoogleFonts.playfairDisplay(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Converts bundled legacy assets to immutable *_v2 docs in memory '
              'and reports what would be published later.\n'
              'Dry run only — no Firestore writes performed.',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _runV2SyncDryRun,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                _v2DryRunLoading
                    ? 'Running v2 dry run…'
                    : 'Run v2 Sync Dry Run',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
            if (_v2DryRunLoading) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ],
            if (_v2DryRunError != null) ...[
              const SizedBox(height: 12),
              Text(
                _v2DryRunError!,
                style: GoogleFonts.inter(color: AppColors.error, height: 1.4),
              ),
            ],
            if (_v2DryRunReport != null) ...[
              const SizedBox(height: 16),
              _V2DryRunReportPanel(report: _v2DryRunReport!),
            ],

            const SizedBox(height: 32),
            Divider(color: AppColors.primary.withValues(alpha: 0.2)),
            const SizedBox(height: 24),

            // --- Current-user assignment reset (debug only) ---
            Text(
              'Reset My Assessment Assignments',
              style: GoogleFonts.playfairDisplay(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current-user assignment reset only. No global assessment content is modified.',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Deletes only users/{uid}/assessment_assignments/{type} for the '
              'signed-in user. Next test open creates a fresh localized assignment '
              'via normal Phase 3H load priority.',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _ResetButton(
              label: 'Reset My IQ Assignment',
              busy: _resetLoading,
              disabled: _busy,
              onPressed: () => _runAssignmentReset(
                AssessmentAssignmentResetHelper.resetIqAssignment,
              ),
            ),
            const SizedBox(height: 10),
            _ResetButton(
              label: 'Reset My EQ Assignment',
              busy: _resetLoading,
              disabled: _busy,
              onPressed: () => _runAssignmentReset(
                AssessmentAssignmentResetHelper.resetEqAssignment,
              ),
            ),
            const SizedBox(height: 10),
            _ResetButton(
              label: 'Reset My Frequency Assignment',
              busy: _resetLoading,
              disabled: _busy,
              onPressed: () => _runAssignmentReset(
                AssessmentAssignmentResetHelper.resetFrequencyAssignment,
              ),
            ),
            const SizedBox(height: 10),
            _ResetButton(
              label: 'Reset All My Assessment Assignments',
              busy: _resetLoading,
              disabled: _busy,
              onPressed: () => _runAssignmentReset(
                AssessmentAssignmentResetHelper.resetAllAssignments,
              ),
            ),
            if (_resetLoading) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ],
            if (_resetError != null) ...[
              const SizedBox(height: 12),
              Text(
                _resetError!,
                style: GoogleFonts.inter(color: AppColors.error, height: 1.4),
              ),
            ],
            if (_resetReport != null) ...[
              const SizedBox(height: 16),
              _ResetReportPanel(report: _resetReport!),
            ],

            const SizedBox(height: 28),
            Divider(color: AppColors.primary.withValues(alpha: 0.2)),
            const SizedBox(height: 20),

            Text(
              'Full Assessment State Reset',
              style: GoogleFonts.playfairDisplay(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current debug user only. Clears IQ/EQ/Frequency progress and result '
              'cache. Does not modify global question data.',
              style: GoogleFonts.inter(
                color: AppColors.error.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Deletes assignment docs, users/{uid}/assessments/frequency, and '
              'assessment result fields on the user doc. Profile and onboarding '
              'fields are preserved.',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _runFullStateReset,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error.withValues(alpha: 0.85),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                _fullResetLoading
                    ? 'Resetting full assessment state…'
                    : 'Reset My Full Assessment State',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
            if (_fullResetLoading) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ],
            if (_fullResetError != null) ...[
              const SizedBox(height: 12),
              Text(
                _fullResetError!,
                style: GoogleFonts.inter(color: AppColors.error, height: 1.4),
              ),
            ],
            if (_fullResetReport != null) ...[
              const SizedBox(height: 16),
              _FullResetReportPanel(report: _fullResetReport!),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreflightReportPanel extends StatelessWidget {
  const _PreflightReportPanel({required this.report});

  final AssessmentSetsPreflightReport report;

  @override
  Widget build(BuildContext context) {
    final missingPreview = _previewIds(report.missingInFirestore);
    final extraPreview = _previewIds(report.extraInFirestore);

    return _PanelShell(
      title: 'Preflight Report',
      children: [
        _line('localDocCount', '${report.localDocCount}'),
        _line('firestoreDocCount', '${report.firestoreDocCount}'),
        _line('expectedDocCount', '${report.expectedDocCount}'),
        _line(
          'local IQ/EQ/Frequency',
          '${report.localIqCount}/${report.localEqCount}/${report.localFrequencyCount}',
        ),
        _line(
          'Firestore IQ/EQ/Frequency',
          '${report.firestoreIqCount}/${report.firestoreEqCount}/${report.firestoreFrequencyCount}',
        ),
        _line(
          'localQuestionCountTotal',
          '${report.localQuestionCountTotal}',
        ),
        _line(
          'firestoreQuestionCountTotal',
          '${report.firestoreQuestionCountTotal}',
        ),
        _line(
          'firestoreLocalizedCount',
          '${report.firestoreLocalizedCount}',
        ),
        _line(
          'firestoreEnglishOnlyCount',
          '${report.firestoreEnglishOnlyCount}',
        ),
        _line(
          'firestorePartiallyLocalizedCount',
          '${report.firestorePartiallyLocalizedCount}',
        ),
        _line(
          'missingInFirestore',
          '${report.missingInFirestore.length}${missingPreview.isEmpty ? '' : ' — $missingPreview'}',
        ),
        _line(
          'extraInFirestore',
          '${report.extraInFirestore.length}${extraPreview.isEmpty ? '' : ' — $extraPreview'}',
        ),
        _line(
          'questionCount mismatches',
          '${report.docsWithQuestionCountMismatch.length}',
        ),
        _line(
          'type mismatches',
          '${report.docsWithTypeMismatch.length}',
        ),
        _line(
          'setNumber mismatches',
          '${report.docsWithSetNumberMismatch.length}',
        ),
        _line(
          'correctAnswer mismatches',
          '${report.docsWithInvalidCorrectAnswer.length}',
        ),
        const SizedBox(height: 8),
        Text(
          'recommendation',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        Text(report.recommendation),
        const SizedBox(height: 12),
        _line('readOnly', 'true'),
        _line('writesPerformed', '${report.firestoreWritesPerformed}'),
        _line(
          'firestoreReadsPerformed',
          '${report.firestoreReadsPerformed}',
        ),
      ],
    );
  }
}

class _V2DryRunReportPanel extends StatelessWidget {
  const _V2DryRunReportPanel({required this.report});

  final AssessmentFirestoreSyncReport report;

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      title: 'v2 Sync Dry-Run Report',
      children: [
        _line('mode', report.mode),
        _line('source', report.source),
        _line('writeEnabledFlag', '${report.writeEnabledFlag}'),
        _line('debugMode', '${report.debugMode}'),
        _line('confirmationAccepted', '${report.confirmationAccepted}'),
        _line('docsConsidered', '${report.docsConsidered}'),
        _line('docsWritten', '${report.docsWritten}'),
        _line('docsSkipped', '${report.docsSkipped}'),
        _line(
          'iqCount / eqCount / frequencyCount',
          '${report.iqDocs} / ${report.eqDocs} / ${report.frequencyDocs}',
        ),
        _line('questionCount', '${report.totalQuestions}'),
        _line('versionedIdCount', '${report.versionedIdCount}'),
        _line('legacyIdCount', '${report.legacyIdCount}'),
        _line('version', '${report.contentVersion}'),
        _line('status', report.status),
        _line('active', '${report.active}'),
        _line('language_mode', report.languageMode),
        _line('targetCollection', report.targetCollection),
        _line('writesPerformed', '${report.firestoreWritesPerformed}'),
        if (report.documentIds.isNotEmpty)
          _line(
            'doc IDs (first/last)',
            '${report.documentIds.first} … ${report.documentIds.last} '
                '(${report.documentIds.length})',
          ),
        if (report.warnings.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'warnings',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          ...report.warnings.map(
            (w) => Text(
              '· $w',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
        if (report.errors.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'errors',
            style: GoogleFonts.inter(
              color: AppColors.error,
              fontSize: 12,
            ),
          ),
          ...report.errors.map(
            (e) => Text(
              '· $e',
              style: GoogleFonts.inter(
                color: AppColors.error,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Dry run only — no Firestore writes performed.',
          style: GoogleFonts.inter(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({
    required this.label,
    required this.onPressed,
    required this.busy,
    required this.disabled,
  });

  final String label;
  final VoidCallback onPressed;
  final bool busy;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: disabled ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        busy ? 'Working…' : label,
        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ResetReportPanel extends StatelessWidget {
  const _ResetReportPanel({required this.report});

  final AssessmentAssignmentResetReport report;

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      title: 'Assignment Reset Report',
      children: [
        _line('scope', report.scope),
        _line('currentUserIdMasked', report.currentUserIdMasked),
        _line(
          'assignmentTypesReset',
          report.assignmentTypesReset.isEmpty
              ? '(none)'
              : report.assignmentTypesReset.join(', '),
        ),
        _line('docsDeleted', '${report.docsDeleted}'),
        _line('writesPerformed', '${report.writesPerformed}'),
        if (report.warnings.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'warnings',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          ...report.warnings.map(
            (w) => Text(
              '· $w',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
        if (report.errors.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'errors',
            style: GoogleFonts.inter(
              color: AppColors.error,
              fontSize: 12,
            ),
          ),
          ...report.errors.map(
            (e) => Text(
              '· $e',
              style: GoogleFonts.inter(
                color: AppColors.error,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Current-user assignment reset only. No global assessment content modified.',
          style: GoogleFonts.inter(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FullResetReportPanel extends StatelessWidget {
  const _FullResetReportPanel({required this.report});

  final AssessmentFullStateResetReport report;

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      title: 'Full Assessment State Reset Report',
      children: [
        _line('scope', report.scope),
        _line('currentUserIdMasked', report.currentUserIdMasked),
        _line('assignmentDocsDeleted', '${report.assignmentDocsDeleted}'),
        _line('resultDocsDeleted', '${report.resultDocsDeleted}'),
        _line(
          'userFieldsDeleted',
          report.userFieldsDeleted.isEmpty
              ? '(none)'
              : report.userFieldsDeleted.join(', '),
        ),
        _line('userFieldsPreserved', report.userFieldsPreservedNote),
        _line('writesPerformed', '${report.writesPerformed}'),
        _line('globalContentTouched', '${report.globalContentTouched}'),
        if (report.warnings.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'warnings',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          ...report.warnings.map(
            (w) => Text(
              '· $w',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
        if (report.errors.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'errors',
            style: GoogleFonts.inter(
              color: AppColors.error,
              fontSize: 12,
            ),
          ),
          ...report.errors.map(
            (e) => Text(
              '· $e',
              style: GoogleFonts.inter(
                color: AppColors.error,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Current debug user only. No global assessment content modified.',
          style: GoogleFonts.inter(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: DefaultTextStyle(
        style: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 13,
          height: 1.45,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

Widget _line(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    ),
  );
}

String _previewIds(List<String> ids) {
  if (ids.isEmpty) return '';
  if (ids.length <= 5) return ids.join(', ');
  return '${ids.take(5).join(', ')}…';
}
