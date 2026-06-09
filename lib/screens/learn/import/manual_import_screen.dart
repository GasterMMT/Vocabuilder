import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/word.dart';
import '../../../providers/word_provider.dart';
import '../../../providers/word_book_provider.dart';
import '../../../utils/constants.dart';
import '../../../utils/l10n.dart';

class ManualImportScreen extends StatefulWidget {
  const ManualImportScreen({super.key});

  @override
  State<ManualImportScreen> createState() => _ManualImportScreenState();
}

class _ManualImportScreenState extends State<ManualImportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _wordController = TextEditingController();
  final _wordFocusNode = FocusNode();
  final _translationController = TextEditingController();
  final _posController = TextEditingController();
  final _exampleController = TextEditingController();
  final _notesController = TextEditingController();

  List<int> _selectedBookIds = [];
  bool _isSubmitting = false;
  String? _newBookName;
  bool _showNewBookField = false;
  final _newBookController = TextEditingController();

  @override
  void dispose() {
    _wordController.dispose(); _wordFocusNode.dispose();
    _translationController.dispose(); _posController.dispose();
    _exampleController.dispose(); _notesController.dispose();
    _newBookController.dispose();
    super.dispose();
  }

  bool get _autoFavorite {
    final favBook = context.read<WordBookProvider>().favoritesBook;
    return favBook != null && _selectedBookIds.contains(favBook.id);
  }

  Future<void> _doImport() async {
    if (!_formKey.currentState!.validate()) return;
    final wordProvider = context.read<WordProvider>();
    final wordText = _wordController.text.trim();

    // Check duplicate
    final existing = await wordProvider.checkDuplicate(wordText);
    if (existing != null && mounted) {
      final newTrans = _translationController.text.trim();
      final newPos = _posController.text.trim();
      final newExample = _exampleController.text.trim().isEmpty ? null : _exampleController.text.trim();
      final newNotes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

      // If fully identical, skip silently
      if (existing.translation == newTrans &&
          existing.partOfSpeech == newPos &&
          existing.example == newExample &&
          existing.notes == newNotes) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('单词"$wordText"已存在，内容相同，已跳过', '"$wordText" already exists with same content, skipped')), backgroundColor: Colors.grey));
        _clearForm();
        return;
      }

      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(context.tr('重复单词', 'Duplicate word')),
          content: Text(context.tr('单词"$wordText"已存在。\n\n现有: ${existing.translation}\n新: ${_translationController.text.trim()}\n\n是否覆盖？',
              'Word "$wordText" already exists.\n\nExisting: ${existing.translation}\nNew: ${_translationController.text.trim()}\n\nOverwrite?')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, 'keep_both'), child: Text(context.tr('保留两者', 'Keep both'))),
            OutlinedButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: Text(context.tr('取消', 'Cancel'))),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, 'overwrite'), child: Text(context.tr('覆盖', 'Overwrite'))),
          ],
        ),
      );
      if (action == null || action == 'cancel') return;
      if (action == 'overwrite') {
        final updated = existing.copyWith(
          translation: _translationController.text.trim(),
          partOfSpeech: _posController.text.trim(),
          example: _exampleController.text.trim().isEmpty ? null : _exampleController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          isFavorite: existing.isFavorite || _autoFavorite,
        );
        await wordProvider.updateWord(updated);
        for (final bookId in _selectedBookIds) {
          await wordProvider.addWordToBook(existing.id!, bookId);
        }
        // Also ensure in favorites if auto-fav
        if (_autoFavorite) {
          final favBook = context.read<WordBookProvider>().favoritesBook;
          if (favBook != null) await wordProvider.addWordToBook(existing.id!, favBook.id!);
        }
        _clearForm();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('已覆盖: $wordText', 'Overwritten: $wordText')), backgroundColor: AppConstants.successColor));
        return;
      }
    }

    // Submit new word
    setState(() => _isSubmitting = true);
    try {
      final bookProvider = context.read<WordBookProvider>();

      // Build book IDs (全部单词 is auto-added by database)
      List<int> finalBookIds = List.from(_selectedBookIds);
      if (_showNewBookField && _newBookName != null && _newBookName!.isNotEmpty) {
        final existingBook = await bookProvider.getBookByName(_newBookName!);
        if (existingBook != null) {
          if (!finalBookIds.contains(existingBook.id)) finalBookIds.add(existingBook.id!);
        } else {
          final newId = await bookProvider.createWordBook(_newBookName!);
          finalBookIds.add(newId);
        }
      }

      // Don't include 全部单词 in the list (DB adds it automatically)
      final allBook = bookProvider.allWordsBook;
      if (allBook != null) finalBookIds.remove(allBook.id);

      final word = Word(
        word: _wordController.text.trim(),
        translation: _translationController.text.trim(),
        partOfSpeech: _posController.text.trim(),
        example: _exampleController.text.trim().isEmpty ? null : _exampleController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        isFavorite: _autoFavorite,
      );

      await wordProvider.addWord(word, wordBookIds: finalBookIds);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('成功导入: ${word.word}', 'Imported: ${word.word}')), backgroundColor: AppConstants.successColor));
        _clearForm();
        _wordFocusNode.requestFocus();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('导入失败: $e', 'Import failed: $e')), backgroundColor: AppConstants.errorColor));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    _wordController.clear(); _translationController.clear(); _posController.clear();
    _exampleController.clear(); _notesController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookProvider = context.watch<WordBookProvider>();
    final selectableBooks = bookProvider.wordBooks.where((b) => b.name != AppConstants.allWordsBookName).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('手动导入单词', 'Manual Import')),
        actions: [
          TextButton.icon(
            onPressed: _isSubmitting ? null : _doImport,
            icon: const Icon(Icons.check, size: 20),
            label: Text(context.t('完成', 'Done')),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.t('必填信息', 'Required'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(controller: _wordController, focusNode: _wordFocusNode,
              decoration: InputDecoration(labelText: context.t('单词 *', 'Word *'), hintText: context.t('输入单词', 'Enter word')),
              textCapitalization: TextCapitalization.none,
              validator: (v) => (v == null || v.trim().isEmpty) ? context.tr('请输入单词', 'Please enter a word') : null,
              textInputAction: TextInputAction.next),
            const SizedBox(height: 12),
            TextFormField(controller: _translationController,
              decoration: InputDecoration(labelText: context.t('翻译/释义 *', 'Translation *'), hintText: context.t('输入中文翻译', 'Enter translation')),
              validator: (v) => (v == null || v.trim().isEmpty) ? context.tr('请输入翻译', 'Please enter a translation') : null,
              textInputAction: TextInputAction.next),
            const SizedBox(height: 12),
            TextFormField(controller: _posController,
              decoration: InputDecoration(labelText: context.t('词性 *', 'Part of Speech *'), hintText: context.t('如: 名词, 动词, 形容词...', 'e.g. noun, verb, adjective...')),
              validator: (v) => (v == null || v.trim().isEmpty) ? context.tr('请输入词性', 'Please enter part of speech') : null,
              textInputAction: TextInputAction.next),
            const SizedBox(height: 28),
            Text(context.t('选填信息', 'Optional'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(controller: _exampleController, decoration: InputDecoration(labelText: context.t('例句', 'Example'), hintText: context.t('输入例句(可选)', 'Enter example (optional)')), maxLines: 2, textInputAction: TextInputAction.next),
            const SizedBox(height: 12),
            TextFormField(controller: _notesController, decoration: InputDecoration(labelText: context.t('笔记', 'Notes'), hintText: context.t('添加个人笔记(可选)', 'Add personal notes (optional)')), maxLines: 2),
            const SizedBox(height: 28),

            if (selectableBooks.isNotEmpty) ...[
              Text(context.t('添加到其他单词本', 'Add to word books'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(context.t('默认已加入"全部单词"，选"收藏"自动标记红心', 'Auto-added to "All Words". Select "Favorites" to bookmark'), style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(120), fontSize: 12)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ...selectableBooks.map((book) {
                  final isSelected = _selectedBookIds.contains(book.id);
                  final isFav = book.name == AppConstants.favoritesBookName;
                  return FilterChip(
                    selected: isSelected,
                    label: Text(context.tBookName(book.name)),
                    selectedColor: (isFav ? AppConstants.errorColor : AppConstants.primaryColor).withAlpha(38),
                    checkmarkColor: isFav ? AppConstants.errorColor : AppConstants.primaryColor,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          if (!_selectedBookIds.contains(book.id)) _selectedBookIds.add(book.id!);
                        } else {
                          _selectedBookIds.remove(book.id);
                        }
                      });
                    },
                  );
                }),
                ActionChip(
                  avatar: Icon(_showNewBookField ? Icons.close : Icons.add, size: 18),
                  label: Text(_showNewBookField ? context.t('取消', 'Cancel') : context.t('新建单词本', 'New Book')),
                  onPressed: () {
                    setState(() {
                      _showNewBookField = !_showNewBookField;
                      if (!_showNewBookField) { _newBookName = null; _newBookController.clear(); }
                    });
                  },
                ),
              ]),
              if (_showNewBookField) ...[
                const SizedBox(height: 12),
                TextFormField(controller: _newBookController, decoration: InputDecoration(labelText: context.t('新单词本名称', 'New book name'), prefixIcon: const Icon(Icons.create_new_folder)),
                  onChanged: (v) => _newBookName = v.trim()),
              ],
            ],

            if (_autoFavorite) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppConstants.errorColor.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.favorite, color: AppConstants.errorColor, size: 18), const SizedBox(width: 8),
                  Expanded(child: Text(context.t('已选收藏单词本，导入后自动标记红心', 'Favorites book selected — auto-bookmark on import'), style: const TextStyle(color: AppConstants.errorColor, fontSize: 13))),
                ]),
              ),
            ],

            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }
}
