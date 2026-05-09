# Phoenix Guru — Flutter Education App

A full-stack Flutter education platform for teachers and students, featuring live quizzes, class management, test creation, and real-time leaderboards.

**Stack:** Flutter · Provider · Firebase (Auth + Firestore + Storage) · Google Sign-In · Google Fonts · Material Symbols · flutter_animate

---

## Project Structure

```
lib/
├── main.dart                              # App entry, ChangeNotifierProvider setup
├── core/
│   ├── models.dart                        # UserModel, ClassModel, TestModel, QuizQuestion, QuizAttempt
│   ├── providers/
│   │   └── app_state.dart                 # Central ChangeNotifier — all auth, data, Firestore ops
│   └── theme/
│       └── app_theme.dart                 # AppColors + AppTheme (dark)
├── shared/
│   └── widgets/
│       └── widgets.dart                   # AppInput, AppButton, GoogleSignInButton,
│                                          # GradientAvatar, GlowBg, ClassListTile,
│                                          # StatCard, StudentTabBar, TeacherTabBar, etc.
└── features/
    ├── auth/
    │   └── screens/
    │       ├── splash_screen.dart         # Animated logo, auth-aware navigation
    │       ├── login_screen.dart          # Email/password + Google Sign-In
    │       ├── signup_screen.dart         # Name/email/password/role + Google Sign-In
    │       ├── role_picker_screen.dart    # Google new-user role selection
    │       └── forgot_password_screen.dart
    ├── student/
    │   ├── screens/
    │   │   └── student_shell.dart         # Dashboard · Classes · Material · Quiz · Profile
    │   └── quiz/
    │       ├── live_quiz_screens.dart     # Join PIN · ABCD answer cards · Leaderboard
    │       └── quiz_screens.dart          # TestAttempt · TestResult · QuizResultsList
    └── teacher/
        └── screens/
            ├── teacher_shell.dart         # Dashboard · Classes · Tests · Quiz · Profile
            ├── create_class_screen.dart   # Subject dropdown, description, Firestore save
            ├── create_test_screen.dart    # Question builder dialog, Firestore save
            ├── class_detail_screen.dart   # Real-time students/tests/material tabs
            │                             # + three-dot menu (edit/delete class)
            ├── live_quiz_host_screen.dart # Real-time answer distribution, reveal/next
            ├── test_results_screen.dart   # Live Firestore scores, grade bars, flagged Qs
            ├── edit_profile_screen.dart   # Name edit → Firestore update
            ├── change_password_screen.dart # Re-auth + Firebase Auth password update
            ├── notifications_screen.dart  # Toggle prefs → Firestore notificationPrefs
            └── help_support_screen.dart   # FAQ accordion + contact cards
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
     │  ├── classes:     List<ClassModel>   ← real-time stream
     │  ├── tests:       List<TestModel>    ← real-time stream
     │  └── attempts:    List<QuizAttempt>  ← real-time stream
     │
     ├── Firestore collections
     │     ├── /users/{uid}
     │     ├── /classes/{classId}
     │     ├── /tests/{testId}
     │     └── /attempts/{attemptId}
     │
     └── Provider.of<AppState> → Screens → Widgets
```

- **State Management:** Provider (`ChangeNotifier`)
- **Navigation:** Flutter Navigator 1.0 (`MaterialPageRoute`)
- **Backend:** Firebase — Auth, Firestore, Storage
- **Animations:** `flutter_animate` (fade, slide, scale, stagger)
- **Fonts:** Poppins (primary), Inter (status/labels)

---

## AppState Methods

### Auth
| Method | Description |
|---|---|
| `login(email, password, role)` | Email/password sign-in with role validation |
| `signUp(name, email, password, role)` | Creates Firebase Auth user + Firestore profile |
| `signInWithGoogle()` | Google OAuth → new user gets `needsRolePicker` status |
| `saveGoogleUserRole(role)` | Writes role to Firestore after role picker |
| `forgotPassword(email)` | Sends Firebase password reset email |
| `logout()` | Signs out Firebase + Google, clears state |

