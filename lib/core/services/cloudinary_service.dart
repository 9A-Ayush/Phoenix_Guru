import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const _totalFreeBytes = 25 * 1024 * 1024 * 1024; // 25 GB
const _dailyLimitBytes = 500 * 1024 * 1024;      // 500 MB
const _maxFileSizeBytes = 20 * 1024 * 1024;      // 20 MB

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class CloudinaryResult {
  final String url;
  final String publicId;
  final String format;
  final int bytes;

  const CloudinaryResult({
    required this.url,
    required this.publicId,
    required this.format,
    required this.bytes,
  });

  factory CloudinaryResult.fromJson(Map<String, dynamic> json) {
    return CloudinaryResult(
      url: json['secure_url'] as String,
      publicId: json['public_id'] as String,
      format: json['format'] as String,
      bytes: json['bytes'] as int,
    );
  }
}

class StorageQuota {
  final int totalBytes;
  final int usedBytes;
  final int remainingBytes;
  final double usedPercentage;

  const StorageQuota({
    required this.totalBytes,
    required this.usedBytes,
    required this.remainingBytes,
    required this.usedPercentage,
  });

  String get usedGB => (usedBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
  String get remainingGB => (remainingBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
  String get totalGB => (totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(0);

  bool get isLow => remainingBytes < 5 * 1024 * 1024 * 1024; // < 5 GB
  bool get isCritical => remainingBytes < 1 * 1024 * 1024 * 1024; // < 1 GB
}

class DailyUsage {
  final int limitBytes;
  final int usedBytes;
  final int remainingBytes;
  final double usedPercentage;
  final String date;

  const DailyUsage({
    required this.limitBytes,
    required this.usedBytes,
    required this.remainingBytes,
    required this.usedPercentage,
    required this.date,
  });

  String get usedMB => (usedBytes / (1024 * 1024)).toStringAsFixed(0);
  String get remainingMB => (remainingBytes / (1024 * 1024)).toStringAsFixed(0);
  String get limitMB => (limitBytes / (1024 * 1024)).toStringAsFixed(0);

  bool get isExceeded => usedBytes >= limitBytes;
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class CloudinaryService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // TODO: Replace with your Firebase Functions URL after deployment
  static const _functionsBaseUrl = 'https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net';

  CloudinaryService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ───────────────────────────────────────────────────────────────────────────
  // QUOTA & USAGE TRACKING
  // ───────────────────────────────────────────────────────────────────────────

  /// Get total storage used across all classes for this teacher
  Future<StorageQuota> getStorageQuota(String teacherId) async {
    try {
      // Get all classes for this teacher
      final classesSnap = await _firestore
          .collection('classes')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      int totalUsed = 0;

      // Sum all material sizes across all classes
      for (final classDoc in classesSnap.docs) {
        final materialsSnap = await _firestore
            .collection('classes')
            .doc(classDoc.id)
            .collection('materials')
            .get();

        for (final materialDoc in materialsSnap.docs) {
          totalUsed += (materialDoc.data()['sizeBytes'] as int? ?? 0);
        }
      }

      final remaining = _totalFreeBytes - totalUsed;
      final percentage = totalUsed / _totalFreeBytes;

      return StorageQuota(
        totalBytes: _totalFreeBytes,
        usedBytes: totalUsed,
        remainingBytes: remaining.clamp(0, _totalFreeBytes),
        usedPercentage: percentage.clamp(0.0, 1.0),
      );
    } catch (e) {
      // On error, return empty quota
      return const StorageQuota(
        totalBytes: _totalFreeBytes,
        usedBytes: 0,
        remainingBytes: _totalFreeBytes,
        usedPercentage: 0.0,
      );
    }
  }

  /// Get today's upload usage for this teacher
  Future<DailyUsage> getDailyUsage(String teacherId) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final doc = await _firestore
          .collection('users')
          .doc(teacherId)
          .collection('uploadTracker')
          .doc('daily')
          .get();

      final data = doc.data();

      // Reset if new day or no data
      if (data == null || data['date'] != today) {
        return DailyUsage(
          limitBytes: _dailyLimitBytes,
          usedBytes: 0,
          remainingBytes: _dailyLimitBytes,
          usedPercentage: 0.0,
          date: today,
        );
      }

      final used = data['bytesUsed'] as int? ?? 0;
      final remaining = _dailyLimitBytes - used;
      final percentage = used / _dailyLimitBytes;

      return DailyUsage(
        limitBytes: _dailyLimitBytes,
        usedBytes: used,
        remainingBytes: remaining.clamp(0, _dailyLimitBytes),
        usedPercentage: percentage.clamp(0.0, 1.0),
        date: today,
      );
    } catch (e) {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      return DailyUsage(
        limitBytes: _dailyLimitBytes,
        usedBytes: 0,
        remainingBytes: _dailyLimitBytes,
        usedPercentage: 0.0,
        date: today,
      );
    }
  }

  /// Increment daily usage tracker after successful upload
  Future<void> _incrementDailyUsage(String teacherId, int fileBytes) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _firestore
        .collection('users')
        .doc(teacherId)
        .collection('uploadTracker')
        .doc('daily')
        .set({
      'date': today,
      'bytesUsed': FieldValue.increment(fileBytes),
    }, SetOptions(merge: true));
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UPLOAD
  // ───────────────────────────────────────────────────────────────────────────

  /// Upload file to Cloudinary via Firebase Function (secure signed upload)
  Future<CloudinaryResult> uploadFile({
    required File file,
    required String fileName,
    required String teacherId,
    void Function(double progress)? onProgress,
  }) async {
    // 1. Validate file size
    final fileBytes = await file.length();
    if (fileBytes > _maxFileSizeBytes) {
      throw 'File exceeds 20 MB limit';
    }

    // 2. Get Firebase Auth token
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw 'Not authenticated';
    }

    // 3. Check daily limit
    final dailyUsage = await getDailyUsage(teacherId);
    if (dailyUsage.usedBytes + fileBytes > _dailyLimitBytes) {
      throw 'Daily upload limit reached. ${dailyUsage.remainingMB} MB remaining today.';
    }

    // 4. Check total storage quota
    final quota = await getStorageQuota(teacherId);
    if (quota.usedBytes + fileBytes > _totalFreeBytes) {
      throw 'Storage quota exceeded. ${quota.remainingGB} GB remaining.';
    }

    // 5. Get signed upload parameters from Firebase Function
    final signedParams = await _getSignedUploadParams(token, teacherId, fileBytes);

    // 6. Upload to Cloudinary
    final uri = Uri.parse(signedParams['upload_url'] as String);
    final request = http.MultipartRequest('POST', uri);

    // Add signed fields
    final fields = signedParams['fields'] as Map<String, dynamic>;
    fields.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    // Add file
    final multipartFile = await http.MultipartFile.fromPath('file', file.path);
    request.files.add(multipartFile);

    // Send with progress tracking
    final streamedResponse = await request.send();

    if (onProgress != null) {
      int bytesReceived = 0;
      streamedResponse.stream.listen(
        (chunk) {
          bytesReceived += chunk.length;
          onProgress(bytesReceived / fileBytes);
        },
      );
    }

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw 'Upload failed: ${response.body}';
    }

