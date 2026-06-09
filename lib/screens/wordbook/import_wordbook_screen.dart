import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/word.dart';
import '../../models/word_book.dart';
import '../../providers/word_book_provider.dart';
import '../../providers/word_provider.dart';
import '../../services/database_service.dart';
import '../../services/import_service.dart';
import '../../utils/constants.dart';
import '../../utils/l10n.dart';

class ImportWordbookScreen extends StatefulWidget {
  const ImportWordbookScreen({super.key});

  @override
  State<ImportWordbookScreen> createState() => _ImportWordbookScreenState();
}

class _ImportWordbookScreenState extends State<ImportWordbookScreen> {
  final ImportService _importService = ImportService();
  bool _isImporting = false;
  String? _error;

  Future<void> _pickAndImport() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null || result.files.single.path == null) return;

      setState(() { _isImporting = true; _error = null; });

      final file = File(result.files.single.path!);
      final parsed = await _importService.parseImportFile(file);
      final bookData = parsed.book;
      final words = parsed.words;

      if (!mounted) return;

      // Resolve book name conflict
      final bookProvider = context.read<WordBookProvider>();
      final existingBook = await bookProvider.getBookByName(bookData.name);

      int? targetBookId;
      bool shouldImportWords = true;

      if (existingBook != null && !existingBook.isDefault) {
        final action = await _showBookNameConflictDialog(existingBook.name);
        if (action == null || action == 'cancel') {
          setState(() => _isImporting = false); return;
        }
        switch (action) {
          case 'overwrite':
            // Clear old words from this book, keep the book
            targetBookId = existingBook.id;
            final oldWords = await DatabaseService.instance.getWordsInBook(targetBookId!);
            if (oldWords.isNotEmpty) {
              await context.read<WordProvider>().removeWordsFromBook(
                  oldWords.map((w) => w.id!).toList(), targetBookId!);
            }
            break;
          case 'rename':
            final newName = await _showRenameDialog(bookData.name);
            if (newName == null) { setState(() => _isImporting = false); return; }
            targetBookId = await bookProvider.createWordBook(newName, description: bookData.description);
            break;
          case 'keep':
            // Add words to existing book without clearing
            targetBookId = existingBook.id;
            break;
        }
      } else if (existingBook != null && existingBook.isDefault) {
        // Default book — just add words to it
        targetBookId = existingBook.id;
      } else {
        // No conflict — create new book
        targetBookId = await bookProvider.createWordBook(bookData.name, description: bookData.description);
      }

      if (targetBookId == null || !mounted) {
        setState(() => _isImporting = false); return;
      }

      // Build book IDs: target book + 全部单词
      final allBook = bookProvider.allWordsBook;
      final List<int> bookIds = [targetBookId];
      if (allBook != null && allBook.id != targetBookId) {
        bookIds.add(allBook.id!);
      }

      final wordProvider = context.read<WordProvider>();
      int imported = 0;
      int skipped = 0;

      for (final word in words) {
        if (!mounted) return;
        final existing = await wordProvider.checkDuplicate(word.word);
        if (existing != null) {
          // Check if fully identical
          if (existing.translation == word.translation &&
              existing.partOfSpeech == word.partOfSpeech &&
              existing.example == word.example &&
              existing.notes == word.notes) {
            // Identical — just ensure it's in the target books
            for (final bid in bookIds) {
              await wordProvider.addWordToBook(existing.id!, bid);
            }
            skipped++;
            continue;
          }
          // Different — ask user
          final action = await _showWordConflictDialog(existing, word);
          if (action == null || action == 'cancel') continue;
          if (action == 'overwrite') {
            final updated = existing.copyWith(
              translation: word.translation,
              partOfSpeech: word.partOfSpeech,
              example: word.example,
              notes: word.notes,
            );
            await wordProvider.updateWord(updated);
            for (final bid in bookIds) {
              await wordProvider.addWordToBook(existing.id!, bid);
            }
            imported++;
          } else {
            // keep_both — add as new
            await wordProvider.addWord(word, wordBookIds: bookIds);
            imported++;
          }
        } else {
          await wordProvider.addWord(word, wordBookIds: bookIds);
          imported++;
        }
      }

      if (mounted) {
        await bookProvider.loadWordBooks();
        await wordProvider.loadAllWords();
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('成功导入 $imported 个单词${skipped > 0 ? '，跳过 $skipped 个重复' : ''}',
                'Imported $imported words${skipped > 0 ? ', skipped $skipped duplicates' : ''}')),
            backgroundColor: AppConstants.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() { _error = context.tr('导入失败: $e', 'Import failed: $e'); _isImporting = false; });
    }
  }

  Future<String?> _showBookNameConflictDialog(String bookName) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('单词本名称冲突', 'Book name conflict')),
        content: Text(context.tr('已存在名为"$bookName"的单词本。请选择处理方式：', 'A book named "$bookName" already exists. Choose:')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'keep'), child: Text(context.tr('保留两者', 'Keep both'))),
          TextButton(onPressed: () => Navigator.pop(ctx, 'rename'), child: Text(context.tr('重命名', 'Rename'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, 'overwrite'), child: Text(context.tr('覆盖', 'Overwrite'))),
          OutlinedButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: Text(context.tr('取消', 'Cancel'))),
        ],
      ),
    );
  }

  Future<String?> _showRenameDialog(String originalName) async {
    final controller = TextEditingController(text: '${originalName}_导入');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('重命名单词本', 'Rename book')),
        content: TextField(controller: controller, decoration: InputDecoration(labelText: context.tr('新名称', 'New name')), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('取消', 'Cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text(context.tr('确认', 'Confirm'))),
        ],
      ),
    );
  }

  Future<String?> _showWordConflictDialog(Word existing, Word imported) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('重复单词', 'Duplicate word')),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr('单词"${imported.word}"已存在。', 'Word "${imported.word}" already exists.')),
            const SizedBox(height: 12),
            Text(context.tr('现有', 'Existing'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('${existing.translation} · ${existing.partOfSpeech}'),
            if (existing.example != null && existing.example!.isNotEmpty)
              Text(existing.example!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const Divider(height: 24),
            Text(context.tr('新导入', 'Importing'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('${imported.translation} · ${imported.partOfSpeech}'),
            if (imported.example != null && imported.example!.isNotEmpty)
              Text(imported.example!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'keep_both'), child: Text(context.tr('保留两者', 'Keep both'))),
          OutlinedButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: Text(context.tr('跳过', 'Skip'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, 'overwrite'), child: Text(context.tr('覆盖', 'Overwrite'))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('导入单词本', 'Import Book'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.file_present, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            Text(context.t('导入单词本文件', 'Import word book file'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(context.t('支持从 Vocabuilder 导出的 .json 文件导入单词本', 'Import .json files exported from Vocabuilder'), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            if (_isImporting)
              Column(children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(context.t('正在导入...', 'Importing...'))])
            else
              ElevatedButton.icon(
                onPressed: _pickAndImport,
                icon: const Icon(Icons.file_open),
                label: Text(context.t('选择文件', 'Select File')),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
              ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppConstants.errorColor.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [const Icon(Icons.error_outline, color: AppConstants.errorColor), const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: AppConstants.errorColor)))]),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
