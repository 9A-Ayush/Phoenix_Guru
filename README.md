# Phoenix Guru — Flutter Education App

A full-stack Flutter education platform for teachers and students, featuring live quizzes, class management, test creation, and real-time leaderboards.

**Stack:** Flutter · Provider · Firebase (Auth + Firestore + Storage) · Google Fonts · Material Symbols · flutter_animate

---

## Project Structure

```
lib/
├── main.dart                          # App entry, ChangeNotifierProvider setup
├── core/
│   ├── models.dart                    # UserModel, ClassModel, TestModel, QuizQuestion, QuizAttempt
│   ├── providers/
│   │   └── app_state.dart             # Central ChangeNotifier — auth, classes, tests, attempts
│   └── theme/
│       └── app_theme.dart             # AppColors + AppTheme (dark)
├── shared/
│   └── widgets/
│       └── widgets.dart               # AppInput, AppButton, GoogleSignInButton, GlowBg, ClassListTile, StatCard, etc.
└── features/
    ├── auth/
    │   └── screens/
    │       ├── splash_screen.dart     # Animated logo, auto-navigate on auth state
    │       ├── login_screen.dart      # Role selector, email/password, Google Sign-In
    │       ├── signup_screen.dart     # Full name, email, password, role, Google Sign-In
    │       ├── role_picker_screen.dart # Google new-user role selection (Student/Teacher)
    │       └── forgot_password_screen.dart
    ├── student/
    │   ├── screens/
    │   │   └── student_shell.dart     # Dashboard · Classes · Material · Quiz · Profile
    │   └── quiz/
    │       ├── live_quiz_screens.dart # Join PIN · ABCD answer cards · Leaderboard
    │       └── quiz_screens.dart      # TestAttempt · TestResult · QuizResultsList
    └── teacher/
        └── screens/
            ├── teacher_shell.dart         # Dashboard · Classes · Tests · Profile
            ├── create_class_screen.dart   # Subject dropdown, description, validation
            ├── create_test_screen.dart    # Question builder with add/edit dialog
            ├── class_detail_screen.dart   # Students · Tests · Material tabs
            ├── live_quiz_host_screen.dart # Real-time answer distribution, student list
            └── test_results_screen.dart   # Score breakdown, grade bars, flagged items
```

---

## Architecture

```
Firebase Auth (Email/Password + Google Sign-In)
     │
     ▼
  AppState (ChangeNotifier)
     │  ├── authStatus:  AuthStatus (unknown|checking|authenticated|needsRolePicker|unauthenticated)
     │  ├── currentUser: UserModel?
     │  ├── classes:     List<ClassModel>
     │  ├── tests:       List<TestModel>
     │  └── attempts:    List<QuizAttempt>
     │
     ├── Firestore real-time streams (_initStreams)
     │     ├── /users/{uid}
     │     ├── /classes
     │     ├── /tests
     │     └── /attempts
     │
     └── Provider.of<AppState> → Screens → Widgets
```

- **State Management:** Provider (`ChangeNotifier`)
- **Navigation:** Flutter Navigator 1.0 (`MaterialPageRoute`)
- **Backend:** Firebase — Auth, Firestore, Storage
- **Animations:** `flutter_animate` (fade, slide, scale, stagger)
- **Fonts:** Poppins (primary), Inter (status/labels)

---

## Firestore Collections

| Collection | Document Key | Description |
|---|---|---|
| `users` | `{uid}` | User profile — name, email, role, createdAt |
| `classes` | `{classId}` | Class info — teacherId, classCode, studentIds |
| `tests` | `{testId}` | Test — questions, duration, classId, isLive |
| `attempts` | `{attemptId}` | Quiz attempt — userId, answers, score, completedAt |

### UserModel fields
```
id          String   Firebase Auth UID
name        String   Full name
email       String   Email address
role        String   "student" | "teacher"
createdAt   String   ISO-8601 timestamp
```

---

## Data Models (`lib/core/models.dart`)

| Model | Key Fields |
|---|---|
| `UserModel` | id, name, email, role, createdAt, avatarInitials |
| `ClassModel` | id, name, subject, teacherId, classCode, studentIds, createdAt |
| `TestModel` | id, title, classId, questions, durationMinutes, isLive, scheduledAt |
| `QuizQuestion` | id, question, options\[4\], correctIndex |
| `QuizAttempt` | id, testId, userId, answers (Map), completedAt |

---

## Design Tokens

| Token | Value |
|---|---|
| Background | `#0A0A1A` |
| Surface | `#13132B` |
| Surface2 | `#1C1C3A` |
| Border | `#2A2A4A` |
| Primary | `#6C47FF` |
| Success | `#22C55E` |
| Warning | `#FBBF24` |
| Error | `#EF4444` |
| Accent | `#FF6B6B` |
| Font | Poppins (main) · Inter (labels) |

---

## Screens (22 total)

### Auth
| # | Screen | File |
|---|---|---|
| 01 | Splash — logo scale + fade | `auth/screens/splash_screen.dart` |
| 02 | Login — role selector, Google Sign-In | `auth/screens/login_screen.dart` |
| 03 | Sign Up — name/email/password + role, Google Sign-In | `auth/screens/signup_screen.dart` |
| 04 | Forgot Password — email + success state | `auth/screens/forgot_password_screen.dart` |
| 05 | Role Picker — Google new-user role selection | `auth/screens/role_picker_screen.dart` |

