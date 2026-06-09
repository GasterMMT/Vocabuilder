import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_book.dart';
import 'database_service.dart';

class ExportService {
  final DatabaseService _db = DatabaseService.instance;

  Future<String> getExportDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('export_path');
    if (saved != null && saved.isNotEmpty) return saved;

    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/exports/';
  }

  Future<String> exportWordBook(WordBook book, String fileName) async {
    final words = await _db.getWordsInBook(book.id!);
    final exportData = {
      'vocabuilder_version': '1.0.0',
      'export_date': DateTime.now().toIso8601String(),
      'word_book': book.toJson(),
      'words': words.map((w) => w.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
    final exportDirPath = await getExportDirectory();
    final exportDir = Directory(exportDirPath);
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final filePath = '$exportDirPath/$fileName.json';
    final file = File(filePath);
    await file.writeAsString(jsonString, flush: true);

    return filePath;
  }
}
