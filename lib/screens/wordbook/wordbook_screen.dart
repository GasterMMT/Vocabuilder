import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/word_book.dart';
import '../../providers/word_book_provider.dart';
import '../../providers/word_provider.dart';
import '../../providers/study_provider.dart';
import '../../services/export_service.dart';
import '../../utils/constants.dart';
import '../../utils/l10n.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/confirm_dialog.dart';
import 'word_list_screen.dart';
import 'import_wordbook_screen.dart';

class WordbookScreen extends StatefulWidget {
  const WordbookScreen({super.key});

  @override
  State<WordbookScreen> createState() => _WordbookScreenState();
}

class _WordbookScreenState extends State<WordbookScreen> {
  bool _isSelectionMode = false;
  final Set<int> _selectedBooks = {};
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WordBookProvider>().loadWordBooks();
    });
  }

  void _enterSelectionMode() {
    setState(() { _isSelectionMode = true; _selectedBooks.clear(); });
  }

  void _exitSelectionMode() {
    setState(() { _isSelectionMode = false; _selectedBooks.clear(); });
  }

  Future<void> _showExportDialog() async {
    final books = context.read<WordBookProvider>().wordBooks;
    if (books.isEmpty) return;

    final bookId = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('导出单词本', 'Export Book')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: books.map((book) => ListTile(
              leading: Icon(book.isDefault ? Icons.book : Icons.bookmark, color: AppConstants.primaryColor),
              title: Text(context.tBookName(book.name)),
              onTap: () => Navigator.pop(ctx, book.id),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            )).toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('取消', 'Cancel')))],
      ),
    );

    if (bookId != null && mounted) {
      final book = books.firstWhere((b) => b.id == bookId);
      final nameController = TextEditingController(text: context.tBookName(book.name).replaceAll(' ', '_'));
      final fileName = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(context.tr('文件名', 'File name')),
          content: TextField(controller: nameController, decoration: InputDecoration(suffixText: '.json'), autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('取消', 'Cancel'))),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, nameController.text.trim()), child: Text(context.tr('导出', 'Export'))),
          ],
        ),
      );
      if (fileName != null && fileName.isNotEmpty && mounted) {
        try {
          final path = await ExportService().exportWordBook(book, fileName);
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
  }

  Future<void> _deleteSelected() async {
    if (_selectedBooks.isEmpty) return;
    final books = context.read<WordBookProvider>().wordBooks;
    final names = _selectedBooks.map((id) => books.firstWhere((b) => b.id == id).name).join(', ');
    final confirm = await ConfirmDialog.show(
      context,
      title: context.tr('删除单词本', 'Delete word book'),
      message: context.tr('确定要删除以下单词本吗？\n$names\n\n注意：仅存于此单词本的单词将被删除。存在于"全部单词"中的单词不受影响。',
          'Delete the following books?\n$names\n\nNote: Words only in this book will be deleted. Words in "All Words" are safe.'),
      confirmLabel: context.tr('删除', 'Delete'),
      isDestructive: true,
    );
    if (confirm == true && mounted) {
      await context.read<WordBookProvider>().deleteWordBooks(_selectedBooks.toList());
      await context.read<WordProvider>().loadAllWords();
      await context.read<StudyProvider>().loadStats();
      _exitSelectionMode();
    }
  }

  Future<void> _createWordBook() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final provider = context.read<WordBookProvider>();
    final existing = await provider.getBookByName(name);
    if (existing != null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('该单词本名称已存在', 'This book name already exists'))));
      return;
    }
    await provider.createWordBook(name, description: _descController.text.trim().isEmpty ? null : _descController.text.trim());
    _nameController.clear();
    _descController.clear();
  }

  void _showCreateBookDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('新建单词本', 'New Word Book')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _nameController, decoration: InputDecoration(labelText: context.tr('单词本名称', 'Book name'), hintText: context.tr('输入名称', 'Enter name')), autofocus: true),
          const SizedBox(height: 12),
          TextField(controller: _descController, decoration: InputDecoration(labelText: context.tr('描述 (可选)', 'Description (optional)'), hintText: context.tr('输入描述', 'Enter description'))),
        ]),
        actions: [
          TextButton(onPressed: () { _nameController.clear(); _descController.clear(); Navigator.pop(ctx); }, child: Text(context.tr('取消', 'Cancel'))),
          ElevatedButton(onPressed: () { Navigator.pop(ctx); _createWordBook(); }, child: Text(context.tr('创建', 'Create'))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = context.watch<WordBookProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? context.t('已选 ${_selectedBooks.length} 项', '${_selectedBooks.length} selected') : context.t('单词本', 'Word Books')),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(icon: const Icon(Icons.delete), onPressed: _selectedBooks.isNotEmpty ? _deleteSelected : null),
            IconButton(icon: const Icon(Icons.close), onPressed: _exitSelectionMode),
          ] else ...[
            IconButton(icon: const Icon(Icons.ios_share), onPressed: _showExportDialog, tooltip: context.t('导出', 'Export')),
            IconButton(icon: const Icon(Icons.add), onPressed: () => _showCreateBookDialog()),
          ],
        ],
      ),
      body: bookProvider.wordBooks.isEmpty
          ? EmptyState(icon: Icons.book_outlined, title: context.t('还没有单词本', 'No word books'), subtitle: context.t('创建单词本来整理你的词汇', 'Create word books to organize vocabulary'), actionLabel: context.t('创建单词本', 'Create Book'), onAction: () => _showCreateBookDialog())
          : RefreshIndicator(
              onRefresh: () => bookProvider.loadWordBooks(),
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: bookProvider.wordBooks.length,
                itemBuilder: (context, index) {
                  final book = bookProvider.wordBooks[index];
                  return _BookListItem(
                    book: book,
                    isSelectionMode: _isSelectionMode,
                    isSelected: _selectedBooks.contains(book.id),
                    onTap: () {
                      if (_isSelectionMode) {
                        setState(() {
                          if (_selectedBooks.contains(book.id)) {
                            _selectedBooks.remove(book.id);
                          } else {
                            if (!book.isDefault) _selectedBooks.add(book.id!);
                          }
                        });
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => WordListScreen(book: book)));
                      }
                    },
                    onLongPress: () {
                      if (!_isSelectionMode && !book.isDefault) {
                        _enterSelectionMode();
                        setState(() => _selectedBooks.add(book.id!));
                      }
                    },
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportWordbookScreen())),
        icon: const Icon(Icons.file_download),
        label: Text(context.t('导入单词本', 'Import Book')),
      ),
    );
  }
}

