import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/word_provider.dart';
import '../../../providers/word_book_provider.dart';
import '../../../utils/constants.dart';
import '../../../utils/l10n.dart';
import 'flashcard_study_screen.dart';

class FlashcardSetupScreen extends StatefulWidget {
  const FlashcardSetupScreen({super.key});

  @override
  State<FlashcardSetupScreen> createState() => _FlashcardSetupScreenState();
}

class _FlashcardSetupScreenState extends State<FlashcardSetupScreen> {
  ImportSource _source = ImportSource.fromWordBook;
  int? _selectedBookId;
  List<int> _selectedWordIds = [];
  int? _randomCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wordProvider = context.watch<WordProvider>();
    final bookProvider = context.watch<WordBookProvider>();
    final totalWords = wordProvider.totalWordCount;

    return Scaffold(
      appBar: AppBar(title: Text(context.t('闪卡学习', 'Flashcards'))),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.t('选择学习方式', 'Select study mode'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            _SourceOption(
              title: context.t('从单词本选择', 'From word book'),
              subtitle: context.t('选择某个单词本中的所有单词', 'All words in a book'),
              icon: Icons.book,
              isSelected: _source == ImportSource.fromWordBook,
              onTap: () => setState(() { _source = ImportSource.fromWordBook; _selectedWordIds = []; }),
            ),
            const SizedBox(height: 12),
            _SourceOption(
              title: context.t('指定单词', 'Specific words'),
              subtitle: context.t('从所有单词中选择特定单词', 'Pick specific words'),
              icon: Icons.checklist,
              isSelected: _source == ImportSource.specificWords,
              onTap: () => setState(() { _source = ImportSource.specificWords; _selectedBookId = null; }),
            ),
            const SizedBox(height: 12),
            _SourceOption(
              title: context.t('随机单词', 'Random words'),
              subtitle: context.t('随机抽取单词进行学习', 'Randomly selected words'),
              icon: Icons.shuffle,
              isSelected: _source == ImportSource.randomWords,
              onTap: () => setState(() { _source = ImportSource.randomWords; _selectedBookId = null; _selectedWordIds = []; }),
            ),

            const SizedBox(height: 24),

            if (_source == ImportSource.fromWordBook) ...[
              Text(context.t('选择单词本', 'Select word book'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...bookProvider.wordBooks.map((book) => Card(
                child: RadioListTile<int>(
                  value: book.id!,
                  groupValue: _selectedBookId,
                  onChanged: (v) => setState(() => _selectedBookId = v),
                  title: Text(context.tBookName(book.name)),
                  subtitle: book.description != null ? Text(book.description!) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )),
            ],

            if (_source == ImportSource.specificWords) ...[
              Text(context.t('选择单词 (勾选后下滑)', 'Select words (scroll down)'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              if (_selectedWordIds.isNotEmpty)
                Text(context.t('已选 ${_selectedWordIds.length} 个', '${_selectedWordIds.length} selected'), style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(150))),
              const SizedBox(height: 8),
              SizedBox(
                height: 300,
                child: ListView(
                  children: wordProvider.allWords.map((word) => CheckboxListTile(
                    value: _selectedWordIds.contains(word.id),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) _selectedWordIds.add(word.id!);
                        else _selectedWordIds.remove(word.id);
                      });
                    },
                    title: Text(word.word),
                    subtitle: Text(word.translation),
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  )).toList(),
                ),
              ),
            ],

            if (_source == ImportSource.randomWords) ...[
              Text(context.t('设置随机数量', 'Set random count'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: (_randomCount ?? _getDefaultRandomCount(totalWords)).toDouble(),
                      min: 1,
                      max: totalWords > 1 ? totalWords.toDouble() : 2.0,
                      divisions: totalWords > 1 ? totalWords - 1 : 1,
                      label: '${_randomCount ?? _getDefaultRandomCount(totalWords)}',
                      onChanged: (v) => setState(() => _randomCount = v.round()),
                    ),
                  ),
                  SizedBox(width: 50, child: Text('${_randomCount ?? _getDefaultRandomCount(totalWords)}', style: theme.textTheme.titleMedium)),
                ],
              ),
            ],

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canStart(totalWords) ? _startFlashcards : null,
                icon: const Icon(Icons.play_arrow),
                label: Text(context.t('开始学习', 'Start Study')),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getDefaultRandomCount(int total) => total.clamp(1, 10);

  bool _canStart(int totalWords) {
    if (totalWords == 0) return false;
    switch (_source) {
      case ImportSource.specificWords:
        return _selectedWordIds.isNotEmpty;
      case ImportSource.fromWordBook:
        return _selectedBookId != null;
      case ImportSource.randomWords:
        return true;
    }
  }

  void _startFlashcards() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardStudyScreen(
          source: _source,
          selectedWordIds: _selectedWordIds,
          selectedBookId: _selectedBookId,
          randomCount: _randomCount ?? _getDefaultRandomCount(context.read<WordProvider>().totalWordCount),
        ),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SourceOption({required this.title, required this.subtitle, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.mediumAnimation,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? AppConstants.primaryColor : Colors.grey.withAlpha(77), width: isSelected ? 2 : 1),
      ),
      child: RadioListTile<bool>(
        value: true,
        groupValue: isSelected,
        onChanged: (_) => onTap(),
        title: Row(children: [Icon(icon, size: 20, color: AppConstants.primaryColor), const SizedBox(width: 12), Text(title, style: const TextStyle(fontWeight: FontWeight.w600))]),
        subtitle: Padding(padding: const EdgeInsets.only(left: 32), child: Text(subtitle)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
