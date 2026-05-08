# Phoenix Guru — Flutter Education App

**Design Source:** Pencil.dev MCP (22 screens pixel-matched)  
**Stack:** Flutter + Provider + Google Fonts + Material Symbols + flutter_animate

---

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── models.dart              # UserModel, ClassModel, TestModel, QuizAttempt, QuizQuestion
│   ├── providers/
│   │   └── app_state.dart       # ChangeNotifier — auth, classes, tests, attempts
│   └── theme/
│       └── app_theme.dart       # AppColors + AppTheme (dark)
├── shared/widgets/
│   └── widgets.dart             # AppInput, AppButton, StatCard, Tab bars, etc.
└── features/
    ├── auth/screens/
    │   ├── splash_screen.dart
    │   ├── login_screen.dart
    │   ├── signup_screen.dart
    │   └── forgot_password_screen.dart
    ├── student/
    │   ├── screens/student_shell.dart   # Dashboard + Classes + Material + Profile
    │   └── quiz/quiz_screens.dart       # TestAttempt + TestResult + QuizResultsList
    └── teacher/screens/
        ├── teacher_shell.dart           # Dashboard + Classes + Tests + Profile
        ├── create_class_screen.dart     # T06 pixel-perfect
        ├── create_test_screen.dart      # T03
        └── class_detail_screen.dart    # T02
```

## Design Token Reference (from MCP)

| Token | Value |
|-------|-------|
| Background | `#0A0A1A` |
| Surface | `#13132B` |
| Surface2 | `#1C1C3A` |
| Border | `#2A2A4A` |
| Primary | `#6C47FF` |
| Success | `#22C55E` |
| Warning | `#FBBF24` |
| Error | `#EF4444` |
| Accent | `#FF6B6B` |
| Font | Poppins (main), Inter (status bar) |

## Setup

```bash
flutter pub get
flutter run
```

**Min Flutter:** 3.22+  
**Min Dart:** 3.3+

## Screens Implemented (22 MCP screens)

### Auth
- `01` Splash — logo scale + fade animation
- `02` Login — role selector (Student/Teacher), validation
- `03` Sign Up — full name/email/password + role
- `04` Forgot Password — email input + success state

### Student Module  
- `05` Dashboard — live quiz banner, stats, classes, upcoming tests
- `06` My Classes — list + join class bottom sheet (OTP-style code input)
- `07` Join Class — 6-digit code entry with class preview
- `08` Study Material — filter tabs, downloadable files
- `09` Tests — upcoming/done tabs
- `10` Join Live Quiz — PIN entry
- `11` Live Quiz ABCD — colorful answer cards
- `12` Test Taking — progress bar, anti-cheat banner, MCQ
- `13` Profile — stats, menu rows, quiz results
- `14` Quiz Leaderboard (podium UI)
- `15` Quiz Results List — grade badges, progress bars

### Teacher Module
- `T01` Teacher Dashboard — quick actions, stats
- `T02` Class Detail — students/tests/material tabs
- `T03` Create Test — question builder with dialog
- `T04` Live Quiz Host — answer distribution view
- `T05` Test Results — student scores, flagged items
- `T06` Create Class — **full validation, subject dropdown, description**

## Architecture

- **State Management:** Provider (ChangeNotifier)
- **Navigation:** Flutter Navigator 1.0 (MaterialPageRoute)
- **Data Layer:** In-memory AppState (backend-ready structure)
- **Animations:** flutter_animate (fade, slide, scale, stagger)
- **Clean separation:** models → providers → screens → widgets
