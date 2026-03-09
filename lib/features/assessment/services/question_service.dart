import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';

class QuestionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // IQ sorularını yükle (Firestore -> fallback local JSON)
  Future<List<QuestionModel>> loadIQQuestions() async {
    try {
      // Önce Firestore'dan dene
      final snapshot = await _firestore
          .collection('questions')
          .where('type', isEqualTo: 'iq')
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        debugPrint('✅ Loading IQ questions from Firestore');
        final doc = snapshot.docs.first;
        final List<dynamic> questionsData = doc.data()['questions'] ?? [];
        
        return questionsData
            .map((json) => QuestionModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      // Firestore'da yoksa local JSON'dan oku
      debugPrint('⚠️ No questions in Firestore, loading from local JSON');
      final String response =
          await rootBundle.loadString('assets/data/iq_questions.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => QuestionModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error loading IQ questions: $e');
      
      // Hata olursa local JSON'dan dene
      try {
        final String response =
            await rootBundle.loadString('assets/data/iq_questions.json');
        final List<dynamic> data = json.decode(response);
        return data.map((json) => QuestionModel.fromJson(json)).toList();
      } catch (e2) {
        debugPrint('❌ Error loading from local JSON: $e2');
        return [];
      }
    }
  }

  // Random IQ soruları seç
  Future<List<QuestionModel>> getRandomIQQuestions({int count = 10}) async {
    final allQuestions = await loadIQQuestions();
    if (allQuestions.length <= count) {
      return allQuestions;
    }
    final shuffled = List<QuestionModel>.from(allQuestions)..shuffle(Random());
    return shuffled.take(count).toList();
  }

  // EQ sorularını yükle (Firestore -> fallback local JSON)
  Future<List<QuestionModel>> loadEQQuestions() async {
    try {
      // Önce Firestore'dan dene
      final snapshot = await _firestore
          .collection('questions')
          .where('type', isEqualTo: 'eq')
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        debugPrint('✅ Loading EQ questions from Firestore');
        final doc = snapshot.docs.first;
        final List<dynamic> questionsData = doc.data()['questions'] ?? [];
        
        return questionsData
            .map((json) => QuestionModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      // Firestore'da yoksa local JSON'dan oku
      debugPrint('⚠️ No questions in Firestore, loading from local JSON');
      final String response =
          await rootBundle.loadString('assets/data/eq_questions.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => QuestionModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error loading EQ questions: $e');
      
      // Hata olursa local JSON'dan dene
      try {
        final String response =
            await rootBundle.loadString('assets/data/eq_questions.json');
        final List<dynamic> data = json.decode(response);
        return data.map((json) => QuestionModel.fromJson(json)).toList();
      } catch (e2) {
        debugPrint('❌ Error loading from local JSON: $e2');
        return [];
      }
    }
  }

  // Random EQ soruları seç
  Future<List<QuestionModel>> getRandomEQQuestions({int count = 10}) async {
    final allQuestions = await loadEQQuestions();
    if (allQuestions.length <= count) {
      return allQuestions;
    }
    final shuffled = List<QuestionModel>.from(allQuestions)..shuffle(Random());
    return shuffled.take(count).toList();
  }
}
