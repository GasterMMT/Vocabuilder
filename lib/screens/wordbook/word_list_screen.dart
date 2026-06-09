import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/word.dart';
import '../../models/word_book.dart';
import '../../providers/word_provider.dart';
import '../../providers/word_book_provider.dart';
import '../../providers/study_provider.dart';
import '../../utils/constants.dart';
import '../../utils/l10n.dart';
import '../../widgets/word_card.dart';
import '../../widgets/sort_selector.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/confirm_dialog.dart';
import '../../services/export_service.dart';

class WordListScreen extends StatefulWidget {
  final WordBook book;
  const WordListScreen({super.key, required this.book});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  bool _isSelectionMode = false;
  final Set<int> _selectedWords = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WordProvider>().loadWordsInBook(widget.book.id!);
    });
  }

  void _exitSelectionMode() {
    setState(() { _isSelectionMode = false; _selectedWords.clear(); });
  }

  Future<void> _deleteSelected() async {
    if (_selectedWords.isEmpty) return;
    final len = _selectedWords.length;
    final confirm = await ConfirmDialog.show(context,
      title: context.tr('删除单词', 'Delete words'),
      message: context.tr('确定要删除 $len 个单词吗？将从所有单词本中移除！', 'Delete $len words? Will be removed from ALL word books!'),
      confirmLabel: context.tr('删除', 'Delete'), isDestructive: true,
    );
    if (confirm == true && mounted) {
      await context.read<WordProvider>().deleteWords(_selectedWords.toList());
      await context.read<StudyProvider>().loadStats();
      _exitSelectionMode();
    }
  }

  Future<void> _removeFromBook() async {
    if (_selectedWords.isEmpty) return;
    await context.read<WordProvider>().removeWordsFromBook(_selectedWords.toList(), widget.book.id!);
    _exitSelectionMode();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('已从单词本中移除', 'Removed from book'))));
  }

  Future<void> _toggleFavoriteSelected() async {
    if (_selectedWords.isEmpty) return;
    await context.read<WordProvider>().batchToggleFavorite(_selectedWords.toList());
    _exitSelectionMode();
  }

  Future<void> _addToBook() async {
    if (_selectedWords.isEmpty) return;
    final bookProvider = context.read<WordBookProvider>();
    final selectableBooks = bookProvider.wordBooks.where((b) => b.id != widget.book.id).toList();
    if (selectableBooks.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('没有其他单词本', 'No other word books'))));
      return;
    }

    final targetId = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('添加到单词本', 'Add to book')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: selectableBooks.map((book) => ListTile(
              title: Text(context.tBookName(book.name)),
              onTap: () => Navigator.pop(ctx, book.id),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            )).toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('取消', 'Cancel')))],
      ),
    );

    if (targetId != null && mounted) {
      final wordProvider = context.read<WordProvider>();
      final favBook = context.read<WordBookProvider>().favoritesBook;
      final isFavTarget = favBook != null && targetId == favBook.id;
      for (final wordId in _selectedWords) {
        await wordProvider.addWordToBook(wordId, targetId);
        if (isFavTarget) {
          // Only toggle if not already favorited
          final word = wordProvider.allWords.firstWhere((w) => w.id == wordId);
          if (!word.isFavorite) {
            await wordProvider.toggleFavorite(wordId);
          }
        }
      }
      _exitSelectionMode();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('已添加 ${_selectedWords.length} 个单词', 'Added ${_selectedWords.length} words')), backgroundColor: AppConstants.successColor));
    }
  }

  Future<void> _exportBook() async {
    final nameController = TextEditingController(text: context.tBookName(widget.book.name).replaceAll(' ', '_'));
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('导出单词本', 'Export Book')),
        content: TextField(controller: nameController, decoration: InputDecoration(labelText: context.tr('文件名', 'File name'), suffixText: '.json'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('取消', 'Cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, nameController.text.trim()), child: Text(context.tr('导出', 'Export'))),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      try {
        final exportService = ExportService();
        final path = await exportService.exportWordBook(widget.book, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('已导出到: $path', 'Exported to: $path')), backgroundColor: AppConstants.successColor, duration: const Duration(seconds: 4)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('导出失败: $e', 'Export failed: $e')), backgroundColor: AppConstants.errorColor));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wordProvider = context.watch<WordProvider>();
    final words = wordProvider.wordsInCurrentBook;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? context.t('已选 ${_selectedWords.length} 项', '${_selectedWords.length} selected') : context.tBookName(widget.book.name)),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: Icon(_selectedWords.length == words.length ? Icons.deselect : Icons.select_all),
              onPressed: () {
                setState(() {
                  if (_selectedWords.length == words.length) {
                    _selectedWords.clear();
                  } else {
                    _selectedWords.addAll(words.map((w) => w.id!));
                  }
                });
              },
              tooltip: _selectedWords.length == words.length ? context.t('全不选', 'Deselect all') : context.t('全选', 'Select all'),
            ),
            IconButton(icon: const Icon(Icons.playlist_add), onPressed: _selectedWords.isNotEmpty ? _addToBook : null, tooltip: context.t('添加到单词本', 'Add to book')),
            if (!widget.book.isDefault)
              IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: _selectedWords.isNotEmpty ? _removeFromBook : null),
            IconButton(icon: const Icon(Icons.delete), onPressed: _selectedWords.isNotEmpty ? _deleteSelected : null),
            IconButton(icon: const Icon(Icons.close), onPressed: _exitSelectionMode),
          ] else ...[
            SortSelector(currentMode: wordProvider.currentSortMode, onChanged: (mode) => wordProvider.setSortMode(mode)),
            IconButton(icon: const Icon(Icons.file_upload), onPressed: _exportBook),
          ],
        ],
      ),
      body: words.isEmpty
          ? EmptyState(icon: Icons.menu_book_outlined, title: context.t('单词本为空', 'Book is empty'), subtitle: context.t('导入单词到这个单词本', 'Import words into this book'))
          : RefreshIndicator(
              onRefresh: () => wordProvider.loadWordsInBook(widget.book.id!),
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: words.length,
                itemBuilder: (context, index) {
                  final word = words[index];
                  return WordCard(
                    word: word,
                    isSelectionMode: _isSelectionMode,
                    isSelected: _selectedWords.contains(word.id),
                    onTap: () {
                      if (_isSelectionMode) {
                        setState(() {
                          if (_selectedWords.contains(word.id)) {
                            _selectedWords.remove(word.id);
                          } else {
                            _selectedWords.add(word.id!);
                          }
                          if (_selectedWords.isEmpty) _isSelectionMode = false;
                        });
                      } else {
                        _showWordDetail(word);
                      }
                    },
                    onFavoriteToggle: _isSelectionMode ? null : () => wordProvider.toggleFavorite(word.id!),
                    onLongPress: () {
                      setState(() {
                        _isSelectionMode = true;
                        if (_selectedWords.contains(word.id)) {
                          _selectedWords.remove(word.id);
                        } else {
                          _selectedWords.add(word.id!);
                        }
                      });
                    },
                  );
                },
              ),
            ),
    );
  }

  void _showWordDetail(Word word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final wp = context.read<WordProvider>();
        return StatefulBuilder(
          builder: (context, setModalState) => DraggableScrollableSheet(
            initialChildSize: 0.45, minChildSize: 0.3, maxChildSize: 0.8, expand: false,
            builder: (context, scrollController) => SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: Text(word.word, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold))),
                  GestureDetector(
                    onTap: () { wp.toggleFavorite(word.id!); setModalState(() {}); },
                    child: Icon(word.isFavorite ? Icons.favorite : Icons.favorite_border, color: word.isFavorite ? AppConstants.errorColor : Colors.grey, size: 28),
                  ),
                ]),
                const SizedBox(height: 12),
                Text(word.translation, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppConstants.primaryColor, fontWeight: FontWeight.w600)),
                if (word.partOfSpeech.isNotEmpty) ...[const SizedBox(height: 12), Chip(label: Text(word.partOfSpeech))],
                if (word.example != null && word.example!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(context.t('例句', 'Example'), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppConstants.primaryColor.withAlpha(13), borderRadius: BorderRadius.circular(12)),
                    child: Text(word.example!, style: const TextStyle(fontStyle: FontStyle.italic))),
                ],
                if (word.notes != null && word.notes!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(context.t('笔记', 'Notes'), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 8), Text(word.notes!),
                ],
                const SizedBox(height: 12),
                Text(context.t('导入: ${word.importTime.year}-${word.importTime.month.toString().padLeft(2,'0')}-${word.importTime.day.toString().padLeft(2,'0')}',
                    'Imported: ${word.importTime.year}-${word.importTime.month.toString().padLeft(2,'0')}-${word.importTime.day.toString().padLeft(2,'0')}'),
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        );
      },
    );
  }
}