### Student Module
| # | Screen | File |
|---|---|---|
| 05 | Dashboard — live banner, stats, classes | `student/screens/student_shell.dart` |
| 06 | My Classes — list + join bottom sheet | `student/screens/student_shell.dart` |
| 07 | Join Class — 6-digit OTP code input | `student/screens/student_shell.dart` |
| 08 | Study Material — filter tabs, files | `student/screens/student_shell.dart` |
| 09 | Tests — upcoming / done tabs | `student/screens/student_shell.dart` |
| 10 | Join Live Quiz — PIN entry | `student/quiz/live_quiz_screens.dart` |
| 11 | Live Quiz ABCD — colorful answer cards | `student/quiz/live_quiz_screens.dart` |
| 12 | Test Taking — progress bar, MCQ | `student/quiz/quiz_screens.dart` |
| 13 | Profile — stats, menu, quiz history | `student/screens/student_shell.dart` |
| 14 | Quiz Leaderboard — podium UI | `student/quiz/live_quiz_screens.dart` |
| 15 | Quiz Results List — grade badges | `student/quiz/quiz_screens.dart` |

### Teacher Module
| # | Screen | File |
|---|---|---|
| T01 | Teacher Dashboard — quick actions, stats | `teacher/screens/teacher_shell.dart` |
| T02 | Class Detail — students/tests/material tabs | `teacher/screens/class_detail_screen.dart` |
| T03 | Create Test — question builder dialog | `teacher/screens/create_test_screen.dart` |
| T04 | Live Quiz Host — real-time answer distribution | `teacher/screens/live_quiz_host_screen.dart` |
| T05 | Test Results — scores, grade bars, flagged | `teacher/screens/test_results_screen.dart` |
| T06 | Create Class — subject dropdown, validation | `teacher/screens/create_class_screen.dart` |

---

## Setup

### Prerequisites
- Flutter 3.22+
- Dart 3.3+
- Firebase project with Firestore, Auth, and Storage enabled

### Install & Run

```bash
flutter pub get
flutter run
```

### Firebase Setup
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** (Email/Password)
3. Enable **Firestore Database** (production mode)
4. Enable **Firebase Storage**
5. Add `google-services.json` → `android/app/`
6. Add `GoogleService-Info.plist` → `ios/Runner/`
7. Deploy Firestore rules and indexes:

```bash
firebase deploy --only firestore --project <your-project-id>
```

### Dependencies

| Package | Version | Purpose |
|---|---|---|
| `firebase_core` | ^2.27.0 | Firebase initialization |
| `firebase_auth` | ^4.20.0 | Email/Password + Google authentication |
| `cloud_firestore` | ^4.17.0 | Real-time database |
| `firebase_storage` | ^11.7.0 | File uploads |
| `google_sign_in` | ^6.2.1 | Google OAuth sign-in |
| `provider` | ^6.1.2 | State management |
| `google_fonts` | ^6.2.1 | Poppins / Inter fonts |
| `flutter_animate` | ^4.5.0 | Animations |
| `material_symbols_icons` | ^4.2792.2 | Icon set |
| `go_router` | ^14.2.7 | Routing |
| `uuid` | ^4.4.2 | ID generation |
| `intl` | ^0.19.0 | Date formatting |
| `shared_preferences` | ^2.3.2 | Local storage |

---

## Key Flows

### Sign Up (Email/Password)
`SignupScreen` → `AppState.signUp()` → Firebase Auth creates user → Firestore `users/{uid}` written → `_initStreams()` starts → navigate to shell

### Login (Email/Password)
`LoginScreen` → `AppState.login()` → Firebase Auth → Firestore `users/{uid}` fetched → role validated → navigate to `TeacherShell` or `StudentShell`

### Sign In with Google — New User
`LoginScreen / SignupScreen` → `AppState.signInWithGoogle()` → Google OAuth → Firebase Auth → no Firestore doc found → `authStatus = needsRolePicker` → `RolePickerScreen` → user picks role → `AppState.saveGoogleUserRole()` → Firestore `users/{uid}` written → navigate to shell

### Sign In with Google — Returning User
`LoginScreen / SignupScreen` → `AppState.signInWithGoogle()` → Google OAuth → Firebase Auth → Firestore doc found → `authStatus = authenticated` → navigate directly to shell

### Splash Navigation
```
Splash (awaits AppState.initialized)
  ├── authenticated        → TeacherShell / StudentShell
  ├── needsRolePicker      → RolePickerScreen
  └── unauthenticated      → LoginScreen
```

### Create Class (Teacher)
`CreateClassScreen` → `AppState.createClass()` → Firestore `classes/{id}` written → real-time stream updates UI

### Join Class (Student)
`_JoinClassSheet` → `AppState.joinClass(code)` → Firestore query by `classCode` → `studentIds` array updated

### Live Quiz
Teacher starts from `TeacherLiveQuizScreen` → sets `isLive: true` on test → students join via PIN in `JoinLiveQuizScreen` → real-time Firestore sync → leaderboard on `QuizLeaderboardScreen`
