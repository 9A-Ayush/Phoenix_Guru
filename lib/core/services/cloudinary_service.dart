import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const _totalFreeBytes = 25 * 1024 * 1024 * 1024; // 25 GB
const _dailyLimitBytes = 500 * 1024 * 1024;      // 500 MB
const _maxFileSizeBytes = 20 * 1024 * 1024;      // 20 MB

// Cloudinary config (exposed in app, but unsigned preset limits uploads)
const _cloudName = 'dwv7xyucs';
const _uploadPreset = 'phoenix_guru_unsigned';

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

  CloudinaryService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

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
  // UPLOAD (Direct to Cloudinary, no Firebase Functions)
  // ───────────────────────────────────────────────────────────────────────────

  /// Upload file directly to Cloudinary using unsigned preset
  /// 
  /// Note: This is less secure than signed uploads via Firebase Functions,
  /// but doesn't require Blaze plan. Rate limits are client-side only.
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

    // 2. Check daily limit (client-side only - can be bypassed)
    final dailyUsage = await getDailyUsage(teacherId);
    if (dailyUsage.usedBytes + fileBytes > _dailyLimitBytes) {
      throw 'Daily upload limit reached. ${dailyUsage.remainingMB} MB remaining today.';
    }

    // 3. Check total storage quota (client-side only - can be bypassed)
    final quota = await getStorageQuota(teacherId);
    if (quota.usedBytes + fileBytes > _totalFreeBytes) {
      throw 'Storage quota exceeded. ${quota.remainingGB} GB remaining.';
    }

    // 4. Upload directly to Cloudinary
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/auto/upload'
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = 'phoenix_guru/materials';

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

    // 5. Increment daily usage tracker
    await _incrementDailyUsage(teacherId, fileBytes);

    return result;
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
