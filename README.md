# StudyVault - Flutter Edition

A 100% Native, Offline-First Mobile Application for Exam Preparation, Bilingual & Indic PDF Notes, Gemini AI Quizzes, and Focused Study Tracking.

---

## 🚀 Key Advantages Over WebView PDF Readers

- **100% Native Indic / Hindi PDF Rendering**: Powered by Google Pdfium via `syncfusion_flutter_pdfviewer`. All embedded custom TrueType/OpenType subset fonts (including Kruti Dev, Devlys, Chanakya, Mangal, and PUA glyphs) render with pixel-perfect native fidelity — **zero tofu boxes (`▯▯▯`)**.
- **Gemini AI Integration**: Connects to Google Gemini API (`gemini-1.5-flash` / `gemini-1.5-pro`) to automatically generate multiple-choice quizzes directly from study notes or chapter topics.
- **Question Bank & Quiz Runner**: Create manual questions, take timed quizzes, instant scoring, and detailed review with explanations.
- **Safe Study Mode**: Toggle to hide/show delete buttons across exams, categories, and PDF notes to prevent accidental deletion during study sessions.
- **Focus Study & Custom Pomodoro**: Built-in floating and in-app Pomodoro timer with customizable work and break intervals.
- **Mark as Complete & Reading Progress**: Remembers page position, total pages, and allows 1-tap marking of completed study notes.
- **Offline SQLite Storage**: All exams, categories, questions, and quiz histories are stored in local SQLite databases (`sqflite`).

---

## 📂 Architecture

```
lib/
├── database/
│   ├── app_database.dart       # SQLite database initialization & migrations
│   ├── category_repo.dart      # Category & Subcategory queries
│   ├── exam_repo.dart          # Exam queries
│   ├── pdf_repo.dart           # PDF document & progress queries
│   └── quiz_repo.dart          # Question bank & quiz result queries
├── models/
│   ├── category.dart           # Category data model
│   ├── exam.dart               # Exam data model
│   ├── pdf_document.dart       # PDF document data model
│   ├── question.dart           # Quiz Question data model
│   └── quiz_result.dart        # Quiz Scorecard data model
├── providers/
│   ├── pomodoro_provider.dart  # Focus timer state management
│   ├── settings_provider.dart  # AI, Safe Mode & Theme state management
│   └── study_provider.dart     # Study materials & exam state management
├── screens/
│   ├── category_detail_screen.dart # Subcategories & PDF list
│   ├── home_screen.dart        # Dual-tab dashboard (Study & Assessment)
│   ├── pdf_reader_screen.dart  # Native high-performance PDF viewer
│   ├── quiz_runner_screen.dart # Interactive quiz interface with timer
│   ├── quiz_scorecard_screen.dart # Detailed score review & explanations
│   └── settings_screen.dart    # AI configuration, Safe Mode toggle
├── services/
│   ├── gemini_service.dart     # Gemini REST API quiz generator & key tester
│   └── pdf_storage_service.dart# File picker & document storage
├── widgets/
│   ├── ai_quiz_modal.dart      # Modal to prompt Gemini AI
│   ├── pomodoro_widget.dart    # In-app focus timer widget
│   └── question_modal.dart     # Manual question creator
└── main.dart                   # Application entry & Material 3 theming
```

---

## 🛠️ How to Run & Build

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run on Connected Android Device or Emulator
```bash
flutter run
```

### 3. Build Release Android APK
```bash
flutter build apk --release
```
The output APK will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`
