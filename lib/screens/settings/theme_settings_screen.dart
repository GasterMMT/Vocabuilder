import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import '../../utils/l10n.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.t('主题设置', 'Theme Settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ThemeOption(
            title: context.t('跟随系统', 'Follow System'),
            subtitle: context.t('自动切换深色/浅色模式', 'Auto switch light/dark'),
            icon: Icons.brightness_auto,
            isSelected: settings.themeMode == AppThemeMode.system,
            onTap: () => settings.setThemeMode(AppThemeMode.system),
          ),
          const SizedBox(height: 12),
          _ThemeOption(
            title: context.t('浅色模式', 'Light Mode'),
            subtitle: context.t('始终使用浅色主题', 'Always use light theme'),
            icon: Icons.light_mode,
            isSelected: settings.themeMode == AppThemeMode.light,
            onTap: () => settings.setThemeMode(AppThemeMode.light),
          ),
          const SizedBox(height: 12),
          _ThemeOption(
            title: context.t('深色模式', 'Dark Mode'),
            subtitle: context.t('始终使用深色主题', 'Always use dark theme'),
            icon: Icons.dark_mode,
            isSelected: settings.themeMode == AppThemeMode.dark,
            onTap: () => settings.setThemeMode(AppThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.mediumAnimation,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppConstants.primaryColor
              : Colors.grey.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppConstants.primaryColor.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? AppConstants.primaryColor
                        : Colors.grey[600],
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: AppConstants.primaryColor, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
