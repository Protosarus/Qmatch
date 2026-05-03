import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Debug/admin helper: uploads bundled `assessment_sets/*.json` into Firestore.
///
/// Does not grant client write access by itself — deploy matching security rules.
class UploadAssessmentSetsHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<int> uploadAssetFile(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final sets = (decoded['sets'] as List<dynamic>?) ?? const [];

    var count = 0;
    for (final item in sets) {
      final map = Map<String, dynamic>.from(item as Map<dynamic, dynamic>);
      final id = map['id'] as String?;
      if (id == null || id.isEmpty) continue;

      await _firestore.collection('assessment_sets').doc(id).set(
            {
              ...map,
              'created_at': FieldValue.serverTimestamp(),
              'updated_at': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
      count++;
    }

    debugPrint('📤 Uploaded $count assessment sets from $assetPath');
    return count;
  }

  /// Uploads IQ, EQ, and Frequency seed bundles; returns total documents written.
  static Future<int> uploadAllBundledSets() async {
    final nIq = await uploadAssetFile('assets/data/assessment_sets/iq_sets.json');
    final nEq = await uploadAssetFile('assets/data/assessment_sets/eq_sets.json');
    final nFq =
        await uploadAssetFile('assets/data/assessment_sets/frequency_sets.json');
    final total = nIq + nEq + nFq;
    debugPrint('✅ Assessment sets upload complete. Total: $total');
    return total;
  }
}
