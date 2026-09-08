class QuizResult {
  final DateTime date;
  final int correctCount;
  final int totalQuestions;
  final String mode;
  final int? elapsedSeconds;

  QuizResult({
    required this.date,
    required this.correctCount,
    required this.totalQuestions,
    this.mode = 'meaning',
    this.elapsedSeconds,
  });

  int get score =>
      totalQuestions == 0 ? 0 : ((correctCount / totalQuestions) * 100).round();

  String get modeLabel => switch (mode) {
        'fillBlank' => '빈칸 채우기',
        'order' => '순서 배열',
        'matching' => '카드 짝맞추기',
        _ => '뜻 맞추기',
      };

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'correctCount': correctCount,
        'totalQuestions': totalQuestions,
        'mode': mode,
        if (elapsedSeconds != null) 'elapsedSeconds': elapsedSeconds,
      };

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
        date: DateTime.parse(json['date'] as String),
        correctCount: json['correctCount'] as int,
        totalQuestions: json['totalQuestions'] as int,
        mode: json['mode'] as String? ?? 'meaning',
        elapsedSeconds: json['elapsedSeconds'] as int?,
      );
}
