# Phoenix Guru — Setup Guide

## Prerequisites

- Flutter SDK 3.22+ (stable)
- Dart 3.3+
- Android Studio / Xcode
- VS Code (recommended)

## Quick Start

```bash
# 1. Extract zip
unzip phoenix_guru_flutter.zip
cd phoenix_guru

# 2. Get dependencies
flutter pub get

# 3. Run on device/emulator
flutter run

# 4. Run on specific platform
flutter run -d android
flutter run -d ios
flutter run -d chrome    # web
```

## Project Structure

```
phoenix_guru/
├── lib/
│   ├── main.dart                                 ← Entry point
│   ├── core/
│   │   ├── models.dart                           ← Data models
│   │   ├── providers/app_state.dart              ← State management
│   │   └── theme/app_theme.dart                  ← Colors + theme
│   ├── shared/widgets/widgets.dart               ← Shared UI components
│   └── features/
│       ├── auth/screens/
│       │   ├── splash_screen.dart
│       │   ├── login_screen.dart
│       │   ├── signup_screen.dart
│       │   └── forgot_password_screen.dart
│       ├── student/
│       │   ├── screens/student_shell.dart         ← Student tab navigator
│       │   └── quiz/
│       │       ├── quiz_screens.dart              ← Test attempt + results
│       │       ├── live_quiz_screens.dart         ← ABCD + Leaderboard
│       │       └── join_live_quiz_screen.dart     ← PIN entry
│       └── teacher/screens/
│           ├── teacher_shell.dart                 ← Teacher tab navigator
│           ├── create_class_screen.dart           ← T06
│           ├── create_test_screen.dart            ← T03
│           ├── class_detail_screen.dart           ← T02
│           ├── live_quiz_host_screen.dart         ← T04
│           └── test_results_screen.dart           ← T05
├── android/                                      ← Android platform
├── ios/                                          ← iOS platform
└── test/widget_test.dart
```

## All 22 Screens

| # | Screen | File |
|---|--------|------|
| 01 | Splash | auth/screens/splash_screen.dart |
| 02 | Login | auth/screens/login_screen.dart |
| 03 | Sign Up | auth/screens/signup_screen.dart |
| 04 | Forgot Password | auth/screens/forgot_password_screen.dart |
| 05 | Student Dashboard | student/screens/student_shell.dart |
| 06 | My Classes | student/screens/student_shell.dart |
| 07 | Join Class (bottom sheet) | student/screens/student_shell.dart |
| 08 | Study Material | student/screens/student_shell.dart |
| 09 | Upcoming Tests | student/screens/student_shell.dart |
| 10 | Join Live Quiz (PIN) | student/quiz/join_live_quiz_screen.dart |
| 11 | Live Quiz ABCD | student/quiz/live_quiz_screens.dart |
| 12 | Test Attempt | student/quiz/quiz_screens.dart |
| 13 | Student Profile | student/screens/student_shell.dart |
| 14 | Quiz Leaderboard | student/quiz/live_quiz_screens.dart |
| 15 | Quiz Results List | student/quiz/quiz_screens.dart |
| T01 | Teacher Dashboard | teacher/screens/teacher_shell.dart |
| T02 | Class Detail | teacher/screens/class_detail_screen.dart |
| T03 | Create Test | teacher/screens/create_test_screen.dart |
| T04 | Live Quiz Host | teacher/screens/live_quiz_host_screen.dart |
| T05 | Test Results | teacher/screens/test_results_screen.dart |
| T06 | Create Class | teacher/screens/create_class_screen.dart |
| T07 | Teacher Profile | teacher/screens/teacher_shell.dart |

## Test Login Credentials

| Role | Email | Password |
|------|-------|----------|
| Student | student@test.com | password |
| Teacher | teacher@test.com | password |

> Any email with @ and password ≥ 6 chars will work.

## State Management

Uses **Provider** (ChangeNotifier) via `AppState`:
- `login()` / `signUp()` / `logout()` — auth
- `createClass()` / `joinClass()` — class operations  
- `createTest()` — test creation
- `submitAttempt()` — quiz submission

All data is in-memory and **backend-ready** — replace `Future.delayed` with real API calls.

## Design Tokens (from MCP)

```dart
AppColors.bg         // #0A0A1A
AppColors.surface    // #13132B
AppColors.primary    // #6C47FF
AppColors.success    // #22C55E
AppColors.warning    // #FBBF24
AppColors.error      // #EF4444
AppColors.accent     // #FF6B6B
```

## Adding Backend

Replace in `lib/core/providers/app_state.dart`:
```dart
// Replace this:
await Future.delayed(const Duration(milliseconds: 800));

// With your API call:
final response = await http.post(Uri.parse('https://api.yourserver.com/login'), ...);
```