class _BookListItem extends StatelessWidget {
  final WordBook book;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _BookListItem({required this.book, required this.isSelectionMode, required this.isSelected, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = book.isDefault
        ? (book.name == AppConstants.allWordsBookName ? AppConstants.primaryColor : AppConstants.errorColor)
        : AppConstants.secondaryColor;

    return AnimatedContainer(
      duration: AppConstants.mediumAnimation,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? AppConstants.primaryColor : Colors.grey.withAlpha(51), width: isSelected ? 2 : 1),
      ),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              if (isSelectionMode && !book.isDefault)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AnimatedContainer(
                    duration: AppConstants.shortAnimation,
                    width: 24, height: 24,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? AppConstants.primaryColor : Colors.transparent, border: Border.all(color: isSelected ? AppConstants.primaryColor : Colors.grey, width: 2)),
                    child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                  ),
                ),
              Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)),
                child: Icon(
                  book.isDefault ? (book.name == AppConstants.allWordsBookName ? Icons.collections_bookmark : Icons.favorite) : Icons.bookmark,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(context.tBookName(book.name), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  if (book.description != null && book.description!.isNotEmpty)
                    Text(book.description!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(150)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              if (book.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                  child: Text(context.t('默认', 'Default'), style: TextStyle(color: color, fontSize: 12)),
                ),
              if (!isSelectionMode)
                const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.chevron_right, color: Colors.grey, size: 20)),
            ]),
          ),
        ),
      ),
    );
  }
}
