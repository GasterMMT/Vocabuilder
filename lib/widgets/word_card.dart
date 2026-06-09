import 'package:flutter/material.dart';
import '../models/word.dart';
import '../utils/constants.dart';
import 'favorite_button.dart';

class WordCard extends StatelessWidget {
  final Word word;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onLongPress;

  const WordCard({
    super.key,
    required this.word,
    this.onTap,
    this.onFavoriteToggle,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: AppConstants.mediumAnimation,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppConstants.primaryColor.withAlpha(25) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppConstants.primaryColor : theme.colorScheme.outlineVariant.withAlpha(50),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isSelectionMode && onTap != null) {
              onTap!(); // Toggle selection
            } else if (!isSelectionMode && onTap != null) {
              onTap!(); // Normal tap
            }
          },
          onLongPress: () {
            if (onLongPress != null) onLongPress!();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AnimatedContainer(
                    duration: AppConstants.shortAnimation,
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppConstants.primaryColor : Colors.transparent,
                      border: Border.all(color: isSelected ? AppConstants.primaryColor : Colors.grey, width: 2),
                    ),
                    child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                  ),
                ),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(word.word, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(word.translation, style: theme.textTheme.bodyMedium?.copyWith(color: AppConstants.primaryColor)),
                  if (word.partOfSpeech.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppConstants.secondaryColor.withAlpha(25), borderRadius: BorderRadius.circular(4)),
                        child: Text(word.partOfSpeech, style: theme.textTheme.bodySmall?.copyWith(color: AppConstants.secondaryColor)),
                      ),
                      if (word.example != null && word.example!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(child: Text(word.example!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(150)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ]),
                  ],
                ]),
              ),
              if (onFavoriteToggle != null && !isSelectionMode)
                FavoriteButton(isFavorite: word.isFavorite, onTap: onFavoriteToggle!, size: 28),
            ]),
          ),
        ),
      ),
    );
  }
}
