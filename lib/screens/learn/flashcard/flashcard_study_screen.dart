import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/word.dart';
import '../../../providers/word_provider.dart';
import '../../../providers/study_provider.dart';
import '../../../services/database_service.dart';
import '../../../utils/constants.dart';
import '../../../utils/l10n.dart';
import '../quiz/quiz_setup_screen.dart';

class FlashcardStudyScreen extends StatefulWidget {
  final ImportSource source;
  final List<int> selectedWordIds;
  final int? selectedBookId;
  final int randomCount;
  const FlashcardStudyScreen({super.key, required this.source, required this.selectedWordIds, this.selectedBookId, this.randomCount = 10});
  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> with TickerProviderStateMixin {
  List<Word> _words = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isLoading = true;
  final List<int> _studiedWordIds = [];
  int _masteredCount = 0, _notMasteredCount = 0;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(vsync: this, duration: AppConstants.mediumAnimation);
    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(1.5, 0)).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeInOut));
    _loadWords();
  }

  Future<void> _loadWords() async {
    final words = await context.read<WordProvider>().getWordsForSelection(
      specificWordIds: widget.source == ImportSource.specificWords ? widget.selectedWordIds : null,
      wordBookId: widget.source == ImportSource.fromWordBook ? widget.selectedBookId : null,
      random: widget.source == ImportSource.randomWords,
      limit: widget.source == ImportSource.randomWords ? widget.randomCount : null,
    );
    if (mounted) { setState(() { _words = words; _isLoading = false; }); context.read<StudyProvider>().startStudySession(); }
  }

  void _flipCard() => setState(() => _isFlipped = !_isFlipped);

  Future<void> _markMastered(bool mastered) async {
    final word = _words[_currentIndex];
    if (!_studiedWordIds.contains(word.id)) _studiedWordIds.add(word.id!);
    if (mastered) { _masteredCount++; } else { _notMasteredCount++; }
    await DatabaseService.instance.updateWordMastery(word.id!, mastered);
    if (_currentIndex < _words.length - 1) {
      await _slideController.forward();
      setState(() { _currentIndex++; _isFlipped = false; });
      _slideController.reset();
    } else {
      await context.read<StudyProvider>().endStudySession(wordsStudied: _studiedWordIds.length, wordsMastered: _masteredCount, wordsNotMastered: _notMasteredCount);
      if (mounted) _showCompletionDialog();
    }
  }

  void _previousCard() { if (_currentIndex > 0) setState(() { _currentIndex--; _isFlipped = false; }); }

  Future<void> _toggleFavorite() async {
    await context.read<WordProvider>().toggleFavorite(_words[_currentIndex].id!);
    if (mounted) {
      final refreshed = await context.read<WordProvider>().getWordsForSelection(specificWordIds: _words.map((w) => w.id!).toList());
      setState(() { final cid = _words[_currentIndex].id; _words = refreshed; _currentIndex = _words.indexWhere((w) => w.id == cid); if (_currentIndex < 0) _currentIndex = 0; });
    }
  }

  void _showCompletionDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(context.tr('学习完成！', 'Study Complete!')),
      content: Text(context.tr('已复习 ${_studiedWordIds.length} 个单词\n掌握 $_masteredCount 个，未掌握 $_notMasteredCount 个', 'Reviewed ${_studiedWordIds.length} words\n$_masteredCount mastered, $_notMasteredCount not mastered')),
      actions: [
        OutlinedButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), child: Text(context.tr('返回主页', 'Home'))),
        ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => QuizSetupScreen(studiedWordIds: _studiedWordIds))); }, child: Text(context.tr('测验这些单词', 'Quiz these words'))),
      ],
    ));
  }

  @override
  void dispose() { _slideController.dispose(); final sp = context.read<StudyProvider>(); if (sp.isStudying) sp.pauseStudySession(); super.dispose(); }

  static const double _btnW = 110;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) return Scaffold(appBar: AppBar(title: Text(context.t('闪卡学习', 'Flashcards'))), body: const Center(child: CircularProgressIndicator()));
    if (_words.isEmpty) return Scaffold(appBar: AppBar(title: Text(context.t('闪卡学习', 'Flashcards'))), body: Center(child: Text(context.t('没有单词可学习', 'No words to study'))));
    final w = _words[_currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text(context.t('闪卡 ${_currentIndex + 1}/${_words.length}', 'Card ${_currentIndex + 1}/${_words.length}'))),
      body: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: (_currentIndex + 1) / _words.length, backgroundColor: Colors.grey.shade200, valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryColor), minHeight: 6))),
        const SizedBox(height: 6),
        Text('${_currentIndex + 1} / ${_words.length}', style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(150), fontSize: 13)),
        Expanded(
          child: GestureDetector(
            onTap: _flipCard,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: SlideTransition(position: _slideAnimation, child: Stack(children: [
                AnimatedOpacity(opacity: _isFlipped ? 0.0 : 1.0, duration: AppConstants.mediumAnimation, child: _frontCard(w)),
                AnimatedOpacity(opacity: _isFlipped ? 1.0 : 0.0, duration: AppConstants.mediumAnimation, child: _backCard(w, theme)),
              ])),
            ),
          ),
        ),
        IconButton(icon: Icon(w.isFavorite ? Icons.favorite : Icons.favorite_border, color: w.isFavorite ? AppConstants.errorColor : Colors.grey, size: 32), onPressed: _toggleFavorite, visualDensity: VisualDensity.compact),
        Padding(padding: const EdgeInsets.fromLTRB(8, 0, 8, 20), child: _isFlipped ? _masteryBtns() : _navBtns()),
      ]),
    );
  }

  final _btnStyle = OutlinedButton.styleFrom(minimumSize: const Size(0, 38), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), visualDensity: VisualDensity.compact);

  Widget _navBtns() => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    _currentIndex > 0 ? SizedBox(width: _btnW, child: OutlinedButton.icon(onPressed: _previousCard, icon: const Icon(Icons.arrow_back, size: 18), label: Text(context.t('上一张', 'Previous'), style: const TextStyle(fontSize: 13)), style: _btnStyle)) : const SizedBox(width: _btnW),
    Text(context.t('点击卡片翻转', 'Tap to flip'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(100), fontSize: 14)),
    SizedBox(width: _btnW, child: _currentIndex < _words.length - 1 ? OutlinedButton.icon(onPressed: () => _markMastered(true), icon: const Icon(Icons.arrow_forward, size: 18), label: Text(context.t('下一张', 'Next'), style: const TextStyle(fontSize: 13)), style: _btnStyle) : OutlinedButton.icon(onPressed: () => _markMastered(true), icon: const Icon(Icons.check, size: 18), label: Text(context.t('完成', 'Done'), style: const TextStyle(fontSize: 13)), style: _btnStyle)),
  ]);

  Widget _masteryBtns() {
    final notM = SizedBox(width: _btnW, child: OutlinedButton.icon(onPressed: () => _markMastered(false), icon: const Icon(Icons.close, color: AppConstants.errorColor, size: 18), label: Text(context.t('未掌握', 'Not mastered'), style: const TextStyle(color: AppConstants.errorColor, fontSize: 13)), style: OutlinedButton.styleFrom(side: const BorderSide(color: AppConstants.errorColor), minimumSize: const Size(0, 38), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), visualDensity: VisualDensity.compact)));
    final mBtn = SizedBox(width: _btnW, child: OutlinedButton.icon(onPressed: () => _markMastered(true), icon: const Icon(Icons.check, color: AppConstants.successColor, size: 18), label: Text(context.t('掌握', 'Mastered'), style: const TextStyle(color: AppConstants.successColor, fontSize: 13)), style: OutlinedButton.styleFrom(side: const BorderSide(color: AppConstants.successColor), minimumSize: const Size(0, 38), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), visualDensity: VisualDensity.compact)));
    final prev = _currentIndex > 0 ? SizedBox(width: _btnW, child: OutlinedButton.icon(onPressed: _previousCard, icon: const Icon(Icons.arrow_back, size: 18), label: Text(context.t('上一张', 'Previous'), style: const TextStyle(fontSize: 13)), style: _btnStyle)) : const SizedBox(width: _btnW);
    return Row(children: [prev, Expanded(child: Center(child: notM)), mBtn]);
  }

  Widget _frontCard(Word w) => Container(
    width: double.infinity, height: double.infinity,
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: AppConstants.gradientPrimary, begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: AppConstants.primaryColor.withAlpha(60), blurRadius: 24, offset: const Offset(0, 10))],
    ),
    child: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.touch_app, color: Colors.white60, size: 28),
      const SizedBox(height: 20),
      Text(w.word, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -0.5), textAlign: TextAlign.center),
      if (w.partOfSpeech.isNotEmpty) ...[const SizedBox(height: 12), Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(20)), child: Text(w.partOfSpeech, style: const TextStyle(color: Colors.white70, fontSize: 14)))],
    ]))),
  );

  Widget _backCard(Word w, ThemeData theme) => Container(
    width: double.infinity, height: double.infinity,
    decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppConstants.primaryColor.withAlpha(30)), boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 24, offset: const Offset(0, 10))]),
    child: SingleChildScrollView(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(w.word, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppConstants.primaryColor)),
      const SizedBox(height: 16),
      Text(w.translation, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
      if (w.partOfSpeech.isNotEmpty) ...[const SizedBox(height: 10), Chip(label: Text(w.partOfSpeech), visualDensity: VisualDensity.compact)],
      if (w.example != null && w.example!.isNotEmpty) ...[const SizedBox(height: 20), const Divider(), const SizedBox(height: 16), Text(context.t('例句', 'Example'), style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(150))), const SizedBox(height: 8), Text(w.example!, style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic), textAlign: TextAlign.center)],
      if (w.notes != null && w.notes!.isNotEmpty) ...[const SizedBox(height: 16), Text(context.t('笔记: ${w.notes}', 'Notes: ${w.notes}'), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withAlpha(150)), textAlign: TextAlign.center)],
    ])),
  );
}
