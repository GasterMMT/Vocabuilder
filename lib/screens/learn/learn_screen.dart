import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/word_provider.dart';
import '../../utils/constants.dart';
import '../../utils/l10n.dart';
import 'import/import_screen.dart';
import 'flashcard/flashcard_setup_screen.dart';
import 'quiz/quiz_setup_screen.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wordProvider = context.watch<WordProvider>();
    final canQuiz = wordProvider.totalWordCount >= 4;

    return Scaffold(
      appBar: AppBar(title: const Text('Vocabuilder')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(context.t('今天继续学习吧！', 'Keep learning today!'), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 24),
            child: Text(context.t('已导入 ${wordProvider.totalWordCount} 个单词', '${wordProvider.totalWordCount} words imported'),
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withAlpha(130))),
          ),
          _HeroCard(
            icon: Icons.add_circle_outline,
            title: context.t('导入单词', 'Import Words'),
            subtitle: context.t('手动添加或AI智能导入', 'Manual entry or AI import'),
            gradient: AppConstants.gradientPrimary,
            onTap: () => Navigator.push(context, _route(const ImportScreen())),
          ),
          const SizedBox(height: 16),
          _HeroCard(
            icon: Icons.style_outlined,
            title: context.t('闪卡学习', 'Flashcards'),
            subtitle: context.t('翻卡记忆，高效背单词', 'Flip cards to memorize'),
            gradient: const [Color(0xFF7C3AED), Color(0xFFA78BFA)],
            onTap: () {
              if (wordProvider.totalWordCount == 0) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('请先导入单词', 'Please import words first'))));
                return;
              }
              Navigator.push(context, _route(const FlashcardSetupScreen()));
            },
          ),
          const SizedBox(height: 16),
          _HeroCard(
            icon: Icons.quiz_outlined,
            title: context.t('单词测验', 'Quiz'),
            subtitle: canQuiz ? context.t('选择题形式，检验学习成果', 'Multiple choice quiz') : context.t('需要至少4个单词才能开始测验', 'Need at least 4 words to start'),
            gradient: const [Color(0xFFF59E0B), Color(0xFFF97316)],
            enabled: canQuiz,
            onTap: canQuiz ? () => Navigator.push(context, _route(const QuizSetupScreen())) : null,
          ),
        ]),
      ),
    );
  }

  Route _route(Widget page) => MaterialPageRoute(builder: (_) => page);
}

class _HeroCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final List<Color> gradient;
  final VoidCallback? onTap;
  final bool enabled;
  const _HeroCard({required this.icon, required this.title, required this.subtitle, required this.gradient, this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: AppConstants.mediumAnimation,
      opacity: enabled ? 1.0 : 0.45,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppConstants.shortAnimation,
          curve: Curves.easeInOut,
          transform: Matrix4.identity()..scale(enabled ? 1.0 : 0.98),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: gradient.first.withAlpha(50), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Row(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 14)),
                ]),
              ),
              if (enabled) Icon(Icons.chevron_right, color: Colors.white.withAlpha(180), size: 24),
            ]),
          ),
        ),
      ),
    );
  }
}
