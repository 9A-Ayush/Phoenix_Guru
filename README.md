# Phoenix Guru — Flutter Education App

A full-stack Flutter education platform for teachers and students, featuring live quizzes, class management, test creation, and real-time leaderboards.

**Stack:** Flutter · Provider · Firebase (Auth + Firestore) · Cloudinary · Google Sign-In · Google Fonts · Material Symbols · flutter_animate

---

## 🎉 Teacher Role Status: READY TO GO! ✅

The teacher module is fully functional and production-ready with all core features implemented:
- ✅ Dashboard with real-time stats
- ✅ Class management (create, edit, delete, student management)
- ✅ Test creation and management (with edit/delete capabilities)
- ✅ Live quiz hosting with real-time leaderboards
- ✅ Material upload system (Cloudinary integration)
- ✅ Test results and analytics
- ✅ Active session monitoring
- ✅ Profile management
- ✅ Notifications system
- ✅ Help & Support with feedback form

### 🚀 Future Updates for Teacher Role

#### High Priority
- [ ] **Analytics Dashboard** — Visual charts for class performance, student trends, test difficulty analysis
- [ ] **Question Bank** — Save and reuse questions, tag by topic/difficulty, quick test creation
- [ ] **Student Management Dashboard** — View all students, individual performance tracking, progress reports
- [ ] **Bulk Operations** — Import students via CSV, bulk test assignments, mass notifications
- [ ] **Communication Tools** — Direct messaging, class announcements, email notifications

#### Medium Priority
- [ ] **Scheduling System** — Calendar view, recurring tests, deadline reminders, auto-publishing
- [ ] **Advanced Grading** — Custom rubrics, partial credit, bonus points, grade curves
- [ ] **Content Library** — Saved materials repository, template tests, resource sharing
- [ ] **Class Insights** — Difficult questions identification, time analytics, engagement metrics
- [ ] **Export & Reports** — PDF/CSV export, performance reports, attendance tracking

#### Low Priority
- [ ] **Collaboration Features** — Co-teacher management, teacher notes, internal chat
- [ ] **Settings & Preferences** — Theme customization, default settings, language selection
- [ ] **Achievements System** — Teaching milestones, badges, activity streaks
- [ ] **Backup & Sync** — Data backup, restore functionality, cloud sync

---

## Recent Changes

### May 13, 2026 (Latest)
- **Teacher Dashboard Improvements**:
  - Fixed "Start Quiz" button to navigate to CreateQuizScreen
  - Removed Teacher badge, added "T" badge on avatar for cleaner UI
  - Made "See All" button functional (navigates to Classes tab)
  - Added "Upload Material" option to teacher profile page
- **Change Password Screen Removed** — Unnecessary for Google Sign-In users and users who forgot password should use "Forgot Password" on login screen
- **Material Upload Screen Enhancements**:
  - Removed double borders from all input fields
  - Icons and placeholders stay visible in input fields
  - Added 200 character limit to description with inline counter
  - Description field auto-expands (1-3 lines) based on content
  - Entire upload zone is now tappable (removed separate browse button)
  - Upload zone expanded to full width (220px height)
  - Changed Image type icon from video camera to proper image icon
- **Storage Limits Display** — Updated functions/index.js to show limits in MB/GB instead of bytes for better readability

### May 13, 2026 (Earlier)
- **Feedback & Support System** — W3-compliant feedback form for both teachers and students:
  - Submit bug reports, feature requests, and general feedback
  - Rate limiting: 3 submissions per day per user
  - Real-time submission counter showing remaining submissions
  - Form validation with character limits (subject: 100, description: 1000)
  - Optional fields: category, priority level
  - Success dialog with ticket ID for tracking
  - Separate help & support screens for teachers and students
  - Firestore security rules for feedback collection and daily trackers
  - Accessible form design with proper ARIA labels and keyboard navigation
- **Material Management** — Full CRUD operations for materials:
  - Edit material metadata (name, subject, description, URL for links)
  - Delete materials with confirmation dialog
  - Open materials in external browser (PDF, images, docs, links)
  - Edit/delete buttons on each material card
