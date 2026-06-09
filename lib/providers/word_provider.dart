import 'package:flutter/foundation.dart';
import '../models/word.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

class WordProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<Word> _allWords = [];
  List<Word> _wordsInCurrentBook = [];
  SortMode _currentSortMode = SortMode.alphabeticalAsc;
  int? _currentBookId;

  List<Word> get allWords => _allWords;
  List<Word> get wordsInCurrentBook => _wordsInCurrentBook;
  SortMode get currentSortMode => _currentSortMode;
  int? get currentBookId => _currentBookId;

  int get totalWordCount => _allWords.length;
  int get favoriteCount => _allWords.where((w) => w.isFavorite).length;

  Future<void> loadAllWords() async {
    _allWords = await _db.getAllWords(sortMode: _currentSortMode);
    notifyListeners();
  }

  Future<void> loadWordsInBook(int bookId) async {
    _currentBookId = bookId;
    _wordsInCurrentBook = await _db.getWordsInBook(bookId, sortMode: _currentSortMode);
    notifyListeners();
  }

  void setSortMode(SortMode mode) {
    _currentSortMode = mode;
    notifyListeners();
    if (_currentBookId != null) {
      loadWordsInBook(_currentBookId!);
    } else {
      loadAllWords();
    }
  }

  /// Check for duplicate word before adding
  Future<Word?> checkDuplicate(String wordText) async {
    return await _db.findDuplicateWord(wordText);
  }

  Future<int> addWord(Word word, {List<int>? wordBookIds}) async {
    final id = await _db.insertWord(word, wordBookIds: wordBookIds);
    await loadAllWords();
    if (_currentBookId != null) {
      await loadWordsInBook(_currentBookId!);
    }
    return id;
  }

  Future<void> updateWord(Word word) async {
    await _db.updateWord(word);
    await loadAllWords();
    if (_currentBookId != null) {
      await loadWordsInBook(_currentBookId!);
    }
  }

  Future<void> toggleFavorite(int wordId) async {
    await _db.toggleFavorite(wordId);
    // Reload both all words and current book to sync everything
    await loadAllWords();
    if (_currentBookId != null) {
      await loadWordsInBook(_currentBookId!);
    }
  }

  Future<void> deleteWord(int wordId) async {
    await _db.deleteWord(wordId);
    await loadAllWords();
    if (_currentBookId != null) {
      await loadWordsInBook(_currentBookId!);
    }
  }

  Future<void> removeWordFromBook(int wordId, int bookId) async {
    await _db.removeWordFromBook(wordId, bookId);
    await loadAllWords();
    if (_currentBookId != null) {
      await loadWordsInBook(_currentBookId!);
    }
  }

  Future<void> addWordToBook(int wordId, int bookId) async {
    await _db.addWordToBook(wordId, bookId);
    await loadAllWords();
    if (_currentBookId == bookId) {
      await loadWordsInBook(bookId);
    }
  }

  Future<void> deleteWords(List<int> wordIds) async {
    for (final id in wordIds) {
      await _db.deleteWord(id);
    }
    await loadAllWords();
    if (_currentBookId != null) {
      await loadWordsInBook(_currentBookId!);
    }
  }

  Future<void> removeWordsFromBook(List<int> wordIds, int bookId) async {
    for (final id in wordIds) {
      await _db.removeWordFromBook(id, bookId);
    }
    await loadAllWords();
    if (_currentBookId != null) {
      await loadWordsInBook(_currentBookId!);
    }
  }

  Future<void> batchToggleFavorite(List<int> wordIds) async {
    for (final id in wordIds) {
      await _db.toggleFavorite(id);
    }
    await loadAllWords();
    if (_currentBookId != null) {
      await loadWordsInBook(_currentBookId!);
    }
  }

  Future<List<Word>> getWordsForSelection({
    List<int>? specificWordIds,
    int? wordBookId,
    bool random = false,
    int? limit,
  }) async {
    List<Word> words;

    if (specificWordIds != null && specificWordIds.isNotEmpty) {
      words = [];
      for (final id in specificWordIds) {
        final word = await _db.getWordById(id);
        if (word != null) words.add(word);
      }
    } else if (wordBookId != null) {
      words = await _db.getWordsInBook(wordBookId);
    } else {
      words = await _db.getAllWords();
    }

    if (random) {
      words.shuffle();
    }

    if (limit != null && words.length > limit) {
      words = words.take(limit).toList();
    }

    return words;
  }

  Future<void> refresh() async {
    await loadAllWords();
    if (_currentBookId != null) {
      await loadWordsInBook(_currentBookId!);
    }
  }
}
