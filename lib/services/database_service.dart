import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/word.dart';
import '../models/word_book.dart';
import '../models/study_session.dart';
import '../models/llm_config.dart';
import '../utils/constants.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vocabuilder.db');
    return await openDatabase(path, version: 3, onCreate: _onCreate, onUpgrade: _onUpgrade,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'));
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE word_books (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, description TEXT, is_default INTEGER DEFAULT 0, created_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE words (id INTEGER PRIMARY KEY AUTOINCREMENT, word TEXT NOT NULL, translation TEXT NOT NULL, part_of_speech TEXT NOT NULL, example TEXT, notes TEXT, is_favorite INTEGER DEFAULT 0, is_mastered INTEGER DEFAULT NULL, import_time TEXT NOT NULL, created_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE word_book_words (word_id INTEGER NOT NULL, word_book_id INTEGER NOT NULL, added_at TEXT NOT NULL, PRIMARY KEY (word_id, word_book_id), FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE, FOREIGN KEY (word_book_id) REFERENCES word_books(id) ON DELETE CASCADE)''');
    await db.execute('''CREATE TABLE study_sessions (id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, duration_seconds INTEGER DEFAULT 0, words_studied INTEGER DEFAULT 0, correct_answers INTEGER DEFAULT 0, total_questions INTEGER DEFAULT 0, words_mastered INTEGER DEFAULT 0, words_not_mastered INTEGER DEFAULT 0)''');
    await db.execute('''CREATE TABLE llm_configs (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, provider TEXT NOT NULL, api_key TEXT NOT NULL, model TEXT NOT NULL, base_url TEXT, is_active INTEGER DEFAULT 0)''');

    final now = DateTime.now().toIso8601String();
    await db.insert('word_books', {'name': AppConstants.allWordsBookName, 'description': '所有导入的单词', 'is_default': 1, 'created_at': now});
    await db.insert('word_books', {'name': AppConstants.favoritesBookName, 'description': '收藏的单词', 'is_default': 1, 'created_at': now});
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE study_sessions ADD COLUMN words_mastered INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE study_sessions ADD COLUMN words_not_mastered INTEGER DEFAULT 0');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE words ADD COLUMN is_mastered INTEGER DEFAULT NULL');
    }
  }

  // ==================== Helpers ====================

  Future<int?> _getAllWordsBookId(Database db) async {
    final maps = await db.query('word_books', where: 'name = ?', whereArgs: [AppConstants.allWordsBookName], limit: 1);
    return maps.isEmpty ? null : maps.first['id'] as int;
  }

  Future<int?> _getFavoritesBookId(Database db) async {
    final maps = await db.query('word_books', where: 'name = ?', whereArgs: [AppConstants.favoritesBookName], limit: 1);
    return maps.isEmpty ? null : maps.first['id'] as int;
  }

  // ==================== Word Operations ====================

  Future<Word?> findDuplicateWord(String wordText) async {
    final db = await database;
    final maps = await db.query('words', where: 'LOWER(word) = LOWER(?)', whereArgs: [wordText.trim()]);
    return maps.isEmpty ? null : Word.fromMap(maps.first);
  }

  Future<int> insertWord(Word word, {List<int>? wordBookIds}) async {
    final db = await database;

    // Build set of target book IDs - ALWAYS include 全部单词
    final Set<int> allBookIds = {};
    final allBookId = await _getAllWordsBookId(db);
    if (allBookId != null) allBookIds.add(allBookId);

    if (wordBookIds != null) allBookIds.addAll(wordBookIds);

    // If favorited, include favorites book
    if (word.isFavorite) {
      final favBookId = await _getFavoritesBookId(db);
      if (favBookId != null) allBookIds.add(favBookId);
    }

    final wordId = await db.insert('words', word.toMap());

    for (final bookId in allBookIds) {
      try {
        await db.insert('word_book_words', {
          'word_id': wordId, 'word_book_id': bookId,
          'added_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }

    return wordId;
  }

  Future<List<Word>> getAllWords({SortMode sortMode = SortMode.alphabeticalAsc}) async {
    final db = await database;
    final maps = await db.query('words', orderBy: _getSortOrder(sortMode));
    return maps.map((map) => Word.fromMap(map)).toList();
  }

  Future<List<Word>> getWordsInBook(int bookId, {SortMode sortMode = SortMode.alphabeticalAsc}) async {
    final db = await database;
    final orderBy = _getSortOrder(sortMode, tablePrefix: 'w.');
    final maps = await db.rawQuery('''SELECT w.* FROM words w INNER JOIN word_book_words wbw ON w.id = wbw.word_id WHERE wbw.word_book_id = ? ORDER BY $orderBy''', [bookId]);
    return maps.map((map) => Word.fromMap(map)).toList();
  }

  Future<Word?> getWordById(int id) async {
    final db = await database;
    final maps = await db.query('words', where: 'id = ?', whereArgs: [id]);
    return maps.isEmpty ? null : Word.fromMap(maps.first);
  }

  Future<Word?> getWordByText(String wordText) async {
    final db = await database;
    final maps = await db.query('words', where: 'LOWER(word) = LOWER(?)', whereArgs: [wordText.trim()]);
    return maps.isEmpty ? null : Word.fromMap(maps.first);
  }

  Future<void> updateWord(Word word) async {
    final db = await database;
    await db.update('words', word.toMap(), where: 'id = ?', whereArgs: [word.id]);
  }

  Future<void> toggleFavorite(int wordId) async {
    final db = await database;
    final word = await getWordById(wordId);
    if (word == null) return;

    final newFavorite = word.isFavorite ? 0 : 1;
    await db.update('words', {'is_favorite': newFavorite}, where: 'id = ?', whereArgs: [wordId]);

    final favBookId = await _getFavoritesBookId(db);
    if (favBookId == null) return;

    if (newFavorite == 1) {
      try {
        await db.insert('word_book_words', {
          'word_id': wordId, 'word_book_id': favBookId,
          'added_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    } else {
      await db.delete('word_book_words', where: 'word_id = ? AND word_book_id = ?', whereArgs: [wordId, favBookId]);
    }
  }

  Future<void> deleteWord(int wordId) async {
    final db = await database;
    await db.delete('word_book_words', where: 'word_id = ?', whereArgs: [wordId]);
    await db.delete('words', where: 'id = ?', whereArgs: [wordId]);
  }

  Future<void> removeWordFromBook(int wordId, int bookId) async {
    final db = await database;
    final allBookId = await _getAllWordsBookId(db);
    if (bookId == allBookId) { await deleteWord(wordId); return; }
    await db.delete('word_book_words', where: 'word_id = ? AND word_book_id = ?', whereArgs: [wordId, bookId]);
    final remaining = await db.rawQuery('SELECT COUNT(*) as cnt FROM word_book_words WHERE word_id = ?', [wordId]);
    if ((remaining.first['cnt'] as int? ?? 0) == 0) {
      await db.delete('words', where: 'id = ?', whereArgs: [wordId]);
    }
  }

  Future<int> getWordCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM words');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> getFavoriteCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM words WHERE is_favorite = 1');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<bool> isWordInBook(int wordId, int bookId) async {
    final db = await database;
    final result = await db.query('word_book_words', where: 'word_id = ? AND word_book_id = ?', whereArgs: [wordId, bookId]);
    return result.isNotEmpty;
  }

  // ==================== WordBook Operations ====================

  Future<int> insertWordBook(WordBook book) async {
    final db = await database;
    return await db.insert('word_books', book.toMap());
  }

  Future<List<WordBook>> getAllWordBooks() async {
    final db = await database;
    final maps = await db.query('word_books', orderBy: 'is_default DESC, created_at ASC');
    return maps.map((map) => WordBook.fromMap(map)).toList();
  }

  Future<WordBook?> getWordBookById(int id) async {
    final db = await database;
    final maps = await db.query('word_books', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return WordBook.fromMap(maps.first);
  }

  Future<WordBook?> getWordBookByName(String name) async {
    final db = await database;
    final maps = await db.query('word_books', where: 'name = ?', whereArgs: [name]);
    if (maps.isEmpty) return null;
    return WordBook.fromMap(maps.first);
  }

  Future<int?> getAllWordsBookId() async {
    final db = await database;
    return _getAllWordsBookId(db);
  }

  Future<int?> getFavoritesBookId() async {
    final db = await database;
    return _getFavoritesBookId(db);
  }

  Future<void> updateWordBook(WordBook book) async {
    final db = await database;
    await db.update('word_books', book.toMap(), where: 'id = ?', whereArgs: [book.id]);
  }

  Future<void> deleteWordBook(int bookId) async {
    final db = await database;
    final book = await getWordBookById(bookId);
    if (book == null || book.isDefault) return;

    final wordsInBook = await getWordsInBook(bookId);
    await db.delete('word_book_words', where: 'word_book_id = ?', whereArgs: [bookId]);

    for (final word in wordsInBook) {
      final remaining = await db.rawQuery('SELECT COUNT(*) as cnt FROM word_book_words WHERE word_id = ?', [word.id]);
      if ((remaining.first['cnt'] as int? ?? 0) == 0) {
        await db.delete('words', where: 'id = ?', whereArgs: [word.id]);
      }
    }
    await db.delete('word_books', where: 'id = ?', whereArgs: [bookId]);
  }

  Future<int> getWordCountInBook(int bookId) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM word_book_words WHERE word_book_id = ?', [bookId]);
    return (result.first['count'] as int?) ?? 0;
  }

  // ==================== Study Session Operations ====================

  Future<void> upsertStudySession(StudySession session) async {
    final db = await database;
    final existing = await db.query('study_sessions', where: 'date = ?', whereArgs: [session.date]);
    if (existing.isEmpty) {
      await db.insert('study_sessions', session.toMap());
    } else {
      final old = StudySession.fromMap(existing.first);
      final updated = StudySession(id: old.id, date: session.date,
        durationSeconds: old.durationSeconds + session.durationSeconds,
        wordsStudied: old.wordsStudied + session.wordsStudied,
        correctAnswers: old.correctAnswers + session.correctAnswers,
        totalQuestions: old.totalQuestions + session.totalQuestions,
        wordsMastered: old.wordsMastered + session.wordsMastered,
        wordsNotMastered: old.wordsNotMastered + session.wordsNotMastered);
      await db.update('study_sessions', updated.toMap(), where: 'id = ?', whereArgs: [old.id]);
    }
  }

  Future<StudySession?> getTodaySession() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final maps = await db.query('study_sessions', where: 'date = ?', whereArgs: [today]);
    return maps.isEmpty ? null : StudySession.fromMap(maps.first);
  }

  Future<List<StudySession>> getSessionsInRange(DateTime start, DateTime end) async {
    final db = await database;
    final startStr = start.toIso8601String().substring(0, 10);
    final endStr = end.toIso8601String().substring(0, 10);
    final maps = await db.query('study_sessions', where: 'date >= ? AND date <= ?', whereArgs: [startStr, endStr], orderBy: 'date ASC');
    return maps.map((map) => StudySession.fromMap(map)).toList();
  }

  Future<int> getTotalStudyDuration() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COALESCE(SUM(duration_seconds), 0) as total FROM study_sessions');
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getTotalQuestions() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COALESCE(SUM(total_questions), 0) as total FROM study_sessions');
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getTotalCorrectAnswers() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COALESCE(SUM(correct_answers), 0) as total FROM study_sessions');
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getTotalWordsMastered() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as total FROM words WHERE is_mastered = 1');
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getTotalWordsNotMastered() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as total FROM words WHERE is_mastered = 0');
    return (result.first['total'] as int?) ?? 0;
  }

  Future<void> updateWordMastery(int wordId, bool mastered) async {
    final db = await database;
    await db.update('words', {'is_mastered': mastered ? 1 : 0}, where: 'id = ?', whereArgs: [wordId]);
  }

  // ==================== LLM Config Operations ====================

  Future<int> insertLLMConfig(LLMConfig config) async {
    final db = await database;
    if (config.isActive) await db.update('llm_configs', {'is_active': 0});
    return await db.insert('llm_configs', config.toMap());
  }

  Future<List<LLMConfig>> getAllLLMConfigs() async {
    final db = await database;
    final maps = await db.query('llm_configs', orderBy: 'id ASC');
    return maps.map((map) => LLMConfig.fromMap(map)).toList();
  }

  Future<LLMConfig?> getActiveLLMConfig() async {
    final db = await database;
    final maps = await db.query('llm_configs', where: 'is_active = 1', limit: 1);
    return maps.isEmpty ? null : LLMConfig.fromMap(maps.first);
  }

  Future<void> updateLLMConfig(LLMConfig config) async {
    final db = await database;
    if (config.isActive) await db.update('llm_configs', {'is_active': 0});
    await db.update('llm_configs', config.toMap(), where: 'id = ?', whereArgs: [config.id]);
  }

  Future<void> setActiveLLMConfig(int id) async {
    final db = await database;
    await db.update('llm_configs', {'is_active': 0});
    await db.update('llm_configs', {'is_active': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteLLMConfig(int id) async {
    final db = await database;
    await db.delete('llm_configs', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Utility ====================

  String _getSortOrder(SortMode sortMode, {String tablePrefix = ''}) {
    switch (sortMode) {
      case SortMode.alphabeticalAsc: return '${tablePrefix}word ASC';
      case SortMode.alphabeticalDesc: return '${tablePrefix}word DESC';
      case SortMode.importTimeNewest: return '${tablePrefix}import_time DESC';
      case SortMode.importTimeOldest: return '${tablePrefix}import_time ASC';
    }
  }

  Future<void> addWordToBook(int wordId, int bookId) async {
    final db = await database;
    try {
      await db.insert('word_book_words', {'word_id': wordId, 'word_book_id': bookId, 'added_at': DateTime.now().toIso8601String()});
    } catch (_) {}
  }
}
