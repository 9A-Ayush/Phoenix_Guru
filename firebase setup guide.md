Firebase Setup Prompt for Phoenix Guru
1. Project Context
I have a Flutter education app called Phoenix Guru with:


Student + Teacher roles (Provider state management)


Auth: login, signup, forgot password (all in AppState)


Firestore collections: users, classes, tests, attempts


Real-time live quiz (snapshots), offline support needed


Firebase Storage for study material file uploads



2. pubspec.yaml Packages
Add these dependencies:
firebase_core: ^2.27.0cloud_firestore: ^4.17.0firebase_auth: ^4.20.0firebase_storage: ^11.7.0
Run:
flutter pub get

3. Firebase Console Setup Prompt
Go to console.firebase.google.com → Create project → Enable these services for Phoenix Guru Flutter app:AuthenticationEnable Email/Password providerFirestore DatabaseCreate in production mode, choose regionStorageEnable for study material uploads

4. google-services.json Setup Prompt
In Firebase Console → Project Settings → Your Apps → Add Android app.Package name:com.phoenixguru.appDownload google-services.json.Place it at:android/app/google-services.json
For iOS:
Download GoogleService-Info.plist → place in ios/Runner/

5. Full Firebase Integration Prompt
Replace the in-memory AppState in Phoenix Guru Flutter app with real Firebase.Replace login() with firebase_auth signInWithEmailAndPassword.Replace signUp() with createUserWithEmailAndPassword + store role in Firestore users collection.Replace createClass() with a Firestore add() to /classes.Replace joinClass() with Firestore update to add studentId.Replace submitAttempt() with Firestore add() to /attempts.Replace allTests with a Firestore stream from /tests.Use StreamBuilder for real-time quiz updates.Keep Provider pattern, just swap data sources.

6. Firestore Security Rules Prompt
Write Firestore security rules for Phoenix Guru:- teachers can read/write their own classes and tests- students can read classes they are enrolled in- any authenticated user can write to /attempts- users can only read/write their own /users document

Quick Reference


firebase_core must be initialized in main.dart before runApp()


Use FirebaseAuth.instance.currentUser to check login state on app start


Wrap live quiz StreamBuilder in your existing TeacherLiveQuizScreen widget


Store userRole (student/teacher) in Firestore users/{uid}.role


Never hardcode API keys — google-services.json is auto-read by Firebase SDK

