import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ─────────────────────────────────────────────────────────────────────────────
// Material Cache Service
// Handles offline storage and caching of study materials
// ─────────────────────────────────────────────────────────────────────────────

class MaterialCacheService {
  static final MaterialCacheService _instance = MaterialCacheService._internal();
  factory MaterialCacheService() => _instance;
  MaterialCacheService._internal();

  final Dio _dio = Dio();
  static const String _cacheMetadataKey = 'material_cache_metadata';
  static const String _lastViewedKey = 'material_last_viewed';

  // ───────────────────────────────────────────────────────────────────────────
  // CACHE DIRECTORY MANAGEMENT
  // ───────────────────────────────────────────────────────────────────────────

  /// Get the cache directory for materials
  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/material_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Get file path for a cached material
  Future<String> _getCachedFilePath(String materialId, String format) async {
    final cacheDir = await _getCacheDirectory();
    return '${cacheDir.path}/$materialId.$format';
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CACHE METADATA MANAGEMENT
  // ───────────────────────────────────────────────────────────────────────────

  /// Get cache metadata for all materials
  Future<Map<String, dynamic>> _getCacheMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cacheMetadataKey);
    if (jsonString == null) return {};
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Save cache metadata
  Future<void> _saveCacheMetadata(Map<String, dynamic> metadata) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheMetadataKey, jsonEncode(metadata));
  }

  /// Update metadata for a specific material
  Future<void> _updateMaterialMetadata(String materialId, Map<String, dynamic> data) async {
    final metadata = await _getCacheMetadata();
    metadata[materialId] = {
      ...data,
      'lastAccessed': DateTime.now().toIso8601String(),
    };
    await _saveCacheMetadata(metadata);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DOWNLOAD & CACHE
  // ───────────────────────────────────────────────────────────────────────────

  /// Download and cache a material
  Future<String> downloadAndCache({
    required String materialId,
    required String url,
    required String format,
    required String name,
    required int sizeBytes,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final filePath = await _getCachedFilePath(materialId, format);
      
      // Download file with progress tracking
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      // Save metadata
      await _updateMaterialMetadata(materialId, {
        'materialId': materialId,
        'name': name,
        'format': format,
        'sizeBytes': sizeBytes,
        'filePath': filePath,
        'url': url,
        'cachedAt': DateTime.now().toIso8601String(),
      });

      return filePath;
    } catch (e) {
      throw 'Failed to download material: $e';
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CACHE RETRIEVAL
  // ───────────────────────────────────────────────────────────────────────────

  /// Check if material is cached
  Future<bool> isCached(String materialId) async {
    final metadata = await _getCacheMetadata();
    if (!metadata.containsKey(materialId)) return false;

    final filePath = metadata[materialId]['filePath'] as String?;
    if (filePath == null) return false;

    final file = File(filePath);
    return await file.exists();
  }

  /// Get cached file path
  Future<String?> getCachedFilePath(String materialId) async {
    if (!await isCached(materialId)) return null;

    final metadata = await _getCacheMetadata();
    final filePath = metadata[materialId]['filePath'] as String?;

    // Update last accessed time
    if (filePath != null) {
      await _updateMaterialMetadata(materialId, metadata[materialId]);
    }

    return filePath;
  }

  /// Get material metadata
  Future<Map<String, dynamic>?> getMaterialMetadata(String materialId) async {
    final metadata = await _getCacheMetadata();
    return metadata[materialId] as Map<String, dynamic>?;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // LAST VIEWED TRACKING
  // ───────────────────────────────────────────────────────────────────────────

  /// Save last viewed position for a material
  Future<void> saveLastViewedPosition({
    required String materialId,
    int? page,
    double? scrollPosition,
    int? videoPosition,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final lastViewed = prefs.getString(_lastViewedKey);
    final Map<String, dynamic> data = lastViewed != null 
        ? jsonDecode(lastViewed) as Map<String, dynamic>
        : {};

    data[materialId] = {
      'page': page,
      'scrollPosition': scrollPosition,
      'videoPosition': videoPosition,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_lastViewedKey, jsonEncode(data));
  }

  /// Get last viewed position for a material
  Future<Map<String, dynamic>?> getLastViewedPosition(String materialId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastViewed = prefs.getString(_lastViewedKey);
    if (lastViewed == null) return null;

    final data = jsonDecode(lastViewed) as Map<String, dynamic>;
    return data[materialId] as Map<String, dynamic>?;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CACHE MANAGEMENT
  // ───────────────────────────────────────────────────────────────────────────

  /// Get total cache size in bytes
  Future<int> getCacheSize() async {
    final metadata = await _getCacheMetadata();
    int totalSize = 0;

    for (final entry in metadata.values) {
      final sizeBytes = entry['sizeBytes'] as int? ?? 0;
      totalSize += sizeBytes;
    }

    return totalSize;
  }

  /// Get cache size in MB
  Future<String> getCacheSizeMB() async {
    final bytes = await getCacheSize();
    return (bytes / (1024 * 1024)).toStringAsFixed(1);
  }

  /// Get list of all cached materials
  Future<List<Map<String, dynamic>>> getCachedMaterials() async {
    final metadata = await _getCacheMetadata();
    final List<Map<String, dynamic>> materials = [];

    for (final entry in metadata.values) {
      final filePath = entry['filePath'] as String?;
      if (filePath != null && await File(filePath).exists()) {
        materials.add(entry as Map<String, dynamic>);
      }
    }

    // Sort by last accessed (most recent first)
    materials.sort((a, b) {
      final aTime = DateTime.parse(a['lastAccessed'] as String);
      final bTime = DateTime.parse(b['lastAccessed'] as String);
      return bTime.compareTo(aTime);
    });

    return materials;
  }

  /// Delete a specific cached material
  Future<void> deleteCachedMaterial(String materialId) async {
    final metadata = await _getCacheMetadata();
    final materialData = metadata[materialId];

    if (materialData != null) {
      final filePath = materialData['filePath'] as String?;
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      metadata.remove(materialId);
      await _saveCacheMetadata(metadata);
    }
  }

  /// Clear all cached materials
  Future<void> clearAllCache() async {
    final cacheDir = await _getCacheDirectory();
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheMetadataKey);
    await prefs.remove(_lastViewedKey);
  }

  /// Clear old cache (materials not accessed in last 30 days)
  Future<void> clearOldCache({int daysOld = 30}) async {
    final metadata = await _getCacheMetadata();
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    final List<String> toDelete = [];

    for (final entry in metadata.entries) {
      final lastAccessed = DateTime.parse(entry.value['lastAccessed'] as String);
      if (lastAccessed.isBefore(cutoffDate)) {
        toDelete.add(entry.key);
      }
    }

    for (final materialId in toDelete) {
      await deleteCachedMaterial(materialId);
    }
  }

  /// Validate cache integrity (remove metadata for missing files)
  Future<void> validateCache() async {
    final metadata = await _getCacheMetadata();
    final List<String> toRemove = [];

    for (final entry in metadata.entries) {
      final filePath = entry.value['filePath'] as String?;
      if (filePath == null || !await File(filePath).exists()) {
        toRemove.add(entry.key);
      }
    }

    for (final materialId in toRemove) {
      metadata.remove(materialId);
    }

    if (toRemove.isNotEmpty) {
      await _saveCacheMetadata(metadata);
    }
  }
}
