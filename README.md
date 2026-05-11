# Phoenix Guru — Flutter Education App

A full-stack Flutter education platform for teachers and students, featuring live quizzes, class management, test creation, and real-time leaderboards.

**Stack:** Flutter · Provider · Firebase (Auth + Firestore + Storage) · Google Sign-In · Google Fonts · Material Symbols · flutter_animate

---

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── models.dart                        # All data models
│   ├── providers/
│   │   └── app_state.dart                 # Central ChangeNotifier — auth, data, Firestore ops
│   ├── services/
│   │   ├── quiz_service.dart              # Isolated Firestore logic for live quiz sessions
│   │   └── rate_limiter.dart              # In-memory client-side rate limiter (singleton)
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
    │       ├── splash_screen.dart
    │       ├── login_screen.dart          # Email/password + Google Sign-In
    │       ├── signup_screen.dart         # Name/email/password/role + Google Sign-In
    │       ├── role_picker_screen.dart    # Google new-user role selection
    │       └── forgot_password_screen.dart
    ├── student/
    │   ├── screens/
    │   │   └── student_shell.dart         # Dashboard · Classes · Material · Quiz · Profile
    │   └── quiz/
    │       ├── join_live_quiz_screen.dart # PIN entry → real Firestore session lookup
    │       ├── live_quiz_screens.dart     # ABCD answer cards · Leaderboard (podium)
    │       └── quiz_screens.dart          # TestAttempt · TestResult · QuizResultsList
    └── teacher/
        └── screens/
            ├── teacher_shell.dart
            ├── create_class_screen.dart
            ├── create_test_screen.dart    # Question builder, date+time picker, allowed attempts
            ├── create_quiz_screen.dart    # Lightweight live quiz builder (no class/expiry)
            ├── edit_test_screen.dart
            ├── class_detail_screen.dart   # Real-time students/tests tabs, multi-select remove
            ├── live_session_lobby_screen.dart # PIN + QR display, participant grid
            ├── live_quiz_host_screen.dart # Real-time answer distribution
            ├── test_results_screen.dart
            ├── edit_profile_screen.dart
            ├── change_password_screen.dart
            ├── notifications_screen.dart
            └── help_support_screen.dart
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
     │     ├── /attempts/{attemptId}
     │     ├── /live_sessions/{sessionId}
     │     │     └── /participants/{userId}
     │     └── /live_answers/{answerId}
     │
     ├── QuizService — isolated live quiz Firestore ops
     ├── RateLimiter — in-memory singleton, no external deps
     │
     └── Provider.of<AppState> → Screens → Widgets
