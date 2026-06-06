# Vocabuilder / 单词本

[English](#english) | [中文](#chinese)

---

## English

An intelligent vocabulary learning Android app built with Jetpack Compose and Material 3. Features AI-powered word extraction, spaced repetition flashcards, and comprehensive quiz modes.

### Features

- **Word Management** — Add, edit, search, and organize words by categories and custom word books
- **Flashcard Review** — SM-2 spaced repetition algorithm with swipe-to-flip cards and 4-level rating
- **Quiz Mode** — Auto-generated multiple-choice quizzes with instant feedback
- **AI Import** — Paste text or select .md/.txt files; AI extracts vocabulary with definitions, POS, and bilingual example sentences via OpenAI-compatible APIs
- **Word Books** — Create/manage word books, export/import as JSON, batch multi-select operations
- **Statistics** — Learning progress, accuracy, 7-day review chart, study time tracking
- **Material 3 Design** — Dynamic color, dark/light themes, smooth animations
- **Bilingual Support** — English + Chinese, switch language in Settings

### Setup

1. Clone and open in Android Studio
2. Sync Gradle
3. Configure an LLM API in **App Menu → LLM Configuration** (OpenAI-compatible endpoint)
4. Build & run

### Tech Stack

- **Kotlin** + **Jetpack Compose**
- **Material 3** (Dynamic Color, Modal Drawer, AnimatedContent)
- **Room** (SQLite persistence)
- **DataStore** (preferences)
- **OkHttp** (LLM API calls)
- **Navigation Compose**

### APK

Download the latest release: [Vocabuilder-v1.0.apk](Vocabuilder-v1.0.apk)

### License

MIT

---

## 中文

一款基于 Jetpack Compose 和 Material 3 的智能背单词 Android 应用。支持 AI 单词提取、间隔重复闪卡、多模式测验。

### 功能

- **单词管理** — 添加、编辑、搜索，按分类和自定义单词本整理
- **闪卡复习** — SM-2 间隔重复算法，支持滑动翻卡和四级评分
- **测验模式** — 自动生成选择题，即时反馈
- **AI 导入** — 粘贴文本或选择 .md/.txt 文件，AI 通过 OpenAI 兼容 API 自动提取单词、词性、释义和双语例句
- **单词本** — 创建/管理单词本，JSON 导出/导入，批量多选操作
- **学习统计** — 学习进度、正确率、7 日复习图表、学习时间追踪
- **Material 3 设计** — 动态取色、亮/暗主题、流畅动画
- **双语支持** — 中英文界面，设置中切换

### 环境配置

1. 克隆项目，用 Android Studio 打开
2. 同步 Gradle
3. 在 **应用菜单 → LLM 配置** 中填写 API 信息（兼容 OpenAI 接口即可）
4. 编译运行

### 技术栈

- **Kotlin** + **Jetpack Compose**
- **Material 3**（动态取色、抽屉导航、过渡动画）
- **Room**（SQLite 持久化）
- **DataStore**（偏好设置）
- **OkHttp**（LLM API 调用）
- **Navigation Compose**

### 安装包

下载最新版本：[Vocabuilder-v1.0.apk](Vocabuilder-v1.0.apk)

### 开源协议

MIT
