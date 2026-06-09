import 'package:flutter/material.dart';
import '../../models/word.dart';
import '../../services/import_service.dart';
import '../../utils/constants.dart';
import '../../utils/l10n.dart';

class ConflictResolutionScreen extends StatefulWidget {
  final List<WordConflict> conflicts;
  final List<Word> newWords;

  const ConflictResolutionScreen({
    super.key,
    required this.conflicts,
    required this.newWords,
  });

  @override
  State<ConflictResolutionScreen> createState() =>
      _ConflictResolutionScreenState();
}

class _ConflictResolutionScreenState extends State<ConflictResolutionScreen> {
  late List<bool?> _decisions;

  @override
  void initState() {
    super.initState();
    _decisions = List.filled(widget.conflicts.length, null);
  }

  void _importAll() {
    setState(() {
      for (int i = 0; i < _decisions.length; i++) {
        _decisions[i] = true;
      }
    });
  }

  void _keepAll() {
    setState(() {
      for (int i = 0; i < _decisions.length; i++) {
        _decisions[i] = false;
      }
    });
  }

  void _confirm() {
    final result = <int, bool>{};
    for (int i = 0; i < _decisions.length; i++) {
      if (_decisions[i] != null) {
        result[i] = _decisions[i]!;
      }
    }
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unresolved = _decisions.where((d) => d == null).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('解决冲突', 'Resolve Conflicts')),
        actions: [
          TextButton(
            onPressed: unresolved > 0 ? null : _confirm,
            child: Text(
              context.t('确认${unresolved > 0 ? " ($unresolved 未解决)" : ""}', 'Confirm${unresolved > 0 ? " ($unresolved unresolved)" : ""}'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppConstants.accentColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('发现 ${widget.conflicts.length} 个冲突单词', '${widget.conflicts.length} conflicting words found'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        context.t('${widget.newWords.length} 个新单词将直接导入', '${widget.newWords.length} new words will be imported directly'),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _importAll,
                    child: Text(context.t('全部使用新版本', 'Use all new versions')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _keepAll,
                    child: Text(context.t('全部保留原有', 'Keep all existing')),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              context.t('请逐一选择要保留的版本：', 'Select version to keep for each:'),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.conflicts.length,
              itemBuilder: (context, index) {
                final conflict = widget.conflicts[index];
                final decision = _decisions[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: decision != null
                        ? BorderSide(
                            color: decision
                                ? AppConstants.primaryColor
                                : AppConstants.secondaryColor,
                            width: 2,
                          )
                        : BorderSide.none,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conflict.existingWord.word,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _VersionCard(
                                label: context.t('原有', 'Existing'),
                                word: conflict.existingWord,
                                isSelected: decision == false,
                                onTap: () => setState(
                                    () => _decisions[index] = false),
                              ),
                            ),
                            const Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.arrow_forward,
                                  color: Colors.grey),
                            ),
                            Expanded(
                              child: _VersionCard(
                                label: context.t('新导入', 'Imported'),
                                word: conflict.importedWord,
                                isSelected: decision == true,
                                onTap: () => setState(
                                    () => _decisions[index] = true),
                              ),
                            ),
                          ],
                        ),

                        if (conflict.hasDifferences) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          Text(
                            context.t('差异：', 'Differences:'),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...conflict.differences.entries.map((entry) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      entry.key,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      entry.value['existing'] ?? '',
                                      style: const TextStyle(
                                        decoration: TextDecoration
                                            .lineThrough,
                                        color: AppConstants
                                            .errorColor,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward,
                                      size: 14,
                                      color: Colors.grey),
                                  Expanded(
                                    child: Text(
                                      entry.value['imported'] ?? '',
                                      style: const TextStyle(
                                        color: AppConstants
                                            .successColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: unresolved > 0 ? null : _confirm,
                child: Text(
                  unresolved > 0
                      ? context.t('还有 $unresolved 个冲突未解决', '$unresolved conflicts remaining')
                      : context.t('确认导入', 'Confirm Import'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  final String label;
  final Word word;
  final bool isSelected;
  final VoidCallback onTap;

  const _VersionCard({
    required this.label,
    required this.word,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.shortAnimation,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryColor
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: AppConstants.primaryColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              word.translation,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(word.partOfSpeech,
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            if (word.example != null && word.example!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(word.example!,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }
}