```

---

## Rate Limiting

All rate limits are client-side (in-memory, resets on app restart). Server-side enforcement via Firestore security rules.

### Both Roles
| Action | Limit | Block Duration |
|---|---|---|
| Login | 3 fails / 10 min | 30 min |
| Sign Up | 2 / 1 hr | 1 hr |
| Forgot Password | 2 / 1 hr | 1 hr |
| Update Profile | 2 / 1 hr | 1 hr |
| Change Password | 2 / 1 hr | 1 hr |
| Join Class | 3 / 5 min | 15 min |
| Notifications save | 3s debounce | — |

### Teacher Only
| Action | Limit | Type |
|---|---|---|
| Create Class | Max 5 per teacher | Hard cap |
| Create Test | Max 20 per teacher | Hard cap |
| Questions per test/quiz | Max 30 | Hard cap |
| Start Live Session | 1 active at a time | Hard block |

### Student Only
| Action | Limit | Type |
|---|---|---|
| Submit Test Attempt | `maxAttempts` field | Hard cap |
| PIN Lookup | 3 / 1 min | 10 min block |
| Join Session | 5 / 5 min | 10 min block |
| Submit Answer | Max 30 / session | Hard cap |

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
| `createClass(name, subject, desc)` | Creates class (max 5 per teacher) |
| `updateClass(classId, name, subject, desc)` | Updates class fields |
| `deleteClass(classId)` | Batch-deletes class + all its tests |
| `joinClass(code)` | Student joins via code → `arrayUnion` on `studentIds` |
| `removeStudent(classId, studentId)` | Removes one student |
| `removeStudents(classId, studentIds)` | Batch-removes multiple students |
| `classStream(classId)` | Real-time stream of a single class document |
| `fetchUser(uid)` | One-time fetch of a user profile by UID |

### Tests & Attempts
| Method | Description |
|---|---|
| `createTest(...)` | Creates test (max 20/teacher, max 30 questions) |
| `updateTest(testId, title, questions)` | Updates test title and questions |
| `extendTestExpiry(testId, newExpiry)` | Updates expiresAt |
| `toggleTestPublish(testId, isLive)` | Toggles isLive |
| `deleteTest(testId)` | Batch-deletes test + all its attempts |
| `submitAttempt(testId, testTitle, answers)` | Saves attempt (enforces maxAttempts) |
| `testsForClass(classId)` | Filtered getter from streamed tests |
| `attemptsForTest(testId)` | Filtered getter from streamed attempts |

### Live Sessions
| Method | Description |
|---|---|
| `startLiveSession(test)` | Creates `live_sessions/{id}` with auto-generated PIN |
| `updateLiveSession(sessionId, ...)` | Advances question or changes status |
| `liveSessionStream(sessionId)` | Real-time stream of session document |
| `findSessionByPin(pin)` | Finds active session by 6-digit PIN |

### QuizService
| Method | Description |
|---|---|
| `startSession(test, hostId, hostName)` | Creates session (1 active per host) |
| `nextQuestion / showResult / endSession` | Host controls |
| `toggleLock / kickParticipant` | Room management |
| `joinSession(sessionId, userId, ...)` | Adds participant doc |
| `submitAnswer(...)` | Saves answer + updates score (max 30/session) |
| `sessionStream / participantsStream / answersForQuestion` | Real-time streams |

---

## Firestore Collections

| Collection | Key | Description |
|---|---|---|
| `users` | `{uid}` | Profile — name, email, role, createdAt, notificationPrefs |
| `classes` | `{classId}` | Class — teacherId, classCode, studentIds |
| `tests` | `{testId}` | Test — questions (max 30), duration, expiresAt, maxAttempts |
| `attempts` | `{attemptId}` | Quiz attempt — userId, answers map, completedAt |
| `live_sessions` | `{sessionId}` | Session — hostId, pin, currentQuestion, status |
| `live_sessions/{id}/participants` | `{userId}` | Score, rank, answeredCount |
| `live_answers` | `{answerId}` | Answer — isCorrect, pointsEarned, responseMs |

### Scoring Formula
```
isCorrect = selectedIndex == correctIndex
speedFactor = 1 - (responseMs / (timerSeconds * 1000))
points = isCorrect ? (500 + 500 * speedFactor).round() : 0
// Range: 500–1000 pts for correct, 0 for wrong
```

---

## Data Models

| Model | Key Fields |
|---|---|
| `UserModel` | id, name, email, role, createdAt, avatarInitials |
| `ClassModel` | id, name, subject, teacherId, classCode, studentIds |
| `TestModel` | id, title, classId, questions (max 30), durationMinutes, isLive, expiresAt, maxAttempts |
| `QuizQuestion` | id, question, options[4], correctIndex |
| `QuizAttempt` | id, testId, userId, answers (Map), completedAt |
| `LiveSession` | id, testId, hostId, pin, currentQuestion, status, participantCount, isLocked |
| `LiveParticipant` | id, sessionId, name, score, rank, answeredCount, correctCount |
| `LiveAnswer` | id, sessionId, participantId, questionIndex, isCorrect, pointsEarned, responseMs |

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
| Calendar selection | `#5B2FD4` |
| Font | Poppins (main) · Inter (labels) |

---

## Screens

### Auth
| # | Screen | Notes |
|---|---|---|
| 01 | Splash | Logo animation, auth-aware routing |
| 02 | Login | Email/password + Google Sign-In |
| 03 | Sign Up | Name/email/password/role + Google Sign-In |
| 04 | Role Picker | Google new-user only |
| 05 | Forgot Password | Firebase reset email |

### Student Module
| # | Screen | Notes |
|---|---|---|
| 06 | Dashboard | Live quiz banner, stats, classes |
| 07 | My Classes | List + join class sheet (6-digit OTP) |
| 08 | Study Material | Filter tabs, files |
| 09 | Tests | Upcoming/done tabs |
| 10 | Join Live Quiz | Real PIN → Firestore session lookup |
| 11 | Live Quiz ABCD | Answer cards, countdown timer |
| 12 | Test Taking | Progress bar, MCQ, anti-cheat |
| 13 | Profile | Stats, Edit Profile, Change Password, Notifications, Help |
| 14 | Quiz Leaderboard | Podium UI |
| 15 | Quiz Results List | Grade badges, real Firestore data |

