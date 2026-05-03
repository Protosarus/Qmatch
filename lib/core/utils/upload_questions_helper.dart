import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// TODO: Legacy questions collection upload. New scalable system uses assessment_sets
// (see UploadAssessmentSetsHelper in lib/features/debug/helpers/).
class UploadQuestionsHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> uploadIQQuestions() async {
    try {
      // JSON dosyasından tüm soruları oku
      final String response =
          await rootBundle.loadString('assets/data/iq_questions.json');
      final List<dynamic> iqQuestions = json.decode(response);

      debugPrint('📤 Uploading ${iqQuestions.length} IQ questions...');

      await _firestore.collection('questions').doc('iq_feb_2026').set({
        'type': 'iq',
        'active': true,
        'questions': iqQuestions,
        'created_at': FieldValue.serverTimestamp(),
        'question_count': iqQuestions.length,
      });

      debugPrint('✅ ${iqQuestions.length} IQ questions uploaded to Firestore!');
    } catch (e) {
      debugPrint('❌ Error uploading IQ questions: $e');
      rethrow;
    }
  }

  static Future<void> uploadEQQuestions() async {
    try {
      // JSON dosyasından tüm soruları oku
      final String response =
          await rootBundle.loadString('assets/data/eq_questions.json');
      final List<dynamic> eqQuestions = json.decode(response);

      debugPrint('📤 Uploading ${eqQuestions.length} EQ questions...');

      await _firestore.collection('questions').doc('eq_feb_2026').set({
        'type': 'eq',
        'active': true,
        'questions': eqQuestions,
        'created_at': FieldValue.serverTimestamp(),
        'question_count': eqQuestions.length,
      });

      debugPrint('✅ ${eqQuestions.length} EQ questions uploaded to Firestore!');
    } catch (e) {
      debugPrint('❌ Error uploading EQ questions: $e');
      rethrow;
    }
  }

  static Future<void> uploadAllQuestions() async {
    await uploadIQQuestions();
    await uploadEQQuestions();
  }
}