- **Environment Variables** — Moved Cloudinary credentials to `.env` file using `flutter_dotenv`
  - Removed hardcoded credentials from source code
  - Added `.env.example` template for setup
  - Improved security by keeping sensitive data out of repository
- **Security Audit** — Removed unused API keys and secrets from frontend
  - Created `SECURITY.md` with security guidelines
  - Documented unsigned vs signed upload tradeoffs
  - All sensitive credentials removed from frontend code
- **Upload Progress** — Fixed progress bar showing 0% during upload
  - Shows simulated progress: 10% → 80% → 100%
  - Better UX feedback during upload process
- **Android URL Support** — Added queries to AndroidManifest.xml for url_launcher
  - Fixed "Cannot open this link" error on Android 11+
  - Materials now open correctly in external browser
- **Firestore Rules** — Updated to allow material updates
  - Teachers can now edit their class materials
  - Proper permission checks for security

### May 12, 2026
- **Cloudinary Integration** — Migrated from Firebase Storage to Cloudinary for material uploads. Uses unsigned uploads (no Firebase Functions required). 25 GB free storage, 500 MB/day per teacher rate limit. Requires unsigned upload preset `phoenix_guru_materials` in Cloudinary dashboard.
- **Material Upload Screen** — `MaterialUploadScreen` integrated into `ClassDetailScreen` Material tab. File picker with type chips (PDF/Image/Doc/Link), class selector, 20 MB limit, upload progress bar. Uses `file_picker ^8.0.0`.
- **Test Results moved to Tests tab** — "Results" button added to `TeacherTestsPage` header (green, next to "New Test"). Removed from Quiz tab.
- **Headers standardized** — All teacher screens now use the `1C1240→bg` gradient header style matching `ClassDetailScreen`.
- **Active Sessions screen** — Multi-select with "Close (N)" button in upper-right corner. Long-press for single-session close. Tap to reopen lobby.
- **Lint fix** — Removed unused `maxLines` parameter from `_AppInput` in `material_upload_screen.dart`.

---

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── models.dart                        # All data models (includes FeedbackModel)
│   ├── providers/
│   │   └── app_state.dart                 # Central ChangeNotifier — auth, data, Firestore ops
│   ├── services/
│   │   ├── cloudinary_service.dart        # Material upload/delete/edit to Cloudinary (unsigned)
│   │   ├── quiz_service.dart              # Isolated Firestore logic for live quiz sessions
│   │   ├── rate_limiter.dart              # In-memory client-side rate limiter (singleton)
│   │   └── feedback_service.dart          # Feedback submission with daily rate limiting
│   └── theme/
│       └── app_theme.dart                 # AppColors + AppTheme (dark)
├── shared/
│   └── widgets/
│       ├── widgets.dart                   # AppInput, AppButton, GoogleSignInButton,
│       │                                  # GradientAvatar, GlowBg, ClassListTile,
│       │                                  # StatCard, StudentTabBar, TeacherTabBar, etc.
│       └── feedback_form_screen.dart      # W3-compliant feedback submission form
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
    │   │   ├── student_shell.dart         # Dashboard · Classes · Material · Quiz · Profile
    │   │   └── help_support_screen.dart   # Student help & support with feedback form
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
            ├── active_sessions_screen.dart    # Active sessions list, multi-select, close
            ├── live_session_lobby_screen.dart # PIN + QR display, participant grid
            ├── live_quiz_host_screen.dart # Real-time answer distribution
            ├── test_results_screen.dart   # Grade bars, flagged questions, student scores
            ├── material_upload_screen.dart # File picker, type chips, class selector
            ├── edit_profile_screen.dart
            ├── change_password_screen.dart
            ├── notifications_screen.dart
            └── help_support_screen.dart   # Teacher help & support with feedback form
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
     │     │     └── /uploadTracker/{doc}   ← daily upload tracking
     │     ├── /classes/{classId}
     │     │     └── /materials/{materialId} ← material metadata
     │     ├── /tests/{testId}
     │     ├── /attempts/{attemptId}
     │     ├── /live_sessions/{sessionId}
     │     │     └── /participants/{userId}
     │     └── /live_answers/{answerId}
     │
     ├── CloudinaryService — unsigned uploads, quota tracking
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
| Login (email) | 3 fails / 10 min | 30 min |
| Sign Up | 2 / 1 hr | 1 hr |
| Forgot Password | 2 / 1 hr | 1 hr |
| Google Sign-In | 4 / 1 hr per email | 1 hr |
| Update Profile | 2 / 1 hr | 1 hr |
| Change Password | 2 / 1 hr | 1 hr |
| Join Class | 3 / 5 min | 15 min |
| Notifications save | 3s debounce | — |
| **Feedback Submission** | **3 / day** | **Until next day** |

### Teacher Only
| Action | Limit | Type |
|---|---|---|
| Create Class | Max 5 per teacher | Hard cap |
| Create Test | Max 20 per teacher | Hard cap |
| Questions per test/quiz | Max 30 | Hard cap |
| Start Live Session | 1 active at a time | Hard block |
| **Material Upload** | **500 MB/day** | **Client-side** |
| **Total Storage** | **25 GB** | **Cloudinary free tier** |
| **Max File Size** | **20 MB** | **Hard cap** |

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
| `users/{uid}/uploadTracker` | `daily` | Daily upload tracking — date, bytesUsed |
| `classes` | `{classId}` | Class — teacherId, classCode, studentIds |
| `classes/{classId}/materials` | `{materialId}` | Material metadata — name, url, publicId, sizeBytes |
| `tests` | `{testId}` | Test — questions (max 30), duration, expiresAt, maxAttempts |
| `attempts` | `{attemptId}` | Quiz attempt — userId, answers map, completedAt |
| `live_sessions` | `{sessionId}` | Session — hostId, pin, currentQuestion, status |
| `live_sessions/{id}/participants` | `{userId}` | Score, rank, answeredCount |
| `live_answers` | `{answerId}` | Answer — isCorrect, pointsEarned, responseMs |
| `feedbacks` | `{feedbackId}` | Feedback — userId, type, subject, description, status |
| `feedback_daily_trackers` | `{userId}_{date}` | Daily submission tracking — count, lastSubmissionTime |

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
| `FeedbackModel` | id, userId, userRole, type, subject, description, priority, category, status, submittedAt |

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
| T03 | Tests | Cards with status, three-dot menu + "Results" button |
| T04 | Live Quiz | Create Quiz + Start from Test + "Sessions" badge button |
| T05 | Profile | Stats, gradient avatar + Teacher badge |
| T06 | Class Detail | Real-time students/tests/material tabs, multi-select remove, material CRUD |
| T07 | Create Class | Subject dropdown, auto class code (max 5) |
| T08 | Create Test | Question builder, date+time picker, attempts (max 30 Qs) |
| T09 | Create Quiz | Lightweight live quiz builder (no class/expiry, max 30 Qs) |
| T10 | Edit Test | Edit name, questions, expiry |
| T11 | Live Session Lobby | PIN + QR, participant grid, lock room |
| T12 | Active Sessions | All active sessions, multi-select close (top-right), long-press single close |
| T13 | Live Quiz Host | Real-time answer distribution |
| T14 | Test Results | Live Firestore scores, grade bars, flagged questions |
| T15 | Material Upload | File picker, type chips, class selector, progress bar, link support |
| T16 | Edit Profile | Name edit → Firestore |
| T17 | Change Password | Re-auth + Firebase Auth update |
| T18 | Notifications | 5 toggles → Firestore (3s debounce) |
| T19 | Help & Support | FAQ accordion + contact cards + feedback form |

---

## Feedback & Support System

### Features
- **W3-compliant form** with proper semantic HTML and ARIA labels
- **Rate limiting**: 3 submissions per day per user (tracked in Firestore)
- **Submission types**: Bug Report, Feature Request, General Feedback
- **Form fields**:
  - Subject (required, max 100 chars)
  - Description (required, max 1000 chars)
  - Category (optional): UI/UX, Performance, Content, Authentication, Classes, Tests & Quizzes, Live Sessions, Other
  - Priority (optional): Low, Medium, High