### Teacher Module
| # | Screen | Notes |
|---|---|---|
| T01 | Dashboard | Quick actions, stats |
| T02 | Classes | Subject icons, tap → detail |
| T03 | Tests | Cards with status, three-dot menu |
| T04 | Live Quiz | Create Quiz + Start from Test |
| T05 | Profile | Stats, gradient avatar + Teacher badge |
| T06 | Class Detail | Real-time students/tests, multi-select remove |
| T07 | Create Class | Subject dropdown, auto class code (max 5) |
| T08 | Create Test | Question builder, date+time picker, attempts (max 30 Qs) |
| T09 | Create Quiz | Lightweight live quiz builder (max 30 Qs) |
| T10 | Edit Test | Edit name, questions, expiry |
| T11 | Live Session Lobby | PIN + QR, participant grid, lock room |
| T12 | Live Quiz Host | Real-time answer distribution |
| T13 | Test Results | Live Firestore scores, flagged questions |
| T14 | Edit Profile | Name edit → Firestore |
| T15 | Change Password | Re-auth + Firebase Auth update |
| T16 | Notifications | 5 toggles → Firestore (3s debounce) |
| T17 | Help & Support | FAQ accordion + contact cards |

---

## Setup

### Prerequisites
- Flutter 3.22+ · Dart 3.3+
- Firebase project with Firestore, Auth, Storage enabled

### Install & Run
```bash
flutter pub get
flutter run
```

### Firebase Setup
1. Create project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** → Email/Password + Google
3. Enable **Firestore Database** (production mode)
4. Enable **Firebase Storage**
5. Add `google-services.json` → `android/app/` *(gitignored — keep local)*
6. Add `GoogleService-Info.plist` → `ios/Runner/` *(gitignored — keep local)*
7. Register Android SHA-1 in Firebase Console → Project Settings
8. Deploy rules and indexes:
```bash
firebase deploy --only firestore --project <your-project-id>
```

> **Security:** `google-services.json` and `GoogleService-Info.plist` are gitignored.
> Never commit them to a public repository.

### Dependencies

| Package | Version | Purpose |
|---|---|---|
| `firebase_core` | ^2.27.0 | Firebase initialization |
| `firebase_auth` | ^4.20.0 | Email/Password + Google auth |
| `cloud_firestore` | ^4.17.0 | Real-time database |
| `firebase_storage` | ^11.7.0 | File uploads |
| `google_sign_in` | ^6.2.1 | Google OAuth |
| `qr_flutter` | ^4.1.0 | QR code generation |
| `provider` | ^6.1.2 | State management |
| `google_fonts` | ^6.2.1 | Poppins / Inter |
| `flutter_animate` | ^4.5.0 | Animations |
| `material_symbols_icons` | ^4.2792.2 | Icon set |
| `uuid` | ^4.4.2 | ID generation |
| `intl` | ^0.19.0 | Date formatting |

---

## Key Flows

### Live Quiz — Teacher
```
TeacherQuizPage
  ├── Create New Quiz → CreateQuizScreen (title + timer + questions, max 30)
  │     → LiveSessionLobbyScreen (PIN + QR + participant grid)
  │     → TeacherLiveQuizScreen (real-time answer distribution)
  │
  └── Start from Test → _TestPickerSheet → LiveSessionLobbyScreen → TeacherLiveQuizScreen
```

### Live Quiz — Student
```
JoinLiveQuizScreen → enter 6-digit PIN (rate limited: 3/min → 10min block)
  → QuizService.findSessionByPin() → validates session
  → QuizService.joinSession() → creates participants/{userId}
  → LiveQuizAbcdScreen (streams session for question sync)
  → tap answer → QuizService.submitAnswer() (max 30/session, 1/question)
  → score: 500–1000 pts based on speed
  → QuizLeaderboardScreen
```

### Auth Flows
```
Splash → authenticated → Shell
       → needsRolePicker → RolePickerScreen → Shell
       → unauthenticated → LoginScreen

Login → email/password → role check → Shell
     → Google → new user → RolePickerScreen → Shell
     → Google → returning → Shell
```

### Class Management
- Create: `createClass()` → Firestore (max 5/teacher)
- Edit/Delete: three-dot menu → `updateClass()` / `deleteClass()` (batch)
- Remove Students: multi-select → `removeStudents()` → `arrayRemove`

### Test Management
- Create: `createTest()` → Firestore (max 20/teacher, max 30 questions)
- Edit: `EditTestScreen` → `updateTest()` + `extendTestExpiry()`
- Delete: three-dot → `deleteTest()` (batch: test + attempts)
- Publish/Unpublish: `toggleTestPublish()`
