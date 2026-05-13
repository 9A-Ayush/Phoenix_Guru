import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models.dart';

/// Service for handling feedback submissions with rate limiting.
/// Saves to Firestore AND sends to email via Web3Forms API.
class FeedbackService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const _web3FormsUrl = 'https://api.web3forms.com/submit';

  CollectionReference get _feedbacks => _db.collection('feedbacks');
  CollectionReference get _dailyTrackers => _db.collection('feedback_daily_trackers');

  String get _web3FormsKey => dotenv.env['WEB3FORMS_ACCESS_KEY'] ?? '';

  /// Check if user can submit feedback today (max 3 per day).
  /// Returns remaining count if allowed, throws exception if limit reached.
  Future<int> checkDailyLimit(String userId) async {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final trackerId = '${userId}_$dateKey';

    final trackerDoc = await _dailyTrackers.doc(trackerId).get();

    if (!trackerDoc.exists) return 3;

    final data = trackerDoc.data() as Map<String, dynamic>;
    final count = data['count'] as int? ?? 0;

    if (count >= 3) {
      final tomorrow = DateTime(today.year, today.month, today.day + 1);
      final hoursUntilReset = tomorrow.difference(DateTime.now()).inHours;
      throw Exception(
          'Daily limit reached (3/3). You can submit again in $hoursUntilReset hours.');
    }

    return 3 - count;
  }

  /// Submit feedback — saves to Firestore and sends email via Web3Forms.
  Future<FeedbackModel> submitFeedback(FeedbackModel feedback) async {
    // 1. Check rate limit
    await checkDailyLimit(feedback.userId);

    // 2. Save to Firestore
    await _feedbacks.doc(feedback.id).set(feedback.toMap());

    // 3. Send email via Web3Forms (fire-and-forget, don't block on failure)
    _sendViaWeb3Forms(feedback);

    // 4. Update daily tracker
    final today = DateTime.now();
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final trackerId = '${feedback.userId}_$dateKey';

    await _dailyTrackers.doc(trackerId).set({
      'userId': feedback.userId,
      'date': dateKey,
      'count': FieldValue.increment(1),
      'lastSubmissionTime': feedback.submittedAt.toIso8601String(),
    }, SetOptions(merge: true));

    return feedback;
  }

  /// POST feedback to Web3Forms API so it arrives in your email inbox.
  Future<void> _sendViaWeb3Forms(FeedbackModel feedback) async {
    if (_web3FormsKey.isEmpty || _web3FormsKey == 'your_web3forms_access_key_here') {
      return; // Skip if key not configured
    }

    try {
      final response = await http.post(
        Uri.parse(_web3FormsUrl),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'access_key': _web3FormsKey,
          'subject': '[Phoenix Guru] ${feedback.typeLabel}: ${feedback.subject}',
          'from_name': '${feedback.userName} (${feedback.userRole.name})',
          'name': feedback.userName,
          'email': 'noreply@phoenixguru.app',
          'message': feedback.description,
          'ticket_id': feedback.id.substring(0, 8).toUpperCase(),
          'type': feedback.typeLabel,
          'category': feedback.category ?? 'Not specified',
          'priority': feedback.priority?.name ?? 'Not specified',
          'user_role': feedback.userRole.name,
          'user_id': feedback.userId,
          'submitted_at': feedback.submittedAt.toIso8601String(),
          'botcheck': '', // honeypot field — must be empty
        }),
      );

      if (response.statusCode != 200) {
        // Log silently — Firestore save already succeeded
        final body = jsonDecode(response.body);
        assert(() {
          // ignore: avoid_print
          print('Web3Forms warning: ${body['message']}');
          return true;
        }());
      }
    } catch (_) {
      // Network error — Firestore save already succeeded, ignore silently
    }
  }

  /// Get user's feedback history (last 30 days).
  Stream<List<FeedbackModel>> getUserFeedbacks(String userId) {
    final thirtyDaysAgo =
        DateTime.now().subtract(const Duration(days: 30));

    return _feedbacks
        .where('userId', isEqualTo: userId)
        .where('submittedAt',
            isGreaterThan: thirtyDaysAgo.toIso8601String())
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                FeedbackModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Get today's submission count for a user.
  Future<int> getTodaySubmissionCount(String userId) async {
    final today = DateTime.now();
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final trackerId = '${userId}_$dateKey';

    final trackerDoc = await _dailyTrackers.doc(trackerId).get();
    if (!trackerDoc.exists) return 0;

    final data = trackerDoc.data() as Map<String, dynamic>;
    return data['count'] as int? ?? 0;
  }

  /// Admin: Get all feedbacks with optional filters.
  Stream<List<FeedbackModel>> getAllFeedbacks({
    FeedbackStatus? status,
    UserRole? userRole,
    FeedbackType? type,
  }) {
    Query query = _feedbacks.orderBy('submittedAt', descending: true);

    if (status != null) query = query.where('status', isEqualTo: status.name);
    if (userRole != null) query = query.where('userRole', isEqualTo: userRole.name);
    if (type != null) query = query.where('type', isEqualTo: type.name);

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) =>
            FeedbackModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  /// Admin: Update feedback status and/or response.
  Future<void> updateFeedback({
    required String feedbackId,
    FeedbackStatus? status,
    String? adminResponse,
  }) async {
    final updates = <String, dynamic>{};

    if (status != null) updates['status'] = status.name;
    if (adminResponse != null) {
      updates['adminResponse'] = adminResponse;
      updates['respondedAt'] = DateTime.now().toIso8601String();
    }

    if (updates.isNotEmpty) {
      await _feedbacks.doc(feedbackId).update(updates);
    }
  }
}
