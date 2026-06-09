import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/word.dart';
import '../../../providers/quiz_provider.dart';
import '../../../providers/study_provider.dart';
import '../../../services/database_service.dart';
import '../../../utils/constants.dart';
import '../../../utils/l10n.dart';

class QuizScreen extends StatefulWidget {
  final List<Word> wordPool;
  final int questionCount;

  const QuizScreen({
    super.key,
    required this.wordPool,
    required this.questionCount,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  int _answeredCount = 0;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    final quizProvider = context.read<QuizProvider>();
    quizProvider.generateQuiz(widget.wordPool,
        questionCount: widget.questionCount);

    // Start study timer
    context.read<StudyProvider>().startStudySession();
  }

  @override
  void dispose() {
    _progressController.dispose();
    final studyProvider = context.read<StudyProvider>();
    if (studyProvider.isStudying) {
      studyProvider.pauseStudySession();
    }
    super.dispose();
  }

  void _answerQuestion(int selectedIndex) {
    final quizProvider = context.read<QuizProvider>();
    final current = quizProvider.currentQuestion;
    if (current == null || current.isCorrect != null) return;

    quizProvider.answerCurrentQuestion(selectedIndex);
    setState(() => _answeredCount++);
  }

  void _nextQuestion() {
    final quizProvider = context.read<QuizProvider>();
    if (quizProvider.currentIndex < quizProvider.totalQuestions - 1) {
      quizProvider.nextQuestion();
      setState(() {});
    } else {
      // Last question — finish quiz directly
      quizProvider.nextQuestion(); // sets isCompleted
      _finishQuiz();
    }
  }

  void _finishQuiz() async {
    if (_finishing) return;
    _finishing = true;
    final quizProvider = context.read<QuizProvider>();
    final studyProvider = context.read<StudyProvider>();

    studyProvider.pauseStudySession();

    // Update per-word mastery BEFORE recordQuizResult (which calls loadStats)
    final db = DatabaseService.instance;
    for (final q in quizProvider.questions) {
      if (q.isCorrect != null && q.word.id != null) {
        await db.updateWordMastery(q.word.id!, q.isCorrect!);
      }
    }

    await studyProvider.recordQuizResult(
      correctAnswers: quizProvider.correctCount,
      totalQuestions: quizProvider.totalQuestions,
    );

    if (mounted) {
      _showResults();
    }
  }

  void _showResults() {
    final quizProvider = context.read<QuizProvider>();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Text(context.t('测验结果', 'Quiz Results'), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Score circle
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: quizProvider.accuracy,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        quizProvider.accuracy >= 0.6
                            ? AppConstants.successColor
                            : AppConstants.errorColor,
                      ),
                    ),
                  ),
                  Text(
                    '${(quizProvider.accuracy * 100).round()}%',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: quizProvider.accuracy >= 0.6
                          ? AppConstants.successColor
                          : AppConstants.errorColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ResultItem(
                  icon: Icons.check_circle,
                  label: context.t('正确', 'Correct'),
                  value: '${quizProvider.correctCount}',
                  color: AppConstants.successColor,
                ),
                _ResultItem(
                  icon: Icons.cancel,
                  label: context.t('错误', 'Wrong'),
                  value: '${quizProvider.incorrectCount}',
                  color: AppConstants.errorColor,
                ),
                _ResultItem(
                  icon: Icons.quiz_outlined,
                  label: context.t('总计', 'Total'),
                  value: '${quizProvider.totalQuestions}',
                  color: AppConstants.primaryColor,
                ),
              ],
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to quiz setup
            },
            child: Text(context.t('返回', 'Back')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Text(context.t('返回主页', 'Home')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quizProvider = context.watch<QuizProvider>();

    if (quizProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(context.t('单词测验', 'Quiz'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final question = quizProvider.currentQuestion;

    if (question == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.t('单词测验', 'Quiz'))),
        body: Center(child: Text(context.t('无法生成测验', 'Cannot generate quiz'))),
      );
    }

    final isAnswered = question.isCorrect != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            context.t('测验 ${quizProvider.currentIndex + 1}/${quizProvider.totalQuestions}', 'Quiz ${quizProvider.currentIndex + 1}/${quizProvider.totalQuestions}')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(context.tr('退出测验？', 'Exit quiz?')),
                content: Text(context.tr('已答题目将会丢失', 'Answered questions will be lost')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(context.tr('继续', 'Continue'))),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: Text(context.tr('退出', 'Exit')),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (quizProvider.currentIndex) /
                          quizProvider.totalQuestions,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppConstants.primaryColor),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${quizProvider.currentIndex + 1}/${quizProvider.totalQuestions}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Question
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Word display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppConstants.primaryColor,
                          AppConstants.secondaryColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryColor
                              .withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.help_outline,
                            color: Colors.white70, size: 28),
                        const SizedBox(height: 12),
                        Text(
                          context.t('选择以下单词的翻译：', 'Choose the translation:'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          question.word.word,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (question.word.partOfSpeech.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              question.word.partOfSpeech,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Options
                  ...List.generate(question.options.length, (index) {
                    Color? bgColor;
                    Color? borderColor;
                    IconData? trailingIcon;

                    if (isAnswered) {
                      if (index == question.correctIndex) {
                        bgColor = AppConstants.successColor
                            .withValues(alpha: 0.1);
                        borderColor = AppConstants.successColor;
                        trailingIcon = Icons.check_circle;
                      } else if (index == question.selectedIndex &&
                          !question.isCorrect!) {
                        bgColor = AppConstants.errorColor
                            .withValues(alpha: 0.1);
                        borderColor = AppConstants.errorColor;
                        trailingIcon = Icons.cancel;
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AnimatedContainer(
                        duration: AppConstants.shortAnimation,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: borderColor ??
                                Colors.grey.withValues(alpha: 0.3),
                            width: borderColor != null ? 2 : 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isAnswered
                                ? null
                                : () => _answerQuestion(index),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isAnswered &&
                                              index ==
                                                  question.correctIndex
                                          ? AppConstants.successColor
                                          : AppConstants.primaryColor
                                              .withValues(alpha: 0.1),
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(
                                            65 + index), // A, B, C, D
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isAnswered &&
                                                  index ==
                                                      question
                                                          .correctIndex
                                              ? Colors.white
                                              : AppConstants
                                                  .primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      question.options[index],
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (trailingIcon != null)
                                    Icon(trailingIcon,
                                        color: borderColor, size: 22),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isAnswered ? _nextQuestion : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  quizProvider.currentIndex < quizProvider.totalQuestions - 1
                      ? context.t('下一题', 'Next')
                      : context.t('查看结果', 'View Results'),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const _ResultItem({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 4),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }
}
