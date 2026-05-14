import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';
import '../services/rate_limiter.dart';
import '../services/material_cache_service.dart';

const _uuid = Uuid();

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
  List<StudentPayment> _payments = [];
  StreamSubscription? _classesSub;
  StreamSubscription? _testsSub;
  StreamSubscription? _attemptsSub;
  StreamSubscription? _paymentsSub;

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
  
  List<StudentPayment> get allPayments => List.unmodifiable(_payments);
  StudentPayment? getStudentPayment(String studentId) {
    try {
      return _payments.firstWhere((p) => p.studentId == studentId);
    } catch (e) {
      return null;
    }
  }

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
          
          // Validate material cache on app start
          _validateMaterialCache();
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
      // Sign-out event — only reset if we're not mid-Google-flow and haven't
      // already been cleared by logout().
      if (_authStatus != AuthStatus.needsRolePicker &&
          _authStatus != AuthStatus.unauthenticated) {
        // Cancel streams FIRST before clearing auth state to avoid
        // PERMISSION_DENIED warnings from final Firestore snapshots.
        _cancelStreams();
        _currentUser = null;
        _authStatus = AuthStatus.unauthenticated;
        _classes.clear();
        _tests.clear();
        _attempts.clear();
        _payments.clear();
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
    
    _initPaymentStream();
  }

  void _cancelStreams() {
    _classesSub?.cancel();
    _testsSub?.cancel();
    _attemptsSub?.cancel();
    _paymentsSub?.cancel();
    _classesSub = null;
    _testsSub = null;
    _attemptsSub = null;
    _paymentsSub = null;
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<String?> login(String email, String password, UserRole role) async {
    _isLoading = true; notifyListeners();
    final rl = RateLimiter.instance;
    final blocked = rl.check(
      'login:$email',
      maxAttempts: 3,
      window: const Duration(minutes: 10),
      blockDuration: const Duration(minutes: 30),
    );
    if (blocked != null) {
      _isLoading = false; notifyListeners();
      return blocked;
    }
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
      rl.reset('login:$email');
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
    final rl = RateLimiter.instance;
    final blocked = rl.check(
      'signup:$email',
      maxAttempts: 2,
      window: const Duration(hours: 1),
      blockDuration: const Duration(hours: 1),
    );
    if (blocked != null) {
      _isLoading = false; notifyListeners();
      return blocked;
    }
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
    final rl = RateLimiter.instance;
    final blocked = rl.check(
      'forgot:$email',
      maxAttempts: 2,
      window: const Duration(hours: 1),
      blockDuration: const Duration(hours: 1),
    );
    if (blocked != null) return blocked;
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

      // Rate limit by Google email — 4 sign-in/sign-out cycles per hour
      final rl = RateLimiter.instance;
      final blocked = rl.check(
        'google_signin:${googleUser.email}',
        maxAttempts: 4,
        window: const Duration(hours: 1),
        blockDuration: const Duration(hours: 1),
      );
      if (blocked != null) {
        await _googleSignIn.signOut();
        _isLoading = false; notifyListeners();
        return blocked;
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
    // Cancel streams FIRST before invalidating the auth token.
    // This prevents the PERMISSION_DENIED warnings that occur when
    // Firestore fires a final snapshot after the auth token is cleared.
    _cancelStreams();

    // Clear local state immediately so no stale data is visible.
    _currentUser = null;
    _authStatus = AuthStatus.unauthenticated;
    _classes.clear();
    _tests.clear();
    _attempts.clear();
    _payments.clear();

    // Reset Google sign-in rate limit on clean logout.
    if (_currentUser != null) {
      RateLimiter.instance.reset('google_signin:${_currentUser!.email}');
    }

    // Now sign out of Firebase — auth token is invalidated after streams are gone.
    await _googleSignIn.signOut();
    await _auth.signOut();

    notifyListeners();
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
    final rl = RateLimiter.instance;
    final blocked = rl.check(
      'profile:${_currentUser?.id}',
      maxAttempts: 2,
      window: const Duration(hours: 1),
      blockDuration: const Duration(hours: 1),
    );
    if (blocked != null) return blocked;
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

  /// Uploads a profile photo to Cloudinary and saves the URL to Firestore.
  Future<String?> updateProfilePhoto(Uint8List imageBytes, String fileName) async {
    if (_currentUser == null) return 'Not logged in';
    try {
      const cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME',
          defaultValue: 'dwv7xyucs');
      const uploadPreset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET',
          defaultValue: 'phoenix_guru_materials');

      // Read from .env via flutter_dotenv if available
      final envCloudName = _getEnvValue('CLOUDINARY_CLOUD_NAME') ?? cloudName;
      final envPreset = _getEnvValue('CLOUDINARY_UPLOAD_PRESET') ?? uploadPreset;

      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$envCloudName/image/upload');

      // Determine image mime type
      final ext = fileName.split('.').last.toLowerCase();
      final mimeSubtype = (ext == 'jpg') ? 'jpeg' : ext;

      // Build multipart request — no overwrite/public_id (requires signed upload)
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = envPreset
        ..fields['folder'] = 'phoenix_guru/profile_photos'
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'profile_${_currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.$ext',
          contentType: MediaType('image', mimeSubtype),
        ));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        return 'Upload failed: $body';
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final photoUrl = json['secure_url'] as String;

      // Save URL to Firestore
      await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .update({'photoUrl': photoUrl});

      _currentUser = _currentUser!.copyWith(photoUrl: photoUrl);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  String? _getEnvValue(String key) {
    try {
      // flutter_dotenv stores values in dotenv.env map
      return dotenv.env[key];
    } catch (_) {
      return null;
    }
  }

  /// Re-authenticates then changes the Firebase Auth password.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null || firebaseUser.email == null) return 'Not logged in';
    // Rate limit: 2 attempts per hour
    final rl = RateLimiter.instance;
    final blocked = rl.check(
      'changepass:${firebaseUser.uid}',
      maxAttempts: 2,
      window: const Duration(hours: 1),
      blockDuration: const Duration(hours: 1),
    );
    if (blocked != null) return blocked;
    try {
      final cred = EmailAuthProvider.credential(
        email: firebaseUser.email!,
        password: currentPassword,
      );
      await firebaseUser.reauthenticateWithCredential(cred);
      await firebaseUser.updatePassword(newPassword);
      rl.reset('changepass:${firebaseUser.uid}');
      return null;
    } catch (e) {
      return _friendlyAuthError(e);
    }
  }

  // ── Classes ───────────────────────────────────────────────────────────────

  Future<ClassModel> createClass({required String name, required String subject, required String description}) async {
    _isLoading = true; notifyListeners();
    final existingCount = _classes.where((c) => c.teacherId == _currentUser!.id).length;
    if (existingCount >= 5) {
      _isLoading = false; notifyListeners();
      throw Exception('Class limit reached. Maximum 5 classes per teacher.');
    }
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
            : null)
        .asBroadcastStream();
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

  /// Fetches all unique students across all of the teacher's classes.
  /// Returns a list of (UserModel, ClassModel) pairs — one entry per
  /// student-class combination so the teacher can track per-class fees.
  Future<List<({UserModel student, ClassModel cls})>> fetchStudentsForTeacher() async {
    final teacherClasses = myClasses; // already filtered to this teacher
    if (teacherClasses.isEmpty) return [];

    // Collect all unique student IDs
    final allIds = <String>{};
    for (final cls in teacherClasses) {
      allIds.addAll(cls.studentIds);
    }
    if (allIds.isEmpty) return [];

    // Batch-fetch user profiles (Firestore 'in' supports up to 30 per query)
    final idList = allIds.toList();
    final Map<String, UserModel> userMap = {};
    for (int i = 0; i < idList.length; i += 30) {
      final chunk = idList.sublist(i, (i + 30).clamp(0, idList.length));
      final snap = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        final u = UserModel.fromMap(doc.data());
        userMap[u.id] = u;
      }
    }

    // Build result: one entry per student per class
    final result = <({UserModel student, ClassModel cls})>[];
    for (final cls in teacherClasses) {
      for (final sid in cls.studentIds) {
        final user = userMap[sid];
        if (user != null) result.add((student: user, cls: cls));
      }
    }
    return result;
  }

  Future<String?> joinClass(String code) async {
    final rl = RateLimiter.instance;
    final userId = _currentUser?.id ?? 'anon';
    final blocked = rl.check(
      'joinclass:$userId',
      maxAttempts: 3,
      window: const Duration(minutes: 5),
      blockDuration: const Duration(minutes: 15),
    );
    if (blocked != null) return blocked;
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

  // ── Live Sessions ─────────────────────────────────────────────────────────

  /// Generates a random 6-digit PIN not already in use.
  Future<String> _generateUniquePin() async {
    final rand = DateTime.now().microsecondsSinceEpoch;
    String pin;
    int attempts = 0;
    do {
      final n = (rand + attempts * 7919) % 1000000;
      pin = n.toString().padLeft(6, '0');
      final existing = await _firestore
          .collection('live_sessions')
          .where('pin', isEqualTo: pin)
          .where('status', whereIn: [
            LiveSessionStatus.waiting.name,
            LiveSessionStatus.active.name,
            LiveSessionStatus.showingResult.name,
          ])
          .get();
      if (existing.docs.isEmpty) break;
      attempts++;
    } while (attempts < 20);
    return pin;
  }

  /// Creates a live session in Firestore and returns it.
  Future<LiveSession?> startLiveSession(TestModel test) async {
    try {
      final pin = await _generateUniquePin();
      final session = LiveSession(
        id: _uuid.v4(),
        testId: test.id,
        testTitle: test.title,
        hostId: _currentUser!.id,
        hostName: _currentUser!.name,
        pin: pin,
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection('live_sessions')
          .doc(session.id)
          .set(session.toMap());
      return session;
    } catch (e) {
      debugPrint('startLiveSession error: $e');
      return null;
    }
  }

  /// Advances to the next question or ends the session.
  Future<void> updateLiveSession(String sessionId, {
    int? currentQuestion,
    LiveSessionStatus? status,
  }) async {
    final data = <String, dynamic>{};
    if (currentQuestion != null) data['currentQuestion'] = currentQuestion;
    if (status != null) data['status'] = status.name;
    if (data.isEmpty) return;
    await _firestore.collection('live_sessions').doc(sessionId).update(data);
  }

  /// Real-time stream of a live session document.
  Stream<LiveSession?> liveSessionStream(String sessionId) {
    return _firestore
        .collection('live_sessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) => doc.exists && doc.data() != null
            ? LiveSession.fromMap(doc.data()!)
            : null);
  }

  /// Finds an active session by PIN (for students joining).
  Future<LiveSession?> findSessionByPin(String pin) async {
    try {
      final snap = await _firestore
          .collection('live_sessions')
          .where('pin', isEqualTo: pin)
          .where('status', whereIn: [
            LiveSessionStatus.waiting.name,
            LiveSessionStatus.active.name,
            LiveSessionStatus.showingResult.name,
          ])
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return LiveSession.fromMap(snap.docs.first.data());
    } catch (e) {
      return null;
    }
  }

  /// Stream of all attempts for a live session's test (for real-time score board).
  Stream<List<QuizAttempt>> liveAttemptsStream(String testId) {
    return _firestore
        .collection('attempts')
        .where('testId', isEqualTo: testId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => QuizAttempt.fromMap(d.data()))
            .toList());
  }

  // ── Tests ─────────────────────────────────────────────────────────────────
  Future<TestModel> createTest({
    required String title,
    required String subject,
    required String classId,
    required int durationMinutes,
    required List<QuizQuestion> questions,
    DateTime? expiresAt,
    int maxAttempts = 1,
    bool isPublished = false,
  }) async {
    _isLoading = true; notifyListeners();
    if (questions.length > 30) {
      _isLoading = false; notifyListeners();
      throw Exception('Maximum 30 questions per test.');
    }
    final existingCount = _tests.where((t) =>
        _classes.any((c) => c.teacherId == _currentUser!.id && c.id == t.classId)).length;
    if (existingCount >= 20) {
      _isLoading = false; notifyListeners();
      throw Exception('Test limit reached. Maximum 20 tests per teacher.');
    }
    final cls = _classes.firstWhere((c) => c.id == classId);
    final test = TestModel(
      title: title,
      subject: subject,
      classId: classId,
      className: cls.name,
      durationMinutes: durationMinutes,
      questions: questions,
      expiresAt: expiresAt,
      maxAttempts: maxAttempts,
      isPublished: isPublished,
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

  /// Toggles isPublished on a test.
  Future<String?> toggleTestPublish(String testId, {required bool isPublished}) async {
    try {
      await _firestore.collection('tests').doc(testId).update({
        'isPublished': isPublished,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Finds a live test by its PIN.
  Future<TestModel?> findTestByPin(String pin) async {
    try {
      final snap = await _firestore
          .collection('tests')
          .where('pin', isEqualTo: pin.toUpperCase())
          .where('isLive', isEqualTo: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return TestModel.fromMap(snap.docs.first.data());
    } catch (_) {
      return null;
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
    // Check maxAttempts enforcement
    final attemptsSnap = await _firestore
        .collection('attempts')
        .where('testId', isEqualTo: testId)
        .where('userId', isEqualTo: _currentUser!.id)
        .get();
    
    final existing = attemptsSnap.docs.length;
    
    // Find the test to get maxAttempts
    final testDoc = await _firestore.collection('tests').doc(testId).get();
    if (!testDoc.exists) throw Exception('Test not found');
    final test = TestModel.fromMap(testDoc.data()!);
    
    if (existing >= test.maxAttempts) {
      throw Exception('Maximum attempts reached for this test.');
    }
    
    if (test.isExpired) {
      throw Exception('This test has expired.');
    }
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

  // ── Payment Management ────────────────────────────────────────────────────

  /// Update payment status for a student (persisted to Firestore)
  Future<void> updatePaymentStatus(String paymentId, PaymentStatus newStatus) async {
    try {
      final updateData = <String, dynamic>{
        'status': newStatus.name,
      };
      if (newStatus == PaymentStatus.paid) {
        updateData['paidDate'] = DateTime.now().toIso8601String();
      } else {
        updateData['paidDate'] = null;
      }
      await _firestore.collection('payments').doc(paymentId).update(updateData);
    } catch (e) {
      debugPrint('Error updating payment status: $e');
    }
  }

  /// Create a payment record for a student (persisted to Firestore)
  Future<void> createPayment({
    required String studentId,
    required String studentName,
    required String classId,
    required String className,
    required double amount,
    required DateTime dueDate,
    PaymentStatus status = PaymentStatus.due,
  }) async {
    try {
      final payment = StudentPayment(
        studentId: studentId,
        studentName: studentName,
        classId: classId,
        className: className,
        status: status,
        amount: amount,
        dueDate: dueDate,
      );
      await _firestore.collection('payments').doc(payment.id).set(payment.toMap());
    } catch (e) {
      debugPrint('Error creating payment: $e');
    }
  }

  /// Initialize real-time payment stream from Firestore
  void _initPaymentStream() {
    if (_currentUser == null) return;
    _paymentsSub?.cancel();

    Query query = _firestore.collection('payments');

    // Students only see their own payment record
    if (isStudent) {
      query = query.where('studentId', isEqualTo: _currentUser!.id);
    }

    _paymentsSub = query.snapshots().listen((snap) {
      _payments = snap.docs
          .map((doc) => StudentPayment.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      notifyListeners();
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MATERIAL CACHE VALIDATION
  // ─────────────────────────────────────────────────────────────────────────────

  /// Validate material cache on app start (remove invalid entries)
  Future<void> _validateMaterialCache() async {
    try {
      final cacheService = MaterialCacheService();
      await cacheService.validateCache();
      debugPrint('Material cache validated successfully');
    } catch (e) {
      debugPrint('Failed to validate material cache: $e');
    }
  }

  @override
  void dispose() {
    _cancelStreams();
    super.dispose();
  }
}