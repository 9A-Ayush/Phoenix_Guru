# Phoenix Guru — Flutter Education App

A full-stack Flutter education platform for teachers and students, featuring live quizzes, class management, test creation, and real-time leaderboards.

**Stack:** Flutter · Provider · Firebase (Auth + Firestore + Storage) · Google Sign-In · Google Fonts · Material Symbols · flutter_animate

---

## Project Structure

```
lib/
├── main.dart                              # App entry, ChangeNotifierProvider setup
├── core/
│   ├── models.dart                        # All data models including LiveSession, LiveParticipant, LiveAnswer
│   ├── providers/
│   │   └── app_state.dart                 # Central ChangeNotifier — auth, data, live session ops
│   ├── services/
│   │   └── quiz_service.dart              # Isolated Firestore logic for live quiz sessions
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
    │       ├── join_live_quiz_screen.dart # PIN entry → real Firestore session lookup
    │       ├── live_quiz_screens.dart     # ABCD answer cards · Leaderboard (podium)
    │       └── quiz_screens.dart          # TestAttempt · TestResult · QuizResultsList
    └── teacher/
        └── screens/
            ├── teacher_shell.dart             # Dashboard · Classes · Tests · Quiz · Profile
            ├── create_class_screen.dart       # Subject dropdown, description, Firestore save
            ├── create_test_screen.dart        # Question builder, date+time picker, allowed attempts
            ├── edit_test_screen.dart          # Edit name, questions, expiry → Firestore
            ├── class_detail_screen.dart       # Real-time students/tests tabs, multi-select remove
            ├── live_session_lobby_screen.dart # PIN display, live participant grid, start button
            ├── live_quiz_host_screen.dart     # Real-time answer distribution via live_answers stream
            ├── test_results_screen.dart       # Live Firestore scores, grade bars, flagged Qs
            ├── edit_profile_screen.dart       # Name edit → Firestore update
            ├── change_password_screen.dart    # Re-auth + Firebase Auth password update
            ├── notifications_screen.dart      # Toggle prefs → Firestore notificationPrefs
            └── help_support_screen.dart       # FAQ accordion + contact cards
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
     ├── QuizService (isolated Firestore service)
     │     ├── startSession() / endSession() / nextQuestion()
     │     ├── joinSession() / submitAnswer()
     │     └── sessionStream() / participantsStream() / answersForQuestion()
     │
     └── Provider.of<AppState> → Screens → Widgets
```

- **State Management:** Provider (`ChangeNotifier`) + `ValueNotifier` for selection UI
- **Navigation:** Flutter Navigator 1.0 (`MaterialPageRoute`)
- **Backend:** Firebase — Auth, Firestore, Storage
- **Live Quiz:** Dedicated `live_sessions` + `participants` + `live_answers` collections
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
| `removeStudent(classId, studentId)` | Removes one student → `arrayRemove` |
| `removeStudents(classId, studentIds)` | Batch-removes multiple students in one write |
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

### Live Sessions
| Method | Description |
|---|---|
| `startLiveSession(test)` | Creates `live_sessions/{id}` doc with auto-generated PIN |
| `updateLiveSession(sessionId, currentQuestion, status)` | Advances question or changes status |
| `liveSessionStream(sessionId)` | Real-time stream of session document |
| `findSessionByPin(pin)` | Finds active session by 6-digit PIN |
| `liveAttemptsStream(testId)` | Real-time stream of all attempts for a test |

### QuizService (lib/core/services/quiz_service.dart)
| Method | Description |
|---|---|
| `startSession(test, hostId, hostName)` | Creates session in `live_sessions` |
| `nextQuestion(sessionId, index)` | Advances to next question, sets status=active |
| `showResult(sessionId)` | Sets status=showingResult |
| `endSession(sessionId)` | Sets status=ended |
| `toggleLock(sessionId, locked)` | Locks/unlocks room for new joins |
| `kickParticipant(sessionId, userId)` | Removes participant from subcollection |
| `joinSession(sessionId, userId, name, initials)` | Adds participant doc, increments count |
| `submitAnswer(...)` | Saves answer, updates participant score in batch |
| `sessionStream(sessionId)` | Real-time session doc stream |
| `participantsStream(sessionId)` | Real-time participants ordered by score |
| `answersForQuestion(sessionId, questionIndex)` | Real-time answers for current question |

---

## Firestore Collections

