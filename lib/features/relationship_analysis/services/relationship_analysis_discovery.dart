import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/firestore_paths.dart';
import '../domain/relationship_analysis_state.dart';
import '../domain/relationship_dimensions.dart';

/// Kind of derived Activity Relationship Analysis prompt (not a feed document).
enum RelationshipActivityPromptKind {
  none,
  start,
  resume,
}

class RelationshipActivityPrompt {
  const RelationshipActivityPrompt(this.kind);

  final RelationshipActivityPromptKind kind;

  bool get showCard => kind != RelationshipActivityPromptKind.none;
  bool get showBadge => kind != RelationshipActivityPromptKind.none;
  bool get isResume => kind == RelationshipActivityPromptKind.resume;
}

/// Derived Activity discovery + badge eligibility from RA assessment state.
///
/// Single document listen on `users/{uid}/assessments/relationship`.
/// Never writes Activity feed events.
class RelationshipAnalysisDiscovery {
  RelationshipAnalysisDiscovery._();

  static bool _isBankCompleteDoc(Map<String, dynamic>? doc) {
    final state = RelationshipAnalysisState.fromPersistence(doc);
    if (state.isBankComplete) return true;
    if (doc == null || doc.isEmpty) return false;
    final depth = doc['analysis_depth'];
    if (depth is num && (depth.toDouble() * 100).round() >= 100) {
      return true;
    }
    final count = doc['answered_count'];
    if (count is num &&
        count.toInt() >= RelationshipAnalysisContract.questionCount) {
      return true;
    }
    return false;
  }

  /// True when Profile may still offer a voluntary micro-scan CTA.
  static bool isProfileCtaAvailable(RelationshipAnalysisState state) {
    return !state.isBankComplete;
  }

  /// Proactive Activity card/badge eligibility (respects 24h cooldown except resume).
  static RelationshipActivityPrompt evaluateActivityPrompt({
    required RelationshipAnalysisState state,
    required DateTime now,
  }) {
    final utcNow = now.toUtc();
    if (state.isBankComplete) {
      return const RelationshipActivityPrompt(
        RelationshipActivityPromptKind.none,
      );
    }
    if (state.hasActiveMicroScan) {
      return const RelationshipActivityPrompt(
        RelationshipActivityPromptKind.resume,
      );
    }
    final suppressUntil = state.proactiveNudgeSuppressUntil?.toUtc();
    if (suppressUntil != null && utcNow.isBefore(suppressUntil)) {
      return const RelationshipActivityPrompt(
        RelationshipActivityPromptKind.none,
      );
    }
    return const RelationshipActivityPrompt(
      RelationshipActivityPromptKind.start,
    );
  }

  static RelationshipActivityPrompt evaluateFromDoc(
    Map<String, dynamic>? doc, {
    required DateTime now,
  }) {
    if (_isBankCompleteDoc(doc)) {
      return const RelationshipActivityPrompt(
        RelationshipActivityPromptKind.none,
      );
    }
    final state = RelationshipAnalysisState.fromPersistence(doc);
    return evaluateActivityPrompt(state: state, now: now);
  }

  /// Profile-oriented: any incomplete bank (ignores Activity cooldown).
  static bool isMicroScanAvailable(Map<String, dynamic>? doc) {
    return !_isBankCompleteDoc(doc);
  }

  /// Live canonical Relationship Analysis state for Profile/UI consumers.
  ///
  /// Single Firestore document subscription. The persisted assessment document
  /// remains the source of truth.
  static Stream<RelationshipAnalysisState> watchState({
    String? uid,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) {
    final resolved =
        (uid ?? (auth ?? FirebaseAuth.instance).currentUser?.uid)?.trim();

    if (resolved == null || resolved.isEmpty) {
      return Stream<RelationshipAnalysisState>.value(
        RelationshipAnalysisState.empty(),
      );
    }

    final doc = firestore != null
        ? firestore
            .collection('users')
            .doc(resolved)
            .collection('assessments')
            .doc(RelationshipAnalysisContract.assessmentType)
        : FirestorePaths.userAssessmentDoc(
            resolved,
            RelationshipAnalysisContract.assessmentType,
          );

    return doc.snapshots().map(
          (snap) => RelationshipAnalysisState.fromPersistence(snap.data()),
        );
  }

  static Stream<RelationshipActivityPrompt> watchActivityPrompt({
    String? uid,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    DateTime Function()? clock,
  }) {
    final resolved =
        (uid ?? (auth ?? FirebaseAuth.instance).currentUser?.uid)?.trim();
    if (resolved == null || resolved.isEmpty) {
      return Stream<RelationshipActivityPrompt>.value(
        const RelationshipActivityPrompt(RelationshipActivityPromptKind.none),
      );
    }
    final nowFn = clock ?? DateTime.now;
    final doc = firestore != null
        ? firestore
            .collection('users')
            .doc(resolved)
            .collection('assessments')
            .doc(RelationshipAnalysisContract.assessmentType)
        : FirestorePaths.userAssessmentDoc(
            resolved,
            RelationshipAnalysisContract.assessmentType,
          );
    return doc.snapshots().map((snap) {
      return evaluateFromDoc(snap.data(), now: nowFn());
    });
  }

  /// Convenience stream for Activity tab lilac dot.
  static Stream<bool> watchActivityBadge({
    String? uid,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    DateTime Function()? clock,
  }) {
    return watchActivityPrompt(
      uid: uid,
      auth: auth,
      firestore: firestore,
      clock: clock,
    ).map((p) => p.showBadge);
  }
}
