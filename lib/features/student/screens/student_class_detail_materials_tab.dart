import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/services/material_cache_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../viewers/secure_pdf_viewer.dart';
import '../viewers/secure_image_viewer.dart';
import '../viewers/secure_document_viewer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Student Materials Tab - Secure in-app viewing with offline support
// ─────────────────────────────────────────────────────────────────────────────

class StudentMaterialsTab extends StatefulWidget {
  final ClassModel cls;
  const StudentMaterialsTab({super.key, required this.cls});

  @override
  State<StudentMaterialsTab> createState() => _StudentMaterialsTabState();
}

class _StudentMaterialsTabState extends State<StudentMaterialsTab> {
  final _cacheService = MaterialCacheService();
  final _connectivityService = ConnectivityService();
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    await _connectivityService.initialize();
    _isOnline = _connectivityService.isConnected;
    _connectivityService.connectionStream.listen((isConnected) {
      if (mounted) {
        setState(() => _isOnline = isConnected);
      }
    });
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':    return Icons.picture_as_pdf_rounded;
      case 'image':  return Icons.image_rounded;
      case 'doc':    return Icons.description_rounded;
      case 'link':   return Icons.link_rounded;
      default:       return Icons.insert_drive_file_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':   return const Color(0xFFEF4444);
      case 'image': return const Color(0xFF8B5CF6);
      case 'doc':   return const Color(0xFF3B82F6);
      case 'link':  return const Color(0xFF10B981);
      default:      return AppColors.textMuted;
    }
  }

  String _formatSize(int bytes) {
    if (bytes == 0) return '';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _openMaterial(Map<String, dynamic> material) async {
    final url = material['url'] as String?;
    final type = (material['type'] as String? ?? '').toLowerCase();
    final materialId = material['id'] as String? ?? '';
    final materialName = material['name'] as String? ?? 'Untitled';
    final sizeBytes = material['sizeBytes'] as int? ?? 0;

    if (url == null || url.isEmpty) {
      _snack('No URL available', isError: true);
      return;
    }

    try {
      // Check if material is cached
      final isCached = await _cacheService.isCached(materialId);
      String? filePath;

      if (isCached) {
        filePath = await _cacheService.getCachedFilePath(materialId);
      } else if (!_isOnline) {
        _snack('No internet connection. Material not available offline.', isError: true);
        return;
      }

      // Navigate to appropriate secure viewer based on type
      Widget viewer;
      
      switch (type) {
        case 'pdf':
          viewer = SecurePDFViewer(
            materialId: materialId,
            materialName: materialName,
            filePath: filePath,
            url: filePath == null ? url : null,
          );
          break;
          
        case 'image':
          viewer = SecureImageViewer(
            materialId: materialId,
            materialName: materialName,
            filePath: filePath,
            url: filePath == null ? url : null,
          );
          break;
          
        case 'doc':
          // DOC/PPT files use Google Docs Viewer (requires URL)
          viewer = SecureDocumentViewer(
            materialId: materialId,
            materialName: materialName,
            url: url,
          );
          break;
          
        case 'link':
          // External links - show warning
          _snack('External links open in browser', isError: false);
          return;
          
        default:
          _snack('Unsupported file type: $type', isError: true);
          return;
      }
      
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => viewer),
        );
        
        // Cache material after first view if not already cached
        if (!isCached && _isOnline && type != 'link' && type != 'doc') {
          // Start background download
          _cacheService.downloadAndCache(
            materialId: materialId,
            url: url,
            format: type,
            name: materialName,
            sizeBytes: sizeBytes,
          ).catchError((e) {
            debugPrint('Failed to cache material: $e');
            return '';
          });
        }
      }
    } catch (e) {
      if (mounted) _snack('Error: $e', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cloudinary = CloudinaryService();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: cloudinary.materialsStream(widget.cls.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final materials = snapshot.data ?? [];

        if (materials.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Symbols.folder_open,
                  color: AppColors.textMuted, size: 52),
              const SizedBox(height: 12),
              Text('No materials yet',
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Your teacher hasn\'t uploaded any materials yet',
                  style: GoogleFonts.poppins(
                      color: AppColors.textMuted, fontSize: 13),
                  textAlign: TextAlign.center),
            ]),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          itemCount: materials.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final m = materials[i];
            final type = (m['type'] as String? ?? '').toLowerCase();
            final icon = _typeIcon(type);
            final color = _typeColor(type);
            final size = _formatSize(m['sizeBytes'] as int? ?? 0);
            final name = m['name'] as String? ?? 'Untitled';
            final subject = m['subject'] as String? ?? '';
            final materialId = m['id'] as String? ?? '';

            return FutureBuilder<bool>(
              future: _cacheService.isCached(materialId),
              builder: (context, cacheSnapshot) {
                final isCached = cacheSnapshot.data ?? false;

                return GestureDetector(
                  onTap: () => _openMaterial(m),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(name,
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (subject.isNotEmpty) subject,
                              type.toUpperCase(),
                              if (size.isNotEmpty) size,
                            ].join('  •  '),
                            style: GoogleFonts.poppins(
                                color: AppColors.textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      // Offline badge or open icon
                      if (isCached)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Symbols.offline_pin,
                                color: AppColors.success,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Offline',
                                style: GoogleFonts.poppins(
                                  color: AppColors.success,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Icon(
                          type == 'link' 
                            ? Symbols.open_in_new 
                            : Symbols.play_arrow,
                          color: AppColors.primary,
                          size: 20,
                        ),
                    ]),
                  ).animate().fadeIn(delay: (i * 40).ms),
                );
              },
            );
          },
        );
      },
    );
  }
}