### Profile
| Method | Description |
|---|---|
| `updateProfile(name)` | Updates name in Firestore `users/{uid}` |
| `changePassword(current, new)` | Re-authenticates then updates Firebase Auth password |

### Classes
| Method | Description |
|---|---|
| `createClass(name, subject, desc)` | Creates class in Firestore, auto-generates 6-digit code |
| `updateClass(classId, name, subject, desc)` | Updates class fields in Firestore |
| `deleteClass(classId)` | Batch-deletes class + all its tests from Firestore |
| `joinClass(code)` | Student joins via code → `arrayUnion` on `studentIds` |
| `removeStudent(classId, studentId)` | Teacher removes student → `arrayRemove` |
| `classStream(classId)` | Real-time stream of a single class document |
| `fetchUser(uid)` | One-time fetch of a user profile by UID |

### Tests & Attempts
| Method | Description |
|---|---|
| `createTest(title, classId, duration, questions, expiresAt, maxAttempts)` | Creates test in Firestore |
| `updateTest(testId, title, questions)` | Updates test title and questions |
| `extendTestExpiry(testId, newExpiry)` | Updates expiresAt in Firestore |
| `toggleTestPublish(testId, isLive)` | Toggles isLive (publish/unpublish) |
| `deleteTest(testId)` | Batch-deletes test + all its attempts |
| `submitAttempt(testId, testTitle, answers)` | Saves student attempt to Firestore |
| `testsForClass(classId)` | Filtered getter from streamed tests |
| `attemptsForTest(testId)` | Filtered getter from streamed attempts |

---

## Firestore Collections

| Collection | Document Key | Description |
|---|---|---|
| `users` | `{uid}` | User profile — name, email, role, createdAt, notificationPrefs |
| `classes` | `{classId}` | Class — teacherId, classCode, studentIds, subject, description |
| `tests` | `{testId}` | Test — questions, duration, classId, isLive |
| `attempts` | `{attemptId}` | Quiz attempt — userId, answers map, completedAt |

### UserModel fields
```
id                  String   Firebase Auth UID
name                String   Full name
email               String   Email address
role                String   "student" | "teacher"
createdAt           String   ISO-8601 timestamp
notificationPrefs   Map      classActivity, testReminders, studentJoins, quizResults, appUpdates
```

---

## Data Models

| Model | Key Fields |
|---|---|
| `UserModel` | id, name, email, role, createdAt, avatarInitials |
| `ClassModel` | id, name, subject, description, teacherId, classCode, studentIds, createdAt |
| `TestModel` | id, title, classId, questions, durationMinutes, isLive, scheduledAt, expiresAt, maxAttempts |
| `QuizQuestion` | id, question, options[4], correctIndex |
| `QuizAttempt` | id, testId, userId, userName, answers (Map), completedAt |

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
| Avatar gradient | `#9B7BFF → #5B2FD4` |
| Font | Poppins (main) · Inter (labels) |

---

## Screens

### Auth
| # | Screen | Notes |
|---|---|---|
| 01 | Splash | Logo animation, auth-aware routing |
| 02 | Login | Email/password + Google Sign-In button |
| 03 | Sign Up | Name/email/password/role + Google Sign-In button |
| 04 | Role Picker | Google new-user only — Student/Teacher card selection |
| 05 | Forgot Password | Email input + Firebase reset email |

### Student Module
| # | Screen | Notes |
|---|---|---|
| 06 | Dashboard | Live quiz banner, stats, classes, upcoming tests |
| 07 | My Classes | List + join class bottom sheet (6-digit OTP input) |
| 08 | Study Material | Filter tabs, downloadable files |
| 09 | Tests | Upcoming/done tabs |
| 10 | Join Live Quiz | PIN entry |
| 11 | Live Quiz ABCD | Colorful answer cards |
| 12 | Test Taking | Progress bar, MCQ |
| 13 | Profile | Stats, menu rows, quiz history |
| 14 | Quiz Leaderboard | Podium UI |
| 15 | Quiz Results List | Grade badges, progress bars |

