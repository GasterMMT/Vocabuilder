import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import '../../utils/l10n.dart';
import 'language_settings_screen.dart';
import 'theme_settings_screen.dart';
import 'llm_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _exportPath = '';

  @override
  void initState() {
    super.initState();
    _loadPath();
  }

  Future<void> _loadPath() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('export_path');
    if (saved != null && saved.isNotEmpty) {
      setState(() => _exportPath = saved);
    } else {
      final dir = await getApplicationDocumentsDirectory();
      setState(() => _exportPath = '${dir.path}/exports/');
    }
  }

  Future<void> _pickExportPath() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('export_path', result);
      setState(() => _exportPath = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.t('设置', 'Settings'))),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader(context, context.t('外观', 'Appearance')),
          const SizedBox(height: 8),
          _card(children: [
            _tile(context, icon: Icons.language, title: context.t('语言设置', 'Language'), subtitle: _langLabel(settings, context), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()))),
            const Divider(height: 1, indent: 56, endIndent: 16),
            _tile(context, icon: Icons.palette_outlined, title: context.t('主题设置', 'Theme'), subtitle: _themeLabel(settings, context), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()))),
          ]),
          const SizedBox(height: 28),
          _sectionHeader(context, context.t('AI 设置', 'AI Settings')),
          const SizedBox(height: 8),
          _card(children: [_tile(context, icon: Icons.smart_toy_outlined, title: context.t('LLM 设置', 'LLM Settings'), subtitle: context.t('配置AI模型用于单词解析', 'Configure AI model for word parsing'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LLMSettingsScreen())))]),
          const SizedBox(height: 28),
          _sectionHeader(context, context.t('数据', 'Data')),
          const SizedBox(height: 8),
          _card(children: [_tile(context, icon: Icons.folder_outlined, title: context.t('导出路径', 'Export Path'), subtitle: _exportPath.isNotEmpty ? _exportPath : context.t('点击设置', 'Tap to set'), onTap: _pickExportPath)]),
          const SizedBox(height: 28),
          _sectionHeader(context, context.t('关于', 'About')),
          const SizedBox(height: 8),
          _card(children: [_tile(context, icon: Icons.info_outline, title: context.t('版本', 'Version'), subtitle: '1.0.0', onTap: null)]),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppConstants.primaryColor, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
  );

  Widget _card({required List<Widget> children}) => Container(
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withAlpha(25)), boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 12, offset: const Offset(0, 4))]),
    child: Column(children: children),
  );

  Widget _tile(BuildContext context, {required IconData icon, required String title, required String subtitle, VoidCallback? onTap}) => ListTile(
    leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppConstants.primaryColor.withAlpha(20), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppConstants.primaryColor, size: 20)),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
    subtitle: Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 13)),
    trailing: onTap != null ? Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20) : null,
    onTap: onTap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  );

  String _langLabel(SettingsProvider s, BuildContext c) {
    switch (s.languageMode) { case AppLanguageMode.system: return c.t('跟随系统', 'Follow System'); case AppLanguageMode.chinese: return c.t('中文', 'Chinese'); case AppLanguageMode.english: return 'English'; }
  }
  String _themeLabel(SettingsProvider s, BuildContext c) {
    switch (s.themeMode) { case AppThemeMode.system: return c.t('跟随系统', 'Follow System'); case AppThemeMode.light: return c.t('浅色模式', 'Light'); case AppThemeMode.dark: return c.t('深色模式', 'Dark'); }
  }
}