- **Real-time counter**: Shows remaining submissions (e.g., "2/3 remaining")
- **Success dialog**: Displays ticket ID for tracking
- **Accessible design**: Keyboard navigation, screen reader support, proper focus management

### FeedbackService Methods
| Method | Description |
|---|---|
| `checkDailyLimit(userId)` | Returns remaining submissions, throws if limit reached |
| `submitFeedback(feedback)` | Saves feedback and updates daily tracker |
| `getUserFeedbacks(userId)` | Stream of user's feedback history (last 30 days) |
| `getTodaySubmissionCount(userId)` | Get today's submission count |
| `getAllFeedbacks(...)` | Admin: Stream all feedbacks with filters |
| `updateFeedback(...)` | Admin: Update status and response |

### Feedback Flow
```
Help & Support Screen
  ├── FAQ accordion (expandable questions)
  ├── Submit Feedback button (highlighted with gradient)
  │     → FeedbackFormScreen
  │           ├── Check daily limit (3/day)
  │           ├── Show submission counter
  │           ├── Fill form (type, subject, description, category, priority)
  │           ├── Validate inputs
  │           ├── Submit → FeedbackService.submitFeedback()
  │           ├── Update daily tracker
  │           └── Show success dialog with ticket ID
  │
  ├── Email Support card
  └── Live Chat card
```

### Firestore Security Rules
```javascript
// Users can read their own feedback, teachers can read all
match /feedbacks/{feedbackId} {
  allow read: if request.auth != null && (
    resource.data.userId == request.auth.uid ||
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'teacher'
  );
  allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
  allow update: if request.auth != null && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'teacher';
}

// Daily trackers for rate limiting
match /feedback_daily_trackers/{trackerId} {
  allow read: if request.auth != null && trackerId.matches('^' + request.auth.uid + '_.*');
  allow create, update: if request.auth != null && 
    trackerId.matches('^' + request.auth.uid + '_.*') &&
    request.resource.data.userId == request.auth.uid;
}
```

---

## Setup

### Prerequisites
- Flutter 3.22+ · Dart 3.3+
- Firebase project with Firestore, Auth enabled
- Cloudinary account (free tier: 25 GB storage)

