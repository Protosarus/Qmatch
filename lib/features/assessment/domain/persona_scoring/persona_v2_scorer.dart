import 'dart:math' as math;

import 'persona_prototype.dart';
import 'persona_runtime_handoff_result.dart';
import 'persona_shadow_input.dart';
import 'persona_v2_contract.dart';
import 'persona_v2_frequency_prototypes.dart';
import 'persona_v2_request.dart';

/// Deterministic Persona V2 distance assignment.
///
/// Same group-normalized level+shape math as the 20D shadow scorer, with
/// Frequency V2 as its own 12D group. No random, no silent default Persona.
class PersonaV2Scorer {
  PersonaV2Scorer({required this.legacyCatalog});

  final PersonaProfileCatalog legacyCatalog;

  PersonaRuntimeHandoffResult assign(PersonaV2HandoffRequest request) {
    _validate(request);
    final scores = request.dimensionScores;
    final userMeans = <String, double>{
      for (final g in PersonaV2Contract.groups)
        g: _mean(
          {for (final d in PersonaV2Contract.dimsOf(g)) d: scores[d]!},
        ),
    };
    final userShape = <String, double>{
      for (final d in PersonaV2Contract.all)
        d: scores[d]! - userMeans[PersonaV2Contract.groupOf(d)]!,
    };

    final candidates = <_Candidate>[];
    for (final persona in _stablePersonas()) {
      candidates.add(_score(persona, scores, userShape));
    }
    candidates.sort(_compare);
    final primary = candidates.first;
    final secondary = candidates[1];

    return PersonaRuntimeHandoffResult(
      primaryPersonaId: primary.personaId,
      secondaryPersonaId: secondary.personaId,
      rawDeltaD: math.max(0.0, secondary.distance - primary.distance),
      scoringVersion: PersonaV2Contract.scoringVersion,
      configVersion: PersonaV2Contract.configVersion,
      prototypeVersion: PersonaV2Contract.prototypeVersion,
      policyVersion: PersonaV2Contract.policyVersion,
      source: PersonaV2Contract.source,
    );
  }

  void _validate(PersonaV2HandoffRequest request) {
    if (request.ownerUid.trim().isEmpty) {
      throw PersonaShadowScoringException(
        PersonaShadowFailureCode.ownerUnavailable,
        'Authenticated owner_uid required',
      );
    }
    if (request.iqScoringPolicyVersion.trim().isEmpty ||
        request.eqScoringPolicyVersion.trim().isEmpty ||
        request.frequencyV2ScoringPolicyVersion.trim().isEmpty) {
      throw PersonaShadowScoringException(
        PersonaShadowFailureCode.missingPolicyVersions,
        'IQ/EQ/Frequency V2 policy versions required',
      );
    }
    for (final d in PersonaV2Contract.all) {
      final x = request.dimensionScores[d];
      if (x == null || !x.isFinite || x < 0 || x > 1) {
        throw PersonaShadowScoringException(
          PersonaShadowFailureCode.incompleteDimensionScores,
          'Missing or out-of-range Persona V2 score for $d',
        );
      }
      final n = request.dimensionEvidenceCounts[d];
      if (n == null || n <= 0) {
        throw PersonaShadowScoringException(
          PersonaShadowFailureCode.missingEvidenceCount,
          'Missing evidence_count for $d',
        );
      }
    }
    for (final d in request.dimensionScores.keys) {
      if (!PersonaV2Contract.allSet.contains(d)) {
        throw PersonaShadowScoringException(
          PersonaShadowFailureCode.unknownDimension,
          'Unknown Persona V2 dimension: $d',
        );
      }
    }
  }

  _Candidate _score(
    PersonaPrototype persona,
    Map<String, double> scores,
    Map<String, double> userShape,
  ) {
    final target = _targetVector(persona);
    var dLevel = 0.0;
    var dShape = 0.0;
    for (final g in PersonaV2Contract.groups) {
      final dims = PersonaV2Contract.dimsOf(g);
      final mean = _mean({for (final d in dims) d: target[d]!});
      var level = 0.0;
      var shape = 0.0;
      for (final d in dims) {
        level += _sq(scores[d]! - target[d]!);
        shape += _sq(userShape[d]! - (target[d]! - mean));
      }
      level /= dims.length;
      shape /= dims.length;
      final w = PersonaV2Contract.groupWeight(g);
      dLevel += w * level;
      dShape += w * shape;
    }
    final dCore = PersonaV2Contract.levelDistanceWeight * dLevel +
        PersonaV2Contract.shapeDistanceWeight * dShape;
    return _Candidate(
      personaId: persona.personaId,
      distance: dCore.clamp(0.0, 1.0),
      tieBreakRank: persona.tieBreakRank,
    );
  }

  Map<String, double> _targetVector(PersonaPrototype persona) {
    final v2 = PersonaV2FrequencyPrototypes.requireUnitTarget(
      persona.personaId,
    );
    return {
      for (final d in PersonaV2Contract.iq) d: persona.targetVector[d]!,
      for (final d in PersonaV2Contract.eq) d: persona.targetVector[d]!,
      ...v2,
    };
  }

  List<PersonaPrototype> _stablePersonas() {
    final list = List<PersonaPrototype>.of(legacyCatalog.personas);
    list.sort((a, b) {
      final r = a.tieBreakRank.compareTo(b.tieBreakRank);
      if (r != 0) return r;
      return a.personaId.compareTo(b.personaId);
    });
    if (list.length < 2) {
      throw StateError('Persona V2 requires at least two prototypes');
    }
    return list;
  }

  int _compare(_Candidate a, _Candidate b) {
    if ((a.distance - b.distance).abs() > PersonaV2Contract.numericalEpsilon) {
      return a.distance.compareTo(b.distance);
    }
    final r = a.tieBreakRank.compareTo(b.tieBreakRank);
    if (r != 0) return r;
    return a.personaId.compareTo(b.personaId);
  }

  static double _mean(Map<String, double> values) {
    var s = 0.0;
    for (final v in values.values) {
      s += v;
    }
    return s / values.length;
  }

  static double _sq(double v) => v * v;
}

class _Candidate {
  const _Candidate({
    required this.personaId,
    required this.distance,
    required this.tieBreakRank,
  });

  final String personaId;
  final double distance;
  final int tieBreakRank;
}