    final result = CloudinaryResult.fromJson(jsonDecode(response.body));

    // 7. Increment daily usage tracker
    await _incrementDailyUsage(teacherId, fileBytes);

    return result;
  }

  /// Call Firebase Function to get signed upload parameters
  Future<Map<String, dynamic>> _getSignedUploadParams(
    String token,
    String teacherId,
    int fileBytes,
  ) async {
    final response = await http.post(
      Uri.parse('$_functionsBaseUrl/getCloudinarySignature'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'teacherId': teacherId,
        'fileBytes': fileBytes,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw error['error']?['message'] ?? 'Failed to get upload signature';
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MATERIAL MANAGEMENT
  // ───────────────────────────────────────────────────────────────────────────

  /// Save material metadata to Firestore
  Future<void> saveMaterial({
    required String classId,
    required String name,
    required String subject,
    required String description,
    required String type,
    required CloudinaryResult cloudinaryResult,
    required String uploadedBy,
  }) async {
    final materialId = _uuid.v4();
    await _firestore
        .collection('classes')
        .doc(classId)
        .collection('materials')
        .doc(materialId)
        .set({
      'id': materialId,
      'name': name,
      'subject': subject,
      'description': description,
      'url': cloudinaryResult.url,
      'publicId': cloudinaryResult.publicId,
      'type': type,
      'format': cloudinaryResult.format,
      'sizeBytes': cloudinaryResult.bytes,
      'uploadedBy': uploadedBy,
      'uploadedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Delete material from Firestore (does NOT delete from Cloudinary)
  Future<void> deleteMaterial(String classId, String materialId) async {
    await _firestore
        .collection('classes')
        .doc(classId)
        .collection('materials')
        .doc(materialId)
        .delete();
  }

  /// Stream materials for a class
  Stream<List<Map<String, dynamic>>> materialsStream(String classId) {
    return _firestore
        .collection('classes')
        .doc(classId)
        .collection('materials')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }
}