| Collection | Document Key | Description |
|---|---|---|
| `users` | `{uid}` | User profile — name, email, role, createdAt, notificationPrefs |
| `classes` | `{classId}` | Class — teacherId, classCode, studentIds, subject, description |
| `tests` | `{testId}` | Test — questions, duration, classId, isLive, expiresAt, maxAttempts |
| `attempts` | `{attemptId}` | Quiz attempt — userId, answers map, completedAt |
| `live_sessions` | `{sessionId}` | Live session — hostId, pin, currentQuestion, status, participantCount |
| `live_sessions/{id}/participants` | `{userId}` | Participant — score, rank, answeredCount, correctCount |
| `live_answers` | `{answerId}` | Answer — sessionId, participantId, questionIndex, isCorrect, pointsEarned, responseMs |

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
| `ClassModel` | id, name, subject, description, teacherId, classCode, studentIds, createdAt |
| `TestModel` | id, title, classId, questions, durationMinutes, isLive, expiresAt, maxAttempts, pin |
| `QuizQuestion` | id, question, options[4], correctIndex |
| `QuizAttempt` | id, testId, userId, userName, answers (Map), completedAt |
| `LiveSession` | id, testId, hostId, pin, currentQuestion, status, participantCount, isLocked |
| `LiveParticipant` | id, sessionId, name, avatarInitials, score, rank, answeredCount, correctCount |
| `LiveAnswer` | id, sessionId, participantId, questionId, questionIndex, selectedIndex, isCorrect, pointsEarned, responseMs |

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
| 10 | Join Live Quiz | Real PIN lookup → Firestore session validation |
| 11 | Live Quiz ABCD | Colorful answer cards, countdown timer |
| 12 | Test Taking | Progress bar, MCQ, anti-cheat banner |
| 13 | Profile | Stats, menu rows, quiz history |
| 14 | Quiz Leaderboard | Podium UI (1st/2nd/3rd) |
| 15 | Quiz Results List | Grade badges, progress bars, real Firestore data |

### Teacher Module
| # | Screen | Notes |
|---|---|---|
| T01 | Dashboard | Quick actions, stats, class list |
| T02 | Classes | List with subject icons, tap → detail |
| T03 | Tests | Cards with status badges, three-dot menu |
| T04 | Live Quiz | Test picker → creates session → lobby |
| T05 | Profile | Stats, gradient avatar + Teacher badge |
| T06 | Class Detail | Real-time students/tests tabs, multi-select remove students |
| T07 | Create Class | Subject dropdown, description, auto class code |
| T08 | Create Test | Question builder, date+time picker, allowed attempts (1/2) |
| T09 | Edit Test | Edit name, add/remove/edit questions, extend expiry |
| T10 | Live Session Lobby | PIN display, live participant grid, lock room, start button |
| T11 | Live Quiz Host | Real-time answer distribution from `live_answers` stream |
| T12 | Test Results | Live Firestore scores, grade bars, flagged questions |
| T13 | Edit Profile | Name edit → Firestore save |
| T14 | Change Password | Re-auth + Firebase Auth update |
| T15 | Notifications | 5 toggles → Firestore `notificationPrefs` |
| T16 | Help & Support | FAQ accordion (7 items) + contact cards |

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
| `qr_flutter` | ^4.1.0 | QR code generation |
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

### Create / Edit / Delete Class
- Create: `CreateClassScreen` → `AppState.createClass()` → Firestore `classes/{id}`
- Edit: `ClassDetailScreen` three-dot → `updateClass()` → Firestore
- Delete: three-dot → `deleteClass()` (batch: class + all tests) → Firestore

### Remove Students (Multi-select)
`ClassDetailScreen` three-dot → "Remove Students" → selection mode → `removeStudents(classId, ids)` → `arrayRemove` batch → Firestore

### Create / Edit / Delete Test
- Create: `CreateTestScreen` → `AppState.createTest()` → Firestore `tests/{id}`
- Edit: `EditTestScreen` → `updateTest()` + `extendTestExpiry()` → Firestore
- Delete: three-dot → `deleteTest()` (batch: test + all attempts) → Firestore

### Join Class (Student)
`_JoinClassSheet` → `AppState.joinClass(code)` → Firestore query by `classCode` → `arrayUnion` on `studentIds`

### Live Quiz — Teacher Flow
```
TeacherQuizPage → _pickTest() → AppState.startLiveSession(test)
  → creates live_sessions/{id} with 6-digit PIN
  → LiveSessionLobbyScreen (shows PIN, participant grid)
  → teacher taps Start → QuizService.nextQuestion(sessionId, 0)
  → TeacherLiveQuizScreen (streams live_answers per question)
  → Reveal Answer → QuizService.showResult()
  → Next → QuizService.nextQuestion() ... repeat
  → Finish → QuizService.endSession()
```

### Live Quiz — Student Flow
```
JoinLiveQuizScreen → enter 6-digit PIN
  → QuizService.findSessionByPin(pin) → validates session
  → QuizService.joinSession() → creates participants/{userId} doc
  → LiveQuizAbcdScreen (streams session for question sync)
  → tap answer → QuizService.submitAnswer() → live_answers/{id}
  → score computed: 500–1000 pts based on speed
  → QuizLeaderboardScreen (streams participants ordered by score)
```

### Test Results
`TeacherTestResultsScreen` → `attemptsForTest()` → scores from `QuizAttempt.score()` → flagged questions auto-detected (>50% wrong)
