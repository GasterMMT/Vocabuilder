import 'package:flutter/foundation.dart';
import '../models/word_book.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

class WordBookProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<WordBook> _wordBooks = [];

  List<WordBook> get wordBooks => _wordBooks;

  WordBook? get allWordsBook {
    try {
      return _wordBooks.firstWhere((b) => b.name == AppConstants.allWordsBookName);
    } catch (_) {
      return null;
    }
  }

  WordBook? get favoritesBook {
    try {
      return _wordBooks.firstWhere((b) => b.name == AppConstants.favoritesBookName);
    } catch (_) {
      return null;
    }
  }

  List<WordBook> get customBooks =>
      _wordBooks.where((b) => !b.isDefault).toList();

  Future<void> loadWordBooks() async {
    _wordBooks = await _db.getAllWordBooks();
    notifyListeners();
  }

  Future<int> createWordBook(String name, {String? description}) async {
    final book = WordBook(name: name, description: description);
    final id = await _db.insertWordBook(book);
    await loadWordBooks();
    return id;
  }

  Future<void> updateWordBook(WordBook book) async {
    if (book.isDefault) return;
    await _db.updateWordBook(book);
    await loadWordBooks();
  }

  Future<void> _deleteSingleBook(int bookId) async {
    final book = await _db.getWordBookById(bookId);
    if (book == null || book.isDefault) return;
    await _db.deleteWordBook(bookId);
  }

  Future<void> deleteWordBook(int bookId) async {
    await _deleteSingleBook(bookId);
    await loadWordBooks();
  }

  Future<void> deleteWordBooks(List<int> bookIds) async {
    for (final id in bookIds) {
      await _deleteSingleBook(id);
    }
    await loadWordBooks();
  }

  Future<int> getWordCountInBook(int bookId) async {
    return await _db.getWordCountInBook(bookId);
  }

  Future<WordBook?> getBookByName(String name) async {
    return await _db.getWordBookByName(name);
  }

  Future<WordBook?> getBookById(int id) async {
    return await _db.getWordBookById(id);
  }
}
