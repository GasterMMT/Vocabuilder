import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'constants.dart';

extension L10n on BuildContext {
  /// Localize a string. Use in build methods to auto-watch SettingsProvider.
  String t(String zh, String en) => watch<SettingsProvider>().t(zh, en);

  /// Localize a string without watching (for use in callbacks/onPressed).
  String tr(String zh, String en) => read<SettingsProvider>().t(zh, en);

  /// Translate a book name (handles default book names).
  String tBookName(String name) {
    switch (name) {
      case AppConstants.allWordsBookName:
        return t('全部单词', 'All Words');
      case AppConstants.favoritesBookName:
        return t('收藏', 'Favorites');
      default:
        return name;
    }
  }
}
