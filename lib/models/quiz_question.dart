import 'word.dart';

class QuizQuestion {
  final Word word;
  final List<String> options; // 4 options including correct answer
  final int correctIndex;
  int? selectedIndex;
  bool? isCorrect;

  QuizQuestion({
    required this.word,
    required this.options,
    required this.correctIndex,
    this.selectedIndex,
    this.isCorrect,
  });

  String get correctAnswer => word.translation;

  void selectAnswer(int index) {
    selectedIndex = index;
    isCorrect = index == correctIndex;
  }

  void reset() {
    selectedIndex = null;
    isCorrect = null;
  }
}
