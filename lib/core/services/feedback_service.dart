import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';

/// Service for handling feedback submissions with rate limiting
class FeedbackService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _feedbacks => _db.collection('feedbacks');
  CollectionReference get _dailyTrackers => _db.collection('feedback_daily_trackers');

  /// Check if user can submit feedback today (max 3 per day)
  /// Returns remaining count if allowed, throws exception if limit reached
  Future<int> checkDailyLimit(String userId) async {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final trackerId = '${userId}_$dateKey';

    final trackerDoc = await _dailyTrackers.doc(trackerId).get();
    
    if (!trackerDoc.exists) {
      return 3; // No submissions today
    }

    final data = trackerDoc.data() as Map<String, dynamic>;
    final count = data['count'] as int? ?? 0;
    
    if (count >= 3) {
      final lastSubmission = DateTime.parse(data['lastSubmissionTime'] as String);
      final tomorrow = DateTime(today.year, today.month, today.day + 1);
      final hoursUntilReset = tomorrow.difference(DateTime.now()).inHours;
      throw Exception('Daily limit reached (3/3). You can submit again in $hoursUntilReset hours.');
    }

    return 3 - count; // Remaining submissions
  }

  /// Submit feedback and update daily tracker
  Future<FeedbackModel> submitFeedback(FeedbackModel feedback) async {
    // Check rate limit
    final remaining = await checkDailyLimit(feedback.userId);
    
    if (remaining <= 0) {
      throw Exception('Daily submission limit reached');
    }

    // Save feedback
    await _feedbacks.doc(feedback.id).set(feedback.toMap());

    // Update daily tracker
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final trackerId = '${feedback.userId}_$dateKey';

    await _dailyTrackers.doc(trackerId).set({
      'userId': feedback.userId,
      'date': dateKey,
      'count': FieldValue.increment(1),
      'lastSubmissionTime': feedback.submittedAt.toIso8601String(),
    }, SetOptions(merge: true));

    return feedback;
  }

  /// Get user's feedback history (last 30 days)
  Stream<List<FeedbackModel>> getUserFeedbacks(String userId) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    return _feedbacks
        .where('userId', isEqualTo: userId)
        .where('submittedAt', isGreaterThan: thirtyDaysAgo.toIso8601String())
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedbackModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get feedback by ID
  Future<FeedbackModel?> getFeedbackById(String feedbackId) async {
    final doc = await _feedbacks.doc(feedbackId).get();
    if (!doc.exists) return null;
    return FeedbackModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  /// Get today's submission count for a user
  Future<int> getTodaySubmissionCount(String userId) async {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final trackerId = '${userId}_$dateKey';

    final trackerDoc = await _dailyTrackers.doc(trackerId).get();
    
    if (!trackerDoc.exists) return 0;
    
    final data = trackerDoc.data() as Map<String, dynamic>;
    return data['count'] as int? ?? 0;
  }

  /// Admin: Get all feedbacks with filters
  Stream<List<FeedbackModel>> getAllFeedbacks({
    FeedbackStatus? status,
    UserRole? userRole,
    FeedbackType? type,
  }) {
    Query query = _feedbacks.orderBy('submittedAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    if (userRole != null) {
      query = query.where('userRole', isEqualTo: userRole.name);
    }
    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => FeedbackModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  /// Admin: Update feedback status and response
  Future<void> updateFeedback({
    required String feedbackId,
    FeedbackStatus? status,
    String? adminResponse,
  }) async {
    final updates = <String, dynamic>{};
    
    if (status != null) {
      updates['status'] = status.name;
    }
    if (adminResponse != null) {
      updates['adminResponse'] = adminResponse;
      updates['respondedAt'] = DateTime.now().toIso8601String();
    }

    if (updates.isNotEmpty) {
      await _feedbacks.doc(feedbackId).update(updates);
    }
  }
}
