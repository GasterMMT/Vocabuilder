import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Vocabuilder';
  static const String allWordsBookName = '全部单词';
  static const String favoritesBookName = '收藏';

  // Primary palette — indigo
  static const Color primaryColor = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color secondaryColor = Color(0xFF7C3AED);
  static const Color accentColor = Color(0xFFF59E0B);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);

  // Surface
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E293B);

  // Gradients
  static const List<Color> gradientPrimary = [Color(0xFF4F46E5), Color(0xFF7C3AED)];
  static const List<Color> gradientSuccess = [Color(0xFF10B981), Color(0xFF059669)];
  static const List<Color> gradientWarm = [Color(0xFFF59E0B), Color(0xFFEF4444)];

  // Animation durations
  static const Duration quickAnimation = Duration(milliseconds: 120);
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Sort options
  static const List<String> sortOptions = [
    '字母顺序 (A-Z)',
    '字母顺序 (Z-A)',
    '导入时间 (最新)',
    '导入时间 (最早)',
  ];
}

enum SortMode { alphabeticalAsc, alphabeticalDesc, importTimeNewest, importTimeOldest }
enum AppThemeMode { system, light, dark }
enum AppLanguageMode { system, chinese, english }
enum ImportSource { specificWords, fromWordBook, randomWords }