### Cloudinary Setup
1. Create account at [cloudinary.com](https://cloudinary.com)
2. Go to Settings → Upload → Upload Presets
3. Create preset:
   - **Name**: `phoenix_guru_materials`
   - **Signing mode**: Unsigned
   - **Folder**: `phoenix_guru/materials`
   - **Max file size**: 20 MB
   - **Allowed formats**: pdf,doc,docx,ppt,pptx,xls,xlsx,jpg,jpeg,png,webp,mp4,mov
4. Copy your Cloud Name from Dashboard
5. Create `.env` file in project root (copy from `.env.example`):
```env
CLOUDINARY_CLOUD_NAME=your_cloud_name_here
CLOUDINARY_UPLOAD_PRESET=phoenix_guru_materials
```

### Firebase Setup
1. Create project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** → Email/Password + Google
3. Enable **Firestore Database** (production mode)
4. Add `google-services.json` → `android/app/` *(gitignored — keep local)*
5. Add `GoogleService-Info.plist` → `ios/Runner/` *(gitignored — keep local)*
6. Register Android SHA-1 in Firebase Console → Project Settings
7. Deploy rules and indexes:
```bash
firebase deploy --only firestore --project <your-project-id>
```

### Install & Run
```bash
flutter pub get
flutter run
```

### Security Notes
- `google-services.json` and `GoogleService-Info.plist` are **gitignored** — never commit to public repo
- `.env` file with Cloudinary credentials is **gitignored** — use `.env.example` as template
- Firebase API keys in those files are restricted by SHA-1 + package name — safe for mobile
- All rate limits are client-side (in-memory) — resets on app restart
- Server-side enforcement via Firestore security rules (deployed)
- Cloudinary upload preset is exposed in APK (unsigned uploads) — acceptable for MVP, consider Firebase Functions for production
- See `SECURITY.md` for detailed security guidelines and best practices

### Dependencies

| Package | Version | Purpose |
|---|---|---|
| `firebase_core` | ^2.27.0 | Firebase initialization |
| `firebase_auth` | ^4.20.0 | Email/Password + Google auth |
| `cloud_firestore` | ^4.17.0 | Real-time database |
| `google_sign_in` | ^6.2.1 | Google OAuth |
| `http` | ^1.2.0 | HTTP client for Cloudinary uploads |
| `url_launcher` | ^6.3.1 | Open materials in external browser |
| `flutter_dotenv` | ^5.1.0 | Environment variable management |
| `qr_flutter` | ^4.1.0 | QR code generation |
| `file_picker` | ^8.0.0 | File selection for material upload |
| `provider` | ^6.1.2 | State management |
| `google_fonts` | ^6.2.1 | Poppins / Inter |
| `flutter_animate` | ^4.5.0 | Animations |
| `material_symbols_icons` | ^4.2792.2 | Icon set |
| `uuid` | ^4.4.2 | ID generation |
| `intl` | ^0.19.0 | Date formatting |

---

## Cloudinary Integration

### Material Upload Flow
```
MaterialUploadScreen
  ├── Select material type (PDF/Image/Doc/Link)
  ├── For files:
  │     ├── Select file (file_picker) → max 20 MB
  │     ├── Check daily quota (500 MB/day per teacher)
  │     ├── Check total quota (25 GB across all teachers)
  │     ├── Upload to Cloudinary (unsigned preset)
  │     │     → https://api.cloudinary.com/v1_1/{cloud_name}/auto/upload
  │     │     → folder: phoenix_guru/materials
  │     │     → Progress: 10% → 80% → 100%
  │     ├── Save metadata to Firestore
  │     │     → classes/{classId}/materials/{materialId}
  │     │     → url, publicId, sizeBytes, uploadedBy, uploadedAt
  │     └── Update daily usage tracker
  │           → users/{teacherId}/uploadTracker/daily
  │
  └── For links:
        └── Save URL directly to Firestore (no Cloudinary upload)

Material Display (Class Detail → Material Tab)
  ├── List all materials with type icons (PDF/Image/Doc/Link)
  ├── Tap material → Open in external browser (url_launcher)
  ├── Edit button → Edit material sheet (name, subject, description, URL)
  └── Delete button → Confirmation dialog → Delete from Firestore
```

### CloudinaryService Methods
| Method | Description |
|---|---|
| `uploadFile(file, fileName, teacherId)` | Direct unsigned upload to Cloudinary with progress tracking |
| `saveMaterial(classId, name, ...)` | Save material metadata to Firestore |
| `saveMaterialLink(classId, name, url, ...)` | Save link material (no Cloudinary upload) |
| `deleteMaterial(classId, materialId)` | Delete material from Firestore |
| `materialsStream(classId)` | Real-time stream of materials for a class |
| `getStorageQuota(teacherId)` | Get total storage used (25 GB limit) |
| `getDailyUsage(teacherId)` | Get today's upload usage (500 MB limit) |

### Quota Tracking
- **Daily limit**: 500 MB per teacher (client-side, resets daily)
- **Total storage**: 25 GB across all teachers (Cloudinary free tier)
- **Max file size**: 20 MB per file
- **Tracking**: Firestore `users/{uid}/uploadTracker/daily` collection

### Security Notes
- Uses **unsigned uploads** (no Firebase Functions required)
- Upload preset `phoenix_guru_unsigned` is exposed in APK
- Rate limits are client-side only (can be bypassed)
- Acceptable for MVP/testing
- Consider Firebase Functions ($0-2/month) for production security

---

## Key Flows

### Live Quiz — Teacher
```
TeacherQuizPage
  ├── "Sessions" button (top-right, shows active count badge)
  │     → ActiveSessionsScreen
  │           - Tap session → LiveSessionLobbyScreen (rejoin existing)
  │           - Long press → single close bottom sheet
  │           - Tap to enter selection mode → multi-select
  │           - "Close (N)" button top-right → ends selected sessions
  │
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
