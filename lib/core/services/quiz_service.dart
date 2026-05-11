import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';
import 'rate_limiter.dart';

/// Isolated service for all live quiz Firestore operations.
/// Screens call this directly via Provider or passed reference.
class QuizService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collections ───────────────────────────────────────────────────────────

  CollectionReference get _sessions   => _db.collection('live_sessions');
  CollectionReference get _answers    => _db.collection('live_answers');

  DocumentReference _sessionDoc(String id)     => _sessions.doc(id);
  CollectionReference _participants(String sid) =>
      _sessions.doc(sid).collection('participants');

  // ── PIN generation ────────────────────────────────────────────────────────

  static String generatePin() {
    final rng = Random();
    return List.generate(6, (_) => rng.nextInt(10)).join();
  }

  // ── Host: start session ───────────────────────────────────────────────────

  Future<LiveSession> startSession({
    required TestModel test,
    required String hostId,
    required String hostName,
  }) async {
    // Check if host already has an active session
    final existing = await _sessions
        .where('hostId', isEqualTo: hostId)
        .where('status', whereIn: [
          LiveSessionStatus.waiting.name,
          LiveSessionStatus.active.name,
        ])
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('You already have an active session. End it before starting a new one.');
    }
    final pin = generatePin();
    final session = LiveSession(
      id: _db.collection('live_sessions').doc().id,
      testId: test.id,
      testTitle: test.title,
      hostId: hostId,
      hostName: hostName,
      pin: pin,
      createdAt: DateTime.now(),
    );
    await _sessionDoc(session.id).set(session.toMap());
    return session;
  }

  // ── Host: advance question ────────────────────────────────────────────────

  Future<void> nextQuestion(String sessionId, int nextIndex) async {
    await _sessionDoc(sessionId).update({
      'currentQuestion': nextIndex,
      'status': LiveSessionStatus.active.name,
    });
  }

  Future<void> showResult(String sessionId) async {
    await _sessionDoc(sessionId).update({
      'status': LiveSessionStatus.showingResult.name,
    });
  }

  Future<void> endSession(String sessionId) async {
    await _sessionDoc(sessionId).update({
      'status': LiveSessionStatus.ended.name,
    });
  }

  Future<void> toggleLock(String sessionId, {required bool locked}) async {
    await _sessionDoc(sessionId).update({'isLocked': locked});
  }

  Future<void> kickParticipant(String sessionId, String userId) async {
    await _participants(sessionId).doc(userId).delete();
  }

  // ── Student: find session by PIN ──────────────────────────────────────────

  Future<LiveSession?> findSessionByPin(String pin) async {
    final rl = RateLimiter.instance;
    // Use a generic key since we may not have userId here
    final blocked = rl.check(
      'pin_lookup:$pin',
      maxAttempts: 3,
      window: const Duration(minutes: 1),
      blockDuration: const Duration(minutes: 10),
    );
    if (blocked != null) throw Exception(blocked);
    final snap = await _sessions
        .where('pin', isEqualTo: pin)
        .where('status', whereIn: [
          LiveSessionStatus.waiting.name,
          LiveSessionStatus.active.name,
          LiveSessionStatus.showingResult.name,
        ])
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return LiveSession.fromMap(snap.docs.first.data() as Map<String, dynamic>);
  }

  // ── Student: join session ─────────────────────────────────────────────────

  Future<String?> joinSession({
    required String sessionId,
    required String userId,
    required String name,
    required String avatarInitials,
  }) async {
    final rl = RateLimiter.instance;
    final blocked = rl.check(
      'join_session:$userId',
      maxAttempts: 5,
      window: const Duration(minutes: 5),
      blockDuration: const Duration(minutes: 10),
    );
    if (blocked != null) return blocked;
    try {
      final sessionSnap = await _sessionDoc(sessionId).get();
      if (!sessionSnap.exists) return 'Session not found';
      final session = LiveSession.fromMap(
          sessionSnap.data() as Map<String, dynamic>);
      if (session.isLocked) return 'Room is locked by the host';
      if (session.isEnded)  return 'This session has ended';

      final participant = LiveParticipant(
        id: userId,
        sessionId: sessionId,
        name: name,
        avatarInitials: avatarInitials,
        joinedAt: DateTime.now(),
      );
      await _participants(sessionId).doc(userId).set(participant.toMap());

      // Increment participant count
      await _sessionDoc(sessionId)
          .update({'participantCount': FieldValue.increment(1)});
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Student: submit answer ────────────────────────────────────────────────

  /// Returns error string or null on success.
  Future<String?> submitAnswer({
    required String sessionId,
    required String participantId,
    required String questionId,
    required int questionIndex,
    required int selectedIndex,
    required int correctIndex,
    required int responseMs,
    required int timerSeconds, // total time allowed
  }) async {
    try {
      // Count total answers by this participant in this session
      final totalAnswers = await _answers
          .where('sessionId', isEqualTo: sessionId)
          .where('participantId', isEqualTo: participantId)
          .count()
          .get();
      if (totalAnswers.count != null && totalAnswers.count! >= 15) {
        return 'Answer limit reached for this session.';
      }

      // Prevent duplicate answers for same question
      final existing = await _answers
          .where('sessionId', isEqualTo: sessionId)
          .where('participantId', isEqualTo: participantId)
          .where('questionIndex', isEqualTo: questionIndex)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) return null; // already answered

      final isCorrect = selectedIndex == correctIndex;

      // Speed bonus: faster = more points (max 1000, min 500 for correct)
      int points = 0;
      if (isCorrect) {
        final speedFactor = 1 - (responseMs / (timerSeconds * 1000));
        points = (500 + (500 * speedFactor.clamp(0.0, 1.0))).round();
      }

      final answer = LiveAnswer(
        id: _answers.doc().id,
        sessionId: sessionId,
        participantId: participantId,
        questionId: questionId,
        questionIndex: questionIndex,
        selectedIndex: selectedIndex,
        isCorrect: isCorrect,
        pointsEarned: points,
        responseMs: responseMs,
        answeredAt: DateTime.now(),
      );

      final batch = _db.batch();

      // Save answer
      batch.set(_answers.doc(answer.id), answer.toMap());

      // Update participant score
      batch.update(_participants(sessionId).doc(participantId), {
        'score': FieldValue.increment(points),
        'answeredCount': FieldValue.increment(1),
        if (isCorrect) 'correctCount': FieldValue.increment(1),
      });

      await batch.commit();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Streams ───────────────────────────────────────────────────────────────

  Stream<LiveSession?> sessionStream(String sessionId) {
    return _sessionDoc(sessionId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return LiveSession.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  Stream<List<LiveParticipant>> participantsStream(String sessionId) {
    return _participants(sessionId)
        .orderBy('score', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => LiveParticipant.fromMap(d.data() as Map<String, dynamic>))
            .toList());
  }

  /// Stream of answers for a specific question in a session.
  Stream<List<LiveAnswer>> answersForQuestion(
      String sessionId, int questionIndex) {
    return _answers
        .where('sessionId', isEqualTo: sessionId)
        .where('questionIndex', isEqualTo: questionIndex)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => LiveAnswer.fromMap(d.data() as Map<String, dynamic>))
            .toList());
  }

  /// One-time fetch of participant's answer for a question.
  Future<LiveAnswer?> myAnswer({
    required String sessionId,
    required String participantId,
    required int questionIndex,
  }) async {
    final snap = await _answers
        .where('sessionId', isEqualTo: sessionId)
        .where('participantId', isEqualTo: participantId)
        .where('questionIndex', isEqualTo: questionIndex)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return LiveAnswer.fromMap(snap.docs.first.data() as Map<String, dynamic>);
  }
}
