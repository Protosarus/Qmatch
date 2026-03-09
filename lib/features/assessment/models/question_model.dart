class QuestionModel {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final int difficulty;

  QuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.difficulty,
  });

  // JSON'dan model oluştur
  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'] as int,
      difficulty: json['difficulty'] as int,
    );
  }

  // Model'den JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'difficulty': difficulty,
    };
  }
}
