import 'package:flutter/material.dart';
import '../utils/constants.dart';

class FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  final double size;

  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onTap,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
        // Add haptic feedback-like visual effect
      },
      child: AnimatedContainer(
        duration: AppConstants.mediumAnimation,
        curve: Curves.easeInOut,
        child: AnimatedSwitcher(
          duration: AppConstants.shortAnimation,
          switchInCurve: Curves.easeInBack,
          switchOutCurve: Curves.easeOutBack,
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            key: ValueKey<bool>(isFavorite),
            size: size,
            color: isFavorite ? AppConstants.errorColor : Colors.grey,
          ),
        ),
      ),
    );
  }
}
