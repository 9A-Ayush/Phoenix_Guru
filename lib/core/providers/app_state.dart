import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models.dart';

class AppState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  UserModel? _currentUser;
  List<ClassModel> _classes = [];
  List<TestModel> _tests = [];
  List<QuizAttempt> _attempts = [];
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isTeacher => _currentUser?.role == UserRole.teacher;
  bool get isStudent => _currentUser?.role == UserRole.student;

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

  AppState() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          _currentUser = UserModel.fromMap(doc.data()!);
          _initStreams();
        }
      } else {
        _currentUser = null;
        _classes.clear();
        _tests.clear();
        _attempts.clear();
      }
      notifyListeners();
    });
  }

  void _initStreams() {
    // Listen to classes
    _firestore.collection('classes').snapshots().listen((snapshot) {
      _classes = snapshot.docs.map((doc) => ClassModel.fromMap(doc.data())).toList();
      notifyListeners();
    });

    // Listen to tests
    _firestore.collection('tests').snapshots().listen((snapshot) {
      _tests = snapshot.docs.map((doc) => TestModel.fromMap(doc.data())).toList();
      notifyListeners();
    });

    // Listen to attempts
    _firestore.collection('attempts').snapshots().listen((snapshot) {
      _attempts = snapshot.docs.map((doc) => QuizAttempt.fromMap(doc.data())).toList();
      notifyListeners();
    });
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<String?> login(String email, String password, UserRole role) async {
    _isLoading = true; notifyListeners();
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final doc = await _firestore.collection('users').doc(credential.user!.uid).get();
      if (!doc.exists) {
        await _auth.signOut();
        _isLoading = false; notifyListeners();
        return 'User data not found';
      }
      _currentUser = UserModel.fromMap(doc.data()!);
      if (_currentUser!.role != role) {
        await _auth.signOut();
        _isLoading = false; notifyListeners();
        return 'Incorrect role selected';
      }
      _isLoading = false; notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false; notifyListeners();
      return e.toString();
    }
  }

  Future<String?> signUp(String name, String email, String password, UserRole role) async {
    _isLoading = true; notifyListeners();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      _currentUser = UserModel(id: credential.user!.uid, name: name, email: email, role: role);
      await _firestore.collection('users').doc(credential.user!.uid).set(_currentUser!.toMap());
      _isLoading = false; notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false; notifyListeners();
      return e.toString();
    }
  }

  Future<String?> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
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
  }) async {
    _isLoading = true; notifyListeners();
    final cls = _classes.firstWhere((c) => c.id == classId);
    final test = TestModel(
      title: title,
      classId: classId,
      className: cls.name,
      durationMinutes: durationMinutes,
      questions: questions,
    );
    await _firestore.collection('tests').doc(test.id).set(test.toMap());
    _isLoading = false;
    notifyListeners();
    return test;
  }

  // ── Quiz Attempts ─────────────────────────────────────────────────────────

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
}
