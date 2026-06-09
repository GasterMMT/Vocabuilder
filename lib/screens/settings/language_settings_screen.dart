import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import '../../utils/l10n.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.t('语言设置', 'Language'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LanguageOption(
            title: context.t('跟随系统', 'Follow System'),
            subtitle: context.t('使用系统默认语言', 'Use system default language'),
            isSelected: settings.languageMode == AppLanguageMode.system,
            onTap: () => settings.setLanguageMode(AppLanguageMode.system),
          ),
          const SizedBox(height: 8),
          _LanguageOption(
            title: context.t('中文', 'Chinese'),
            subtitle: context.t('简体中文', 'Simplified Chinese'),
            isSelected: settings.languageMode == AppLanguageMode.chinese,
            onTap: () => settings.setLanguageMode(AppLanguageMode.chinese),
          ),
          const SizedBox(height: 8),
          _LanguageOption(
            title: 'English',
            subtitle: context.t('英文界面', 'English interface'),
            isSelected: settings.languageMode == AppLanguageMode.english,
            onTap: () => settings.setLanguageMode(AppLanguageMode.english),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.mediumAnimation,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppConstants.primaryColor
              : Colors.grey.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<bool>(
        value: true,
        groupValue: isSelected,
        onChanged: (_) => onTap(),
        title: Text(title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )),
        subtitle: Text(subtitle),
        activeColor: AppConstants.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
