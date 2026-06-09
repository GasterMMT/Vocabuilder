import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../models/word.dart';
import '../../../providers/word_provider.dart';
import '../../../providers/word_book_provider.dart';
import '../../../services/ai_service.dart';
import '../../../services/database_service.dart';
import '../../../utils/constants.dart';
import '../../../utils/l10n.dart';

class AIImportScreen extends StatefulWidget {
  const AIImportScreen({super.key});

  @override
  State<AIImportScreen> createState() => _AIImportScreenState();
}

class _AIImportScreenState extends State<AIImportScreen> {
  final _textController = TextEditingController();
  List<Word> _parsedWords = [];
  Set<int> _selectedIndices = {};
  bool _isParsing = false;
  bool _isImporting = false;
  String? _error;

  List<int> _selectedBookIds = [];
  String? _newBookName;
  bool _showNewBookField = false;
  final _newBookController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    _newBookController.dispose();
    super.dispose();
  }

  bool get _autoFavorite {
    final favBook = context.read<WordBookProvider>().favoritesBook;
    return favBook != null && _selectedBookIds.contains(favBook.id);
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _parseText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = context.tr('请输入文本内容', 'Please enter text content'));
      return;
    }

    // Get active LLM config
    final db = DatabaseService.instance;
    final activeConfig = await db.getActiveLLMConfig();

    if (activeConfig == null) {
      setState(() => _error = context.tr('请先在设置中配置AI模型', 'Please configure AI model in settings first'));
      return;
    }

    setState(() {
      _isParsing = true;
      _error = null;
    });

    try {
      final aiService = AIService(activeConfig);
      final words = await aiService.parseWordsFromText(text);

      setState(() {
        _parsedWords = words;
        _selectedIndices = Set.from(words.asMap().keys);
        _isParsing = false;
      });
    } catch (e) {
      setState(() {
        _error = context.tr('AI解析失败: $e', 'AI parse failed: $e');
        _isParsing = false;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md', 'json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final ext = result.files.single.extension ?? 'txt';
        _textController.text = content;

        // Auto-parse after picking file
        await _parseTextForFile(content, ext);
      }
    } catch (e) {
      setState(() => _error = context.tr('文件读取失败: $e', 'File read failed: $e'));
    }
  }

  Future<void> _parseTextForFile(String content, String fileType) async {
    final db = DatabaseService.instance;
    final activeConfig = await db.getActiveLLMConfig();

    if (activeConfig == null) {
      setState(() => _error = context.tr('请先在设置中配置AI模型', 'Please configure AI model in settings first'));
      return;
    }

    setState(() {
      _isParsing = true;
      _error = null;
    });

    try {
      final aiService = AIService(activeConfig);
      final words = await aiService.parseWordsFromFileContent(content, fileType);

      setState(() {
        _parsedWords = words;
        _selectedIndices = Set.from(words.asMap().keys);
        _isParsing = false;
      });
    } catch (e) {
      setState(() {
        _error = context.tr('AI解析失败: $e', 'AI parse failed: $e');
        _isParsing = false;
      });
    }
  }

  Future<void> _importWords() async {
    if (_selectedIndices.isEmpty) return;

    setState(() => _isImporting = true);

    try {
      final wordProvider = context.read<WordProvider>();
      final bookProvider = context.read<WordBookProvider>();

      // Build book IDs — exclude 全部单词 (DB adds it automatically)
      List<int> finalBookIds = List.from(_selectedBookIds);
      final allBook = bookProvider.allWordsBook;
      if (allBook != null) finalBookIds.remove(allBook.id);

      if (_showNewBookField && _newBookName != null && _newBookName!.isNotEmpty) {
        final existingBook = await bookProvider.getBookByName(_newBookName!);
        if (existingBook != null) {
          if (!finalBookIds.contains(existingBook.id)) {
            finalBookIds.add(existingBook.id!);
          }
        } else {
          final newId = await bookProvider.createWordBook(_newBookName!);
          finalBookIds.add(newId);
        }
      }

      int imported = 0;
      for (final index in _selectedIndices) {
        final word = _parsedWords[index];

        // Check duplicate
        final existing = await wordProvider.checkDuplicate(word.word);
        if (existing != null && mounted) {
          // If fully identical, skip silently
          if (existing.translation == word.translation &&
              existing.partOfSpeech == word.partOfSpeech &&
              existing.example == word.example &&
              existing.notes == word.notes) {
            continue;
          }

          final action = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(context.tr('重复单词', 'Duplicate word')),
              content: Text(context.tr('单词"${word.word}"已存在。\n\n现有: ${existing.translation}\n新: ${word.translation}\n\n是否覆盖？',
                  'Word "${word.word}" already exists.\n\nExisting: ${existing.translation}\nNew: ${word.translation}\n\nOverwrite?')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, 'keep_both'), child: Text(context.tr('保留两者', 'Keep both'))),
                OutlinedButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: Text(context.tr('取消', 'Cancel'))),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, 'overwrite'), child: Text(context.tr('覆盖', 'Overwrite'))),
              ],
            ),
          );
          if (action == null || action == 'cancel') continue;
          if (action == 'overwrite') {
            final updated = existing.copyWith(
              translation: word.translation,
              partOfSpeech: word.partOfSpeech,
              example: word.example,
              notes: word.notes,
              isFavorite: existing.isFavorite || _autoFavorite,
            );
            await wordProvider.updateWord(updated);
            for (final bookId in finalBookIds) {
              await wordProvider.addWordToBook(existing.id!, bookId);
            }
            if (_autoFavorite) {
              final favBook = context.read<WordBookProvider>().favoritesBook;
              if (favBook != null) await wordProvider.addWordToBook(existing.id!, favBook.id!);
            }
            imported++;
            continue;
          }
          // keep_both: fall through to add as new
        }

        final w = word.copyWith(isFavorite: _autoFavorite);
        await wordProvider.addWord(w, wordBookIds: finalBookIds);
        imported++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('成功导入 $imported 个单词', 'Successfully imported $imported words')),
            backgroundColor: AppConstants.successColor,
          ),
        );
        // Stay on page — keep parsed words so user can import into different books
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('导入失败: $e', 'Import failed: $e')),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookProvider = context.watch<WordBookProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('AI 导入单词', 'AI Import')),
        actions: [
          if (_parsedWords.isNotEmpty)
            TextButton.icon(
              onPressed: _isImporting ? null : _importWords,
              icon: const Icon(Icons.download, size: 20),
              label: Text(context.t('导入 ${_selectedIndices.length} 个', 'Import ${_selectedIndices.length}')),
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text input
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: context.t('输入文本', 'Enter text'),
                hintText: context.t('粘贴英文文本或上传文件...', 'Paste English text or upload file...'),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: _pickFile,
                      tooltip: context.t('上传文件', 'Upload file'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.auto_awesome),
                      onPressed: _isParsing ? null : _parseText,
                      tooltip: context.t('AI解析', 'AI Parse'),
                    ),
                  ],
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              minLines: 3,
            ),

            if (_isParsing) ...[
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(context.t('AI正在解析中...', 'AI is parsing...')),
                  ],
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppConstants.errorColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: AppConstants.errorColor)),
                    ),
                  ],
                ),
              ),
            ],

            if (_parsedWords.isNotEmpty) ...[
              const SizedBox(height: 24),

              // Select/deselect all
              Row(
                children: [
                  Text(
                    context.t('解析结果 (${_parsedWords.length} 个单词)', 'Results (${_parsedWords.length} words)'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedIndices.length == _parsedWords.length) {
                          _selectedIndices.clear();
                        } else {
                          _selectedIndices =
                              Set.from(_parsedWords.asMap().keys);
                        }
                      });
                    },
                    child: Text(
                      _selectedIndices.length == _parsedWords.length
                          ? context.t('取消全选', 'Deselect all')
                          : context.t('全选', 'Select all'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Book selection — exclude 全部单词 (auto-added by DB)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...bookProvider.wordBooks.where((b) => b.name != AppConstants.allWordsBookName).map((book) {
                    final isSelected = _selectedBookIds.contains(book.id);
                    final isFav = book.name == AppConstants.favoritesBookName;
                    return FilterChip(
                      selected: isSelected,
                      label: Text(context.tBookName(book.name)),
                      selectedColor: (isFav ? AppConstants.errorColor : AppConstants.primaryColor).withValues(alpha: 0.15),
                      checkmarkColor: isFav ? AppConstants.errorColor : AppConstants.primaryColor,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            if (!_selectedBookIds.contains(book.id)) {
                              _selectedBookIds.add(book.id!);
                            }
                          } else {
                            _selectedBookIds.remove(book.id);
                          }
                        });
                      },
                    );
                  }),
                  ActionChip(
                    avatar: Icon(
                      _showNewBookField ? Icons.close : Icons.add,
                      size: 18,
                    ),
                    label: Text(_showNewBookField ? context.t('取消', 'Cancel') : context.t('新建单词本', 'New Book')),
                    onPressed: () {
                      setState(() {
                        _showNewBookField = !_showNewBookField;
                        if (!_showNewBookField) {
                          _newBookName = null;
                          _newBookController.clear();
                        }
                      });
                    },
                  ),
                ],
              ),

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

              if (_showNewBookField) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _newBookController,
                  decoration: InputDecoration(
                    labelText: context.t('新单词本名称', 'New book name'),
                    prefixIcon: const Icon(Icons.create_new_folder),
                  ),
                  onChanged: (v) => _newBookName = v.trim(),
                ),
              ],

              const SizedBox(height: 12),

              // Word list
              ...List.generate(_parsedWords.length, (index) {
                final word = _parsedWords[index];
                final isSelected = _selectedIndices.contains(index);

                return AnimatedContainer(
                  duration: AppConstants.shortAnimation,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppConstants.primaryColor.withValues(alpha: 0.05)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppConstants.primaryColor.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedIndices.add(index);
                        } else {
                          _selectedIndices.remove(index);
                        }
                      });
                    },
                    title: Text(word.word,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${word.translation} · ${word.partOfSpeech}${word.example != null ? '\n${word.example}' : ''}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
