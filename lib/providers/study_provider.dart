import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/study_session.dart';
import '../services/database_service.dart';
import '../utils/helpers.dart';

class StudyProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  int _todayDurationSeconds = 0;
  int _totalDurationSeconds = 0;
  int _totalQuestions = 0;
  int _totalCorrectAnswers = 0;
  int _totalWordsMastered = 0;
  int _totalWordsNotMastered = 0;
  List<StudySession> _recentSessions = [];
  bool _isLoading = false;

  Timer? _studyTimer;
  int _sessionStartTime = 0;
  int _accumulatedTime = 0;
  bool _isStudying = false;

  int get todayDurationSeconds => _todayDurationSeconds;
  int get totalDurationSeconds => _totalDurationSeconds;
  int get totalQuestions => _totalQuestions;
  int get totalCorrectAnswers => _totalCorrectAnswers;
  int get totalWordsMastered => _totalWordsMastered;
  int get totalWordsNotMastered => _totalWordsNotMastered;
  double get accuracy =>
      _totalQuestions > 0 ? _totalCorrectAnswers / _totalQuestions : 0.0;
  List<StudySession> get recentSessions => _recentSessions;
  bool get isStudying => _isStudying;
  int get currentSessionDurationSeconds =>
      _isStudying ? _accumulatedTime : 0;
  bool get isLoading => _isLoading;

  Future<void> loadStats() async {
    _isLoading = true;
    notifyListeners();

    final todaySession = await _db.getTodaySession();
    _todayDurationSeconds = todaySession?.durationSeconds ?? 0;

    _totalDurationSeconds = await _db.getTotalStudyDuration();
    _totalQuestions = await _db.getTotalQuestions();
    _totalCorrectAnswers = await _db.getTotalCorrectAnswers();
    _totalWordsMastered = await _db.getTotalWordsMastered();
    _totalWordsNotMastered = await _db.getTotalWordsNotMastered();

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month - 1, now.day);
    _recentSessions = await _db.getSessionsInRange(monthStart, now);

    _isLoading = false;
    notifyListeners();
  }

  void startStudySession() {
    if (_isStudying) return;
    _isStudying = true;
    _accumulatedTime = 0;
    _sessionStartTime = DateTime.now().millisecondsSinceEpoch;
    _studyTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _accumulatedTime =
          (DateTime.now().millisecondsSinceEpoch - _sessionStartTime) ~/ 1000;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> pauseStudySession() async {
    if (!_isStudying) return;
    _studyTimer?.cancel();
    _isStudying = false;

    // Save accumulated time
    await _db.upsertStudySession(StudySession(
      date: Helpers.todayString(),
      durationSeconds: _accumulatedTime,
    ));

    await loadStats();
    notifyListeners();
  }

  Future<void> endStudySession({int wordsStudied = 0, int wordsMastered = 0, int wordsNotMastered = 0}) async {
    if (!_isStudying) return;
    _studyTimer?.cancel();
    _isStudying = false;

    _accumulatedTime =
        (DateTime.now().millisecondsSinceEpoch - _sessionStartTime) ~/ 1000;

    await _db.upsertStudySession(StudySession(
      date: Helpers.todayString(),
      durationSeconds: _accumulatedTime,
      wordsStudied: wordsStudied,
      wordsMastered: wordsMastered,
      wordsNotMastered: wordsNotMastered,
    ));

    await loadStats();
    notifyListeners();
  }

  Future<void> recordQuizResult({
    required int correctAnswers,
    required int totalQuestions,
    int durationSeconds = 0,
  }) async {
    await _db.upsertStudySession(StudySession(
      date: Helpers.todayString(),
      durationSeconds: durationSeconds,
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
    ));

    _totalQuestions += totalQuestions;
    _totalCorrectAnswers += correctAnswers;
    await loadStats();
  }

  Future<List<StudySession>> getSessionsInRange(
      DateTime start, DateTime end) async {
    return await _db.getSessionsInRange(start, end);
  }

  @override
  void dispose() {
    _studyTimer?.cancel();
    super.dispose();
  }
}
