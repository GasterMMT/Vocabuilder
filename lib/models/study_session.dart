class StudySession {
  final int? id;
  final String date; // YYYY-MM-DD
  final int durationSeconds;
  final int wordsStudied;
  final int correctAnswers;
  final int totalQuestions;
  final int wordsMastered;
  final int wordsNotMastered;

  StudySession({
    this.id,
    required this.date,
    this.durationSeconds = 0,
    this.wordsStudied = 0,
    this.correctAnswers = 0,
    this.totalQuestions = 0,
    this.wordsMastered = 0,
    this.wordsNotMastered = 0,
  });

  double get accuracy =>
      totalQuestions > 0 ? correctAnswers / totalQuestions : 0.0;

  StudySession copyWith({
    int? id,
    String? date,
    int? durationSeconds,
    int? wordsStudied,
    int? correctAnswers,
    int? totalQuestions,
    int? wordsMastered,
    int? wordsNotMastered,
  }) {
    return StudySession(
      id: id ?? this.id,
      date: date ?? this.date,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      wordsStudied: wordsStudied ?? this.wordsStudied,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      wordsMastered: wordsMastered ?? this.wordsMastered,
      wordsNotMastered: wordsNotMastered ?? this.wordsNotMastered,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'duration_seconds': durationSeconds,
      'words_studied': wordsStudied,
      'correct_answers': correctAnswers,
      'total_questions': totalQuestions,
      'words_mastered': wordsMastered,
      'words_not_mastered': wordsNotMastered,
    };
  }

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      id: map['id'] as int?,
      date: map['date'] as String,
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      wordsStudied: map['words_studied'] as int? ?? 0,
      correctAnswers: map['correct_answers'] as int? ?? 0,
      totalQuestions: map['total_questions'] as int? ?? 0,
      wordsMastered: map['words_mastered'] as int? ?? 0,
      wordsNotMastered: map['words_not_mastered'] as int? ?? 0,
    );
  }

  @override
  String toString() =>
      'StudySession(date: $date, duration: $durationSeconds, accuracy: $accuracy)';
}
