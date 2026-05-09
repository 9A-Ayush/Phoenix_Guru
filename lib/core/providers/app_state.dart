import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models.dart';

/// Tracks where we are in the auth lifecycle.
/// [unknown]         → app just started, haven't checked yet
/// [checking]        → actively fetching auth state + user profile
/// [authenticated]   → user is logged in and profile is loaded
/// [needsRolePicker] → Google sign-in succeeded but no Firestore profile yet
/// [unauthenticated] → no user session
enum AuthStatus { unknown, checking, authenticated, needsRolePicker, unauthenticated }

class AppState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Auth state ────────────────────────────────────────────────────────────
  AuthStatus _authStatus = AuthStatus.unknown;
  UserModel? _currentUser;
  bool _isLoading = false; // only for data operations (create class, etc.)

  // Completer that resolves once the initial auth check is done.
  // Splash screen awaits this before navigating.
  final Completer<void> _initCompleter = Completer<void>();

  // ── Data state ────────────────────────────────────────────────────────────
  List<ClassModel> _classes = [];
  List<TestModel> _tests = [];
  List<QuizAttempt> _attempts = [];
  StreamSubscription? _classesSub;
  StreamSubscription? _testsSub;
  StreamSubscription? _attemptsSub;

  // ── Getters ───────────────────────────────────────────────────────────────
  AuthStatus get authStatus => _authStatus;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _authStatus == AuthStatus.authenticated && _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isTeacher => _currentUser?.role == UserRole.teacher;
  bool get isStudent => _currentUser?.role == UserRole.student;

  /// Exposed for screens that need direct Firestore access (e.g. student streams).
  FirebaseFirestore get firestoreInstance => _firestore;

  /// Resolves when the initial auth check is complete.
  /// Splash screen should `await` this.
  Future<void> get initialized => _initCompleter.future;

  List<ClassModel> get allClasses => List.unmodifiable(_classes);
  List<ClassModel> get myClasses {
    if (_currentUser == null) return [];
    if (isTeacher) return _classes.where((c) => c.teacherId == _currentUser!.id).toList();
    return _classes.where((c) => c.studentIds.contains(_currentUser!.id)).toList();
  }

  List<TestModel> get allTests => List.unmodifiable(_tests);
  List<TestModel> testsForClass(String classId) => _tests.where((t) => t.classId == classId).toList();
  List<QuizAttempt> get myAttempts => _currentUser == null ? [] : _attempts.where((a) => a.userId == _currentUser!.id).toList();
  List<QuizAttempt> attemptsForTest(String testId) => _attempts.where((a) => a.testId == testId).toList();

  // ── Constructor ───────────────────────────────────────────────────────────

  AppState() {
    _initialize();
  }

  /// One-time startup: check if there's already a Firebase Auth session,
  /// load the user profile, then set up ongoing listeners.
  Future<void> _initialize() async {
    _authStatus = AuthStatus.checking;
    // Don't notify yet — splash screen is awaiting the completer.

    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        // There IS an existing session — load the profile from Firestore.
        final loaded = await _loadUserProfile(firebaseUser.uid);
        if (loaded) {
          _authStatus = AuthStatus.authenticated;
          _initStreams();
        } else {
          // Profile doc missing in Firestore — sign out the orphan session.
          await _auth.signOut();
          _authStatus = AuthStatus.unauthenticated;
        }
      } else {
        _authStatus = AuthStatus.unauthenticated;
      }
    } catch (e) {
      // Network error, Firestore unavailable, etc.
      // Fail gracefully — send to login so user can retry.
      debugPrint('AppState init error: $e');
      _authStatus = AuthStatus.unauthenticated;
    }

    // Signal that init is done.
    if (!_initCompleter.isCompleted) _initCompleter.complete();
    notifyListeners();

    // Set up ongoing listener for future auth changes (logout, token refresh).
    // Skip(1) because we already handled the current state above.
    _auth.authStateChanges().skip(1).listen(_onAuthChanged);
  }

  /// Loads user profile from Firestore. Returns true if found.
  Future<bool> _loadUserProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 8));
      if (doc.exists && doc.data() != null) {
        _currentUser = UserModel.fromMap(doc.data()!);
        return true;
      }
      return false;
    } on TimeoutException {
      debugPrint('Firestore user profile fetch timed out');
      return false;
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      return false;
    }
  }

  /// Handles auth state changes AFTER initial boot (e.g. logout from another device).
  Future<void> _onAuthChanged(User? user) async {
    if (user != null) {
      // A new sign-in happened (Google or email).
      // If signInWithGoogle() or login() already set _currentUser, do nothing —
      // those methods manage their own state transitions.
      // Only act if we have a Firebase user but no app-level user loaded yet
      // AND we're not mid-Google-flow (needsRolePicker).
      if (_currentUser == null && _authStatus != AuthStatus.needsRolePicker) {
        _authStatus = AuthStatus.checking;
        notifyListeners();
        final loaded = await _loadUserProfile(user.uid);
        if (loaded) {
          _authStatus = AuthStatus.authenticated;
          _initStreams();
        } else {
          // No profile found — could be a new Google user whose role hasn't
          // been saved yet. Don't sign them out here; let the UI handle it.
          _authStatus = AuthStatus.unauthenticated;
        }
        notifyListeners();
      }
    } else {
      // Sign-out event — only reset if we're not mid-Google-flow.
      if (_authStatus != AuthStatus.needsRolePicker) {
        _currentUser = null;
        _authStatus = AuthStatus.unauthenticated;
        _cancelStreams();
        _classes.clear();
        _tests.clear();
        _attempts.clear();
        notifyListeners();
      }
    }
  }

  // ── Firestore Streams ─────────────────────────────────────────────────────

  void _initStreams() {
    _cancelStreams(); // Prevent duplicate listeners.

    _classesSub = _firestore.collection('classes').snapshots().listen((snapshot) {
      _classes = snapshot.docs.map((doc) => ClassModel.fromMap(doc.data())).toList();
      notifyListeners();
    });

    _testsSub = _firestore.collection('tests').snapshots().listen((snapshot) {
      _tests = snapshot.docs.map((doc) => TestModel.fromMap(doc.data())).toList();
      notifyListeners();
    });

    _attemptsSub = _firestore.collection('attempts').snapshots().listen((snapshot) {
      _attempts = snapshot.docs.map((doc) => QuizAttempt.fromMap(doc.data())).toList();
      notifyListeners();
    });
  }

  void _cancelStreams() {
    _classesSub?.cancel();
    _testsSub?.cancel();
    _attemptsSub?.cancel();
    _classesSub = null;
    _testsSub = null;
    _attemptsSub = null;
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<String?> login(String email, String password, UserRole role) async {
    _isLoading = true; notifyListeners();
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final loaded = await _loadUserProfile(credential.user!.uid);
      if (!loaded) {
        await _auth.signOut();
        _isLoading = false; notifyListeners();
        return 'User data not found';
      }
      if (_currentUser!.role != role) {
        _currentUser = null;
        await _auth.signOut();
        _isLoading = false; notifyListeners();
        return 'Incorrect role selected';
      }
      _authStatus = AuthStatus.authenticated;
      _initStreams();
      _isLoading = false; notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false; notifyListeners();
      return _friendlyAuthError(e);
    }
  }

  Future<String?> signUp(String name, String email, String password, UserRole role) async {
    _isLoading = true; notifyListeners();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      _currentUser = UserModel(id: credential.user!.uid, name: name, email: email, role: role);
      await _firestore.collection('users').doc(credential.user!.uid).set(_currentUser!.toMap());
      _authStatus = AuthStatus.authenticated;
      _initStreams();
      _isLoading = false; notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false; notifyListeners();
      return _friendlyAuthError(e);
    }
  }

  Future<String?> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } catch (e) {
      return _friendlyAuthError(e);
    }
  }

  /// Signs in with Google.
  /// - If the user already has a Firestore profile → authenticates normally.
  /// - If new user → sets status to [needsRolePicker] so the UI shows the role picker.
  /// Returns an error string on failure, null on success.
  Future<String?> signInWithGoogle() async {
    _isLoading = true; notifyListeners();
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the picker.
        _isLoading = false; notifyListeners();
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;

      // Check if a Firestore profile already exists.
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (doc.exists && doc.data() != null) {
        // Returning user — load profile and go straight to dashboard.
        _currentUser = UserModel.fromMap(doc.data()!);
        _authStatus = AuthStatus.authenticated;
        _initStreams();
      } else {
        // New Google user — create a partial profile (no role yet).
        // Role will be saved by saveGoogleUserRole() after role picker.
        _currentUser = UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? googleUser.displayName ?? 'User',
          email: firebaseUser.email ?? googleUser.email,
          role: UserRole.student, // placeholder, overwritten by saveGoogleUserRole
        );
        _authStatus = AuthStatus.needsRolePicker;
      }

      _isLoading = false; notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false; notifyListeners();
      return _friendlyAuthError(e);
    }
  }

  /// Called from RolePickerScreen after the user picks a role.
  /// Writes the full user document to Firestore and transitions to authenticated.
  Future<String?> saveGoogleUserRole(UserRole role) async {
    // Capture everything we need before any async gap.
    final firebaseUser = _auth.currentUser;
    final partialUser = _currentUser;

    if (firebaseUser == null || partialUser == null) {
      return 'Session expired. Please sign in again.';
    }

    try {
      final user = UserModel(
        id: firebaseUser.uid,
        name: partialUser.name,
        email: partialUser.email,
        role: role,
      );
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toMap());
      _currentUser = user;
      _authStatus = AuthStatus.authenticated;
      _initStreams();
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    _cancelStreams();
    _currentUser = null;
    _authStatus = AuthStatus.unauthenticated;
    _classes.clear();
    _tests.clear();
    _attempts.clear();
    notifyListeners();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Converts Firebase exceptions into user-friendly messages.
  String _friendlyAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found': return 'No account found with this email';
        case 'wrong-password': return 'Incorrect password';
        case 'email-already-in-use': return 'Email already registered';
        case 'weak-password': return 'Password is too weak';
        case 'invalid-email': return 'Invalid email address';
        case 'too-many-requests': return 'Too many attempts. Try again later';
        case 'network-request-failed': return 'Network error. Check your connection';
        default: return e.message ?? 'Authentication failed';
      }
    }
    return e.toString();
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  /// Updates the user's display name in Firestore and local state.
  Future<String?> updateProfile({required String name}) async {
    if (_currentUser == null || _auth.currentUser == null) return 'Not logged in';
    try {
      final updated = _currentUser!.copyWith(name: name);
      await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .update({'name': name});
      _currentUser = updated;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Re-authenticates then changes the Firebase Auth password.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null || firebaseUser.email == null) return 'Not logged in';
    try {
      // Re-authenticate first
      final cred = EmailAuthProvider.credential(
        email: firebaseUser.email!,
        password: currentPassword,
      );
      await firebaseUser.reauthenticateWithCredential(cred);
      await firebaseUser.updatePassword(newPassword);
      return null;
    } catch (e) {
      return _friendlyAuthError(e);
    }
  }

  // ── Classes ───────────────────────────────────────────────────────────────

  Future<ClassModel> createClass({required String name, required String subject, required String description}) async {
    _isLoading = true; notifyListeners();
    final cls = ClassModel(
      name: name,
      subject: subject,
      description: description,
      teacherId: _currentUser!.id,
      teacherName: _currentUser!.name,
    );
    await _firestore.collection('classes').doc(cls.id).set(cls.toMap());
    _isLoading = false;
    notifyListeners();
    return cls;
  }

  /// Removes a student from a class by updating studentIds in Firestore.
  Future<String?> removeStudent({
    required String classId,
    required String studentId,
  }) async {
    try {
      await _firestore.collection('classes').doc(classId).update({
        'studentIds': FieldValue.arrayRemove([studentId]),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Removes multiple students from a class in a single Firestore write.
  Future<String?> removeStudents({
    required String classId,
    required List<String> studentIds,
  }) async {
    try {
      await _firestore.collection('classes').doc(classId).update({
        'studentIds': FieldValue.arrayRemove(studentIds),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Updates class name, subject and description in Firestore.
  Future<String?> updateClass({
    required String classId,
    required String name,
    required String subject,
    required String description,
  }) async {
    try {
      await _firestore.collection('classes').doc(classId).update({
        'name': name,
        'subject': subject,
        'description': description,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Deletes a class and all its associated tests from Firestore.
  Future<String?> deleteClass(String classId) async {
    try {
      // Delete all tests belonging to this class
      final testSnap = await _firestore
          .collection('tests')
          .where('classId', isEqualTo: classId)
          .get();
      final batch = _firestore.batch();
      for (final doc in testSnap.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_firestore.collection('classes').doc(classId));
      await batch.commit();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Returns a real-time stream of the class document.
  Stream<ClassModel?> classStream(String classId) {
    return _firestore
        .collection('classes')
        .doc(classId)
        .snapshots()
        .map((doc) => doc.exists && doc.data() != null
            ? ClassModel.fromMap(doc.data()!)
            : null);
  }

  /// Fetches a user profile by UID from Firestore (one-time).
  Future<UserModel?> fetchUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> joinClass(String code) async {
    try {
      final query = await _firestore.collection('classes').where('classCode', isEqualTo: code.toUpperCase()).get();
      if (query.docs.isEmpty) return 'Class not found';
      
      final doc = query.docs.first;
      final cls = ClassModel.fromMap(doc.data());
      
      if (cls.studentIds.contains(_currentUser!.id)) return 'Already joined';

      await _firestore.collection('classes').doc(cls.id).update({
        'studentIds': FieldValue.arrayUnion([_currentUser!.id])
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  ClassModel? classForCode(String code) {
    try {
      return _classes.firstWhere((c) => c.classCode == code.toUpperCase());
    } catch (e) {
      return null;
    }
  }

  // ── Tests ─────────────────────────────────────────────────────────────────
  Future<TestModel> createTest({
    required String title,
    required String classId,
    required int durationMinutes,
    required List<QuizQuestion> questions,
    DateTime? expiresAt,
    int maxAttempts = 1,
  }) async {
    _isLoading = true; notifyListeners();
    final cls = _classes.firstWhere((c) => c.id == classId);
    final test = TestModel(
      title: title,
      classId: classId,
      className: cls.name,
      durationMinutes: durationMinutes,
      questions: questions,
      expiresAt: expiresAt,
      maxAttempts: maxAttempts,
    );
    await _firestore.collection('tests').doc(test.id).set(test.toMap());
    _isLoading = false;
    notifyListeners();
    return test;
  }

  // ── Quiz Attempts ─────────────────────────────────────────────────────────

  /// Updates test title and questions in Firestore.
  Future<String?> updateTest({
    required String testId,
    required String title,
    required List<QuizQuestion> questions,
  }) async {
    try {
      await _firestore.collection('tests').doc(testId).update({
        'title': title,
        'questions': questions.map((q) => q.toMap()).toList(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Extends the expiry date of a test.
  Future<String?> extendTestExpiry({
    required String testId,
    required DateTime newExpiry,
  }) async {
    try {
      await _firestore.collection('tests').doc(testId).update({
        'expiresAt': newExpiry.toIso8601String(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Toggles isLive (publish/unpublish) on a test.
  Future<String?> toggleTestPublish(String testId, {required bool isLive}) async {
    try {
      await _firestore.collection('tests').doc(testId).update({
        'isLive': isLive,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Deletes a test and all its attempts from Firestore.
  Future<String?> deleteTest(String testId) async {
    try {
      final attemptSnap = await _firestore
          .collection('attempts')
          .where('testId', isEqualTo: testId)
          .get();
      final batch = _firestore.batch();
      for (final doc in attemptSnap.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_firestore.collection('tests').doc(testId));
      await batch.commit();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<QuizAttempt> submitAttempt({
    required String testId,
    required String testTitle,
    required Map<String, int> answers,
  }) async {
    final attempt = QuizAttempt(
      testId: testId,
      testTitle: testTitle,
      userId: _currentUser!.id,
      userName: _currentUser!.name,
      answers: answers,
    );
    await _firestore.collection('attempts').doc(attempt.id).set(attempt.toMap());
    return attempt;
  }

  // ── Storage ───────────────────────────────────────────────────────────────

  Future<String?> uploadFile(String fileName, Uint8List data) async {
    try {
      final ref = _storage.ref().child('study_materials/$fileName');
      await ref.putData(data);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _cancelStreams();
    super.dispose();
  }
}
