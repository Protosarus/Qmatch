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
    final id = json['id']?.toString().trim() ?? '';
    if (id.isEmpty) {
      throw FormatException('QuestionModel.fromJson requires non-empty id');
    }
    return QuestionModel(
      id: id,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctAnswer: (json['correctAnswer'] as num?)?.toInt() ?? 0,
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 0,
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
