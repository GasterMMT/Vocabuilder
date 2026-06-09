import 'dart:convert';
import 'dart:io';
import '../models/word.dart';
import '../models/word_book.dart';
import 'database_service.dart';

class ImportResult {
  final WordBook wordBook;
  final List<WordConflict> conflicts;
  final List<Word> newWords;

  ImportResult({
    required this.wordBook,
    required this.conflicts,
    required this.newWords,
  });

  bool get hasConflicts => conflicts.isNotEmpty;
}

class WordConflict {
  final Word existingWord;
  final Word importedWord;
  final bool? useImported; // null = unresolved, true = use imported, false = keep existing

  WordConflict({
    required this.existingWord,
    required this.importedWord,
    this.useImported,
  });

  bool get hasDifferences =>
      existingWord.translation != importedWord.translation ||
      existingWord.partOfSpeech != importedWord.partOfSpeech ||
      existingWord.example != importedWord.example ||
      existingWord.notes != importedWord.notes;

  Map<String, Map<String, String?>> get differences {
    final diffs = <String, Map<String, String?>>{};
    if (existingWord.translation != importedWord.translation) {
      diffs['翻译'] = {
        'existing': existingWord.translation,
        'imported': importedWord.translation,
      };
    }
    if (existingWord.partOfSpeech != importedWord.partOfSpeech) {
      diffs['词性'] = {
        'existing': existingWord.partOfSpeech,
        'imported': importedWord.partOfSpeech,
      };
    }
    if (existingWord.example != importedWord.example) {
      diffs['例句'] = {
        'existing': existingWord.example,
        'imported': importedWord.example,
      };
    }
    if (existingWord.notes != importedWord.notes) {
      diffs['笔记'] = {
        'existing': existingWord.notes,
        'imported': importedWord.notes,
      };
    }
    return diffs;
  }
}

class ImportService {
  final DatabaseService _db = DatabaseService.instance;

  /// Parse a JSON file into a word book with its words
  Future<({WordBook book, List<Word> words})> parseImportFile(File file) async {
    final content = await file.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;

    final bookData = data['word_book'] as Map<String, dynamic>?;
    final wordsData = data['words'] as List<dynamic>?;

    if (wordsData == null || wordsData.isEmpty) {
      throw Exception('导入文件中没有找到单词数据');
    }

    final book = WordBook(
      name: bookData?['name'] as String? ?? '导入的单词本',
      description: bookData?['description'] as String?,
    );

    final words = wordsData
        .map((w) => Word.fromJson(w as Map<String, dynamic>))
        .toList();

    return (book: book, words: words);
  }

  /// Check for conflicts between imported words and local words
  Future<ImportResult> checkConflicts(
      WordBook importedBook, List<Word> importedWords) async {
    final conflicts = <WordConflict>[];
    final newWords = <Word>[];

    for (final importedWord in importedWords) {
      final existingWord = await _db.getWordByText(importedWord.word);

      if (existingWord != null) {
        final conflict = WordConflict(
          existingWord: existingWord,
          importedWord: importedWord,
        );
        if (conflict.hasDifferences) {
          conflicts.add(conflict);
        }
        // If no differences, word is already in database, skip it
      } else {
        newWords.add(importedWord);
      }
    }

    return ImportResult(
      wordBook: importedBook,
      conflicts: conflicts,
      newWords: newWords,
    );
  }

  /// Import words into a book, resolving conflicts
  Future<void> importWords(
    WordBook book,
    List<Word> words,
    Map<int, bool> conflictResolutions, // word index -> useImported
  ) async {
    // Check if book name exists
    final existingBook = await _db.getWordBookByName(book.name);
    int bookId;

    if (existingBook != null) {
      bookId = existingBook.id!;
    } else {
      bookId = await _db.insertWordBook(book);
    }

    // Process each word
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final existingWord = await _db.getWordByText(word.word);

      if (existingWord != null) {
        final resolution = conflictResolutions[i];
        if (resolution == true) {
          // Use imported version - update existing word
          final updated = existingWord.copyWith(
            translation: word.translation,
            partOfSpeech: word.partOfSpeech,
            example: word.example,
            notes: word.notes,
          );
          await _db.updateWord(updated);
        }
        // Ensure word is in this book
        await _db.addWordToBook(existingWord.id!, bookId);
      } else {
        // New word - insert it
        await _db.insertWord(word, wordBookIds: [bookId]);
      }
    }
  }

  /// Quick import without conflict checking (for simple cases)
  Future<void> quickImport(WordBook book, List<Word> words) async {
    final result = await checkConflicts(book, words);

    if (result.hasConflicts) {
      throw Exception('存在冲突的单词，请先解决冲突');
    }

    await importWords(book, words, {});
  }
}
