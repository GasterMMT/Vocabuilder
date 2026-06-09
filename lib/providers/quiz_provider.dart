import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/word.dart';
import '../models/quiz_question.dart';

class QuizProvider extends ChangeNotifier {
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  bool _isCompleted = false;
  bool _isLoading = false;

  List<QuizQuestion> get questions => _questions;
  QuizQuestion? get currentQuestion =>
      _currentIndex < _questions.length ? _questions[_currentIndex] : null;
  int get currentIndex => _currentIndex;
  int get totalQuestions => _questions.length;
  bool get isCompleted => _isCompleted;
  bool get isLoading => _isLoading;

  int get correctCount =>
      _questions.where((q) => q.isCorrect == true).length;
  int get incorrectCount =>
      _questions.where((q) => q.isCorrect == false).length;
  int get unansweredCount =>
      _questions.where((q) => q.isCorrect == null).length;
  double get accuracy =>
      totalQuestions > 0 ? correctCount / totalQuestions : 0.0;

  void generateQuiz(List<Word> wordPool, {int questionCount = 10}) {
    _isLoading = true;
    notifyListeners();

    if (wordPool.length < 4) {
      _questions = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    final random = Random();
    final selectedWords = List<Word>.from(wordPool)..shuffle(random);

    final actualCount = min(questionCount, selectedWords.length);
    final quizWords = selectedWords.take(actualCount).toList();

    _questions = quizWords.map((word) {
      // Generate options: 1 correct + 3 random incorrect
      final otherWords = wordPool.where((w) => w.id != word.id).toList();
      otherWords.shuffle(random);

      final incorrectOptions = otherWords.take(3).map((w) => w.translation).toList();

      // Ensure we have enough options
      while (incorrectOptions.length < 3 && incorrectOptions.length < wordPool.length - 1) {
        final extraWord = wordPool[random.nextInt(wordPool.length)];
        if (extraWord.id != word.id &&
            !incorrectOptions.contains(extraWord.translation)) {
          incorrectOptions.add(extraWord.translation);
        }
      }

      final options = [word.translation, ...incorrectOptions];
      options.shuffle(random);

      final correctIndex = options.indexOf(word.translation);

      return QuizQuestion(
        word: word,
        options: options,
        correctIndex: correctIndex,
      );
    }).toList();

    _currentIndex = 0;
    _isCompleted = false;
    _isLoading = false;
    notifyListeners();
  }

  void answerCurrentQuestion(int selectedIndex) {
    if (_isCompleted || currentQuestion == null) return;
    currentQuestion!.selectAnswer(selectedIndex);
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      notifyListeners();
    } else {
      _isCompleted = true;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void reset() {
    _questions = [];
    _currentIndex = 0;
    _isCompleted = false;
    _isLoading = false;
    notifyListeners();
  }
}