### Teacher Module
| # | Screen | Notes |
|---|---|---|
| T01 | Dashboard | Quick actions, stats, class list |
| T02 | Classes | List with subject icons, tap → detail |
| T03 | Tests | All tests with status badges |
| T04 | Live Quiz | Start quiz, view results card |
| T05 | Profile | Stats, gradient avatar + Teacher badge |
| T06 | Class Detail | Real-time students/tests/material tabs, three-dot menu |
| T07 | Create Class | Subject dropdown, description, auto class code |
| T08 | Create Test | Question builder, date+time picker, allowed attempts (1/2) |
| T09 | Edit Test | Edit name, add/remove questions, extend expiry |
| T10 | Live Quiz Host | Real-time answer distribution, reveal/next controls |
| T11 | Test Results | Live Firestore scores, grade bars, flagged questions |
| T12 | Edit Profile | Name edit → Firestore save |
| T13 | Change Password | Re-auth + Firebase Auth update |
| T14 | Notifications | 5 toggles → Firestore `notificationPrefs` |
| T15 | Help & Support | FAQ accordion (7 items) + contact cards |

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
2. Enable **Authentication** → Email/Password + Google
3. Enable **Firestore Database** (production mode)
4. Enable **Firebase Storage**
5. Add `google-services.json` → `android/app/`
6. Add `GoogleService-Info.plist` → `ios/Runner/`
7. Register your Android SHA-1 in Firebase Console → Project Settings
8. Deploy Firestore rules and indexes:

```bash
firebase deploy --only firestore --project <your-project-id>
```

### Dependencies

| Package | Version | Purpose |
|---|---|---|
| `firebase_core` | ^2.27.0 | Firebase initialization |
| `firebase_auth` | ^4.20.0 | Email/Password + Google auth |
| `cloud_firestore` | ^4.17.0 | Real-time database |
| `firebase_storage` | ^11.7.0 | File uploads |
| `google_sign_in` | ^6.2.1 | Google OAuth |
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
`SignupScreen` → `AppState.signUp()` → Firebase Auth + Firestore `users/{uid}` → `_initStreams()` → Shell

### Login (Email/Password)
`LoginScreen` → `AppState.login()` → Firebase Auth → Firestore profile fetch → role check → Shell

### Sign In with Google — New User
`LoginScreen` → `AppState.signInWithGoogle()` → Google OAuth → no Firestore doc → `needsRolePicker` → `RolePickerScreen` → `saveGoogleUserRole()` → Firestore write → Shell

### Sign In with Google — Returning User
`LoginScreen` → `AppState.signInWithGoogle()` → Google OAuth → Firestore doc found → `authenticated` → Shell

### Splash Navigation
```
Splash (awaits AppState.initialized)
  ├── authenticated        → TeacherShell / StudentShell
  ├── needsRolePicker      → RolePickerScreen
  └── unauthenticated      → LoginScreen
```

### Create Class
`CreateClassScreen` → `AppState.createClass()` → Firestore `classes/{id}` → real-time stream updates UI

### Edit / Delete Class
`ClassDetailScreen` three-dot menu → `updateClass()` or `deleteClass()` (batch: class + tests) → Firestore

### Edit / Delete Test
`TeacherTestsPage` three-dot menu → `EditTestScreen` (name/questions/expiry) or `deleteTest()` (batch: test + attempts) or `toggleTestPublish()` or `extendTestExpiry()`

### Join Class (Student)
`_JoinClassSheet` → `AppState.joinClass(code)` → Firestore query by `classCode` → `arrayUnion` on `studentIds`

### Live Quiz
Teacher → `TeacherLiveQuizScreen` → real-time `attempts` stream → answer distribution → reveal/next
Student → `JoinLiveQuizScreen` → PIN → `LiveQuizAbcdScreen` → `submitAttempt()` → Firestore

### Test Results
`TeacherTestResultsScreen` → `attemptsForTest()` → scores computed from `QuizAttempt.score()` → flagged questions auto-detected (>50% wrong)
