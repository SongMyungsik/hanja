class QuizResult {
  final DateTime date;
  final int correctCount;
  final int totalQuestions;

  QuizResult({
    required this.date,
    required this.correctCount,
    required this.totalQuestions,
  });

  int get score =>
      totalQuestions == 0 ? 0 : ((correctCount / totalQuestions) * 100).round();

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'correctCount': correctCount,
        'totalQuestions': totalQuestions,
      };

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
        date: DateTime.parse(json['date'] as String),
        correctCount: json['correctCount'] as int,
        totalQuestions: json['totalQuestions'] as int,
      );
}
