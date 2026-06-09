import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/word_provider.dart';
import '../../../providers/word_book_provider.dart';
import '../../../utils/constants.dart';
import '../../../utils/l10n.dart';
import 'quiz_screen.dart';

class QuizSetupScreen extends StatefulWidget {
  final List<int>? studiedWordIds;
  const QuizSetupScreen({super.key, this.studiedWordIds});

  @override
  State<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  ImportSource _source = ImportSource.fromWordBook;
  int? _selectedBookId;
  List<int> _selectedWordIds = [];
  int? _questionCount;

  @override
  void initState() {
    super.initState();
    if (widget.studiedWordIds != null && widget.studiedWordIds!.isNotEmpty) {
      _source = ImportSource.specificWords;
      _selectedWordIds = widget.studiedWordIds!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wordProvider = context.watch<WordProvider>();
    final bookProvider = context.watch<WordBookProvider>();
    final totalWords = wordProvider.totalWordCount;

    if (totalWords < 4) {
      return Scaffold(
        appBar: AppBar(title: Text(context.t('单词测验', 'Quiz'))),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.warning_amber, size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          Text(context.t('需要至少4个单词才能进行测验', 'Need at least 4 words to start quiz')),
          Text(context.t('请先导入更多单词', 'Please import more words first')),
        ])),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.t('单词测验', 'Quiz'))),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (widget.studiedWordIds != null && widget.studiedWordIds!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppConstants.primaryColor.withAlpha(25), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.info_outline, color: AppConstants.primaryColor), const SizedBox(width: 8),
                Expanded(child: Text(context.t('将对刚学过的单词进行测验', 'Quiz on recently studied words'), style: const TextStyle(color: AppConstants.primaryColor))),
              ]),
            ),

          Text(context.t('选择测验范围', 'Select quiz source'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          _SourceOption(title: context.t('从单词本选择', 'From word book'), subtitle: context.t('选择某一单词本的单词', 'Words from a book'), icon: Icons.book, isSelected: _source == ImportSource.fromWordBook,
            onTap: () => setState(() { _source = ImportSource.fromWordBook; _selectedWordIds = []; })),
          const SizedBox(height: 12),
          _SourceOption(title: context.t('指定单词', 'Specific words'), subtitle: context.t('选择特定单词进行测验', 'Select specific words'), icon: Icons.checklist, isSelected: _source == ImportSource.specificWords,
            onTap: () => setState(() { _source = ImportSource.specificWords; _selectedBookId = null; })),
          const SizedBox(height: 12),
          _SourceOption(title: context.t('随机单词', 'Random words'), subtitle: context.t('随机抽取单词进行测验', 'Randomly selected words'), icon: Icons.shuffle, isSelected: _source == ImportSource.randomWords,
            onTap: () => setState(() { _source = ImportSource.randomWords; _selectedBookId = null; _selectedWordIds = []; })),

          const SizedBox(height: 20),

          if (_source == ImportSource.fromWordBook) ...[
            ...bookProvider.wordBooks.where((b) => !b.isDefault || b.name == AppConstants.allWordsBookName).map((book) =>
              Card(child: RadioListTile<int>(value: book.id!, groupValue: _selectedBookId, onChanged: (v) => setState(() => _selectedBookId = v),
                title: Text(context.tBookName(book.name)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
          ],

          if (_source == ImportSource.specificWords) ...[
            Text(context.t('选择单词', 'Select words'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            if (_selectedWordIds.isNotEmpty) Text(context.t('已选 ${_selectedWordIds.length} 个', '${_selectedWordIds.length} selected'), style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(150))),
            const SizedBox(height: 8),
            SizedBox(height: 300, child: ListView(
              children: wordProvider.allWords.map((word) => CheckboxListTile(
                value: _selectedWordIds.contains(word.id),
                onChanged: (v) { setState(() { if (v == true) _selectedWordIds.add(word.id!); else _selectedWordIds.remove(word.id); }); },
                title: Text(word.word), subtitle: Text(word.translation), dense: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              )).toList(),
            )),
          ],

          if (_source == ImportSource.randomWords) ...[
            Text(context.t('题目数量', 'Number of questions'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Slider(
                value: (_safeQuestionCount).toDouble(),
                min: 4.0,
                max: totalWords.toDouble().clamp(4.0, 50.0),
                divisions: totalWords > 4 ? (totalWords - 4) : null,
                label: '${_safeQuestionCount}',
                onChanged: (v) => setState(() => _questionCount = v.round()),
              )),
              SizedBox(width: 50, child: Text('${_safeQuestionCount}', style: theme.textTheme.titleMedium)),
            ]),
          ],

          const SizedBox(height: 40),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: _canStart(totalWords) ? _startQuiz : null,
            icon: const Icon(Icons.play_arrow), label: Text(context.t('开始测验', 'Start Quiz')),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 18)),
          )),
        ]),
      ),
    );
  }

  int get _safeQuestionCount {
    final total = context.read<WordProvider>().totalWordCount;
    final count = _questionCount ?? total.clamp(4, 10);
    return count.clamp(4, total);
  }

  bool _canStart(int totalWords) {
    switch (_source) {
      case ImportSource.specificWords: return _selectedWordIds.length >= 4;
      case ImportSource.fromWordBook: return _selectedBookId != null;
      case ImportSource.randomWords: return totalWords >= 4;
    }
  }

  Future<void> _startQuiz() async {
    final wordProvider = context.read<WordProvider>();
    final words = await wordProvider.getWordsForSelection(
      specificWordIds: _source == ImportSource.specificWords ? _selectedWordIds : null,
      wordBookId: _source == ImportSource.fromWordBook ? _selectedBookId : null,
      random: _source == ImportSource.randomWords,
      limit: _source == ImportSource.randomWords ? _safeQuestionCount : null,
    );

    if (words.length < 4) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('可用单词不足4个', 'Not enough words available'))));
      return;
    }
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(wordPool: words, questionCount: words.length)));
    }
  }
}

class _SourceOption extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _SourceOption({required this.title, required this.subtitle, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.mediumAnimation,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? AppConstants.primaryColor : Colors.grey.withAlpha(77), width: isSelected ? 2 : 1)),
      child: RadioListTile<bool>(value: true, groupValue: isSelected, onChanged: (_) => onTap(),
        title: Row(children: [Icon(icon, size: 20, color: AppConstants.primaryColor), const SizedBox(width: 12), Text(title, style: const TextStyle(fontWeight: FontWeight.w600))]),
        subtitle: Padding(padding: const EdgeInsets.only(left: 32), child: Text(subtitle)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }
}
