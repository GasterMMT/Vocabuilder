<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.44-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.12-blue?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Material-Design%203-indigo?logo=material-design" alt="Material Design 3">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
</p>

<h1 align="center">📚 Vocabuilder</h1>
<p align="center"><strong>优雅的词汇学习助手  |  Elegant Vocabulary Learning Companion</strong></p>

---

<p align="center">
  <b>Vocabuilder</b> 是一款使用 <b>Flutter</b> 框架完全重构的跨平台词汇学习应用。采用 <b>Material Design 3</b> 设计语言，支持中英双语界面，提供闪卡记忆、单词测验、单词本管理等核心功能。<br><br>
  <b>Vocabuilder</b> is a cross-platform vocabulary learning app completely rebuilt with <b>Flutter</b>. Featuring <b>Material Design 3</b>, bilingual UI (Chinese/English), flashcard study, quiz mode, and word book management.
</p>

---

## ✨ 功能 | Features

### 📖 学习 | Learn
- **手动导入** — 逐词录入单词、翻译、词性、例句、笔记
- **AI 智能导入** — 粘贴文本或上传文件，AI 自动解析（支持 OpenAI / Anthropic / Google Gemini / DeepSeek）
- **闪卡记忆** — 大卡片翻面学习，掌握/未掌握打分，进度追踪
- **单词测验** — 选择题模式，≥4 个单词即可开始，自动统计正确率

### 📂 单词本 | Word Books
- 默认「全部单词」+「收藏」两个系统单词本
- 自定义单词本，支持创建、删除、重命名
- 批量选择：全选/反选、批量删除、批量添加到其他单词本、批量收藏
- 跨单词本同步收藏状态
- **导出/导入** — JSON 格式，支持同名冲突处理（覆盖/重命名/保留）

### 📊 统计 | Statistics
- 今日/累计学习时长、总单词数、收藏数
- **已掌握/未掌握** — 基于每词追踪（闪卡 + 测验综合判定）
- **正确率** — 测验正确率实时统计
- **学习日历热力图** — 按月查看每日学习时长

### ⚙️ 设置 | Settings
- 语言切换：跟随系统 / 中文 / English
- 主题切换：跟随系统 / 浅色 / 深色
- LLM 配置：多提供商支持，一键获取模型列表
- 自定义导出路径

---

## 🛠 技术栈 | Tech Stack

| 类别 | 技术 |
|------|------|
| 框架 | **Flutter 3.44** · **Dart 3.12** |
| 状态管理 | **Provider** + ChangeNotifier |
| 数据库 | **SQLite** (sqflite) |
| UI | **Material Design 3** |
| 国际化 | flutter_localizations · 中英双语 |
| HTTP | http · AI API 集成 |
| 存储 | shared_preferences · path_provider |
| 文件 | file_picker |

---

## 🚀 快速开始 | Quick Start

```bash
git clone https://github.com/GasterMMT/Vocabuilder.git
cd Vocabuilder
flutter pub get
flutter run
```

```bash
# 构建 APK
flutter build apk --release
```

> 需要 Flutter SDK ≥ 3.44

---

## 📁 项目结构 | Project Structure

```
lib/
├── main.dart                    # 入口
├── app.dart                     # MaterialApp 主题
├── models/                      # 数据模型
├── providers/                   # 状态管理
├── services/                    # 服务层 (DB, AI, 导入导出)
├── screens/
│   ├── home_screen.dart         # 首页导航
│   ├── learn/                   # 学习 (导入/闪卡/测验)
│   ├── wordbook/                # 单词本管理
│   ├── stats/                   # 统计面板
│   └── settings/                # 设置
├── widgets/                     # 通用组件
└── utils/                       # 工具 / 国际化
```

---

## 📄 许可证 | License

MIT © 2025 GasterMMT

---

<p align="center"><sub>Built with ❤️ using Flutter & Material Design 3</sub></p>
