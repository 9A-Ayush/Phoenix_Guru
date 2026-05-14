import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/material_cache_service.dart';
import '../../../shared/widgets/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Material Cache Manager Screen
// View and manage cached study materials
// ─────────────────────────────────────────────────────────────────────────────

class MaterialCacheManagerScreen extends StatefulWidget {
  const MaterialCacheManagerScreen({super.key});

  @override
  State<MaterialCacheManagerScreen> createState() => _MaterialCacheManagerScreenState();
}

class _MaterialCacheManagerScreenState extends State<MaterialCacheManagerScreen> {
  final _cacheService = MaterialCacheService();
  List<Map<String, dynamic>> _cachedMaterials = [];
  String _totalCacheSize = '0.0';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCachedMaterials();
  }

  Future<void> _loadCachedMaterials() async {
    setState(() => _isLoading = true);
    
    final materials = await _cacheService.getCachedMaterials();
    final size = await _cacheService.getCacheSizeMB();
    
    if (mounted) {
      setState(() {
        _cachedMaterials = materials;
        _totalCacheSize = size;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMaterial(String materialId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Cached Material',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$name" from offline storage?',
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _cacheService.deleteCachedMaterial(materialId);
      _snack('Material deleted from offline storage');
      await _loadCachedMaterials();
    }
  }

  Future<void> _clearAllCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear All Cache',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will delete all cached materials. You\'ll need internet to view them again.',
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Clear All',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _cacheService.clearAllCache();
      _snack('All cached materials cleared');
      await _loadCachedMaterials();
    }
  }

  Future<void> _clearOldCache() async {
    await _cacheService.clearOldCache(daysOld: 30);
    _snack('Old cached materials cleared');
    await _loadCachedMaterials();
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':    return Icons.picture_as_pdf_rounded;
      case 'image':  return Icons.image_rounded;
      case 'doc':    return Icons.description_rounded;
      default:       return Icons.insert_drive_file_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':   return const Color(0xFFEF4444);
      case 'image': return const Color(0xFF8B5CF6);
      case 'doc':   return const Color(0xFF3B82F6);
      default:      return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // Header
          Container(
            height: 72 + MediaQuery.of(context).padding.top,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1C1240), AppColors.bg],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const AppBackButton(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Offline Storage',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_cachedMaterials.isNotEmpty)
                  PopupMenuButton<String>(
                    icon: const Icon(Symbols.more_vert, color: Colors.white),
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'clear_old') {
                        _clearOldCache();
                      } else if (value == 'clear_all') {
                        _clearAllCache();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'clear_old',
                        child: Row(
                          children: [
                            const Icon(Symbols.auto_delete, color: AppColors.warning, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Clear Old (30+ days)',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'clear_all',
                        child: Row(
                          children: [
                            const Icon(Symbols.delete_forever, color: AppColors.error, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Clear All Cache',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Storage info card
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Symbols.storage,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_totalCacheSize MB',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${_cachedMaterials.length} materials cached',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Cached materials list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _cachedMaterials.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Symbols.cloud_off,
                              color: AppColors.textMuted,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Cached Materials',
                              style: GoogleFonts.poppins(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Materials will be cached automatically\nwhen you view them',
                              style: GoogleFonts.poppins(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount: _cachedMaterials.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final m = _cachedMaterials[i];
                          final type = (m['format'] as String? ?? '').toLowerCase();
                          final icon = _typeIcon(type);
                          final color = _typeColor(type);
                          final name = m['name'] as String? ?? 'Untitled';
                          final size = _formatSize(m['sizeBytes'] as int? ?? 0);
                          final materialId = m['materialId'] as String? ?? '';
                          final cachedAt = DateTime.parse(m['cachedAt'] as String);
                          final daysAgo = DateTime.now().difference(cachedAt).inDays;

                          return Dismissible(
                            key: Key(materialId),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Symbols.delete,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            onDismissed: (_) => _deleteMaterial(materialId, name),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
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
                                        Text(
                                          name,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          [
                                            type.toUpperCase(),
                                            size,
                                            daysAgo == 0
                                                ? 'Today'
                                                : daysAgo == 1
                                                    ? 'Yesterday'
                                                    : '$daysAgo days ago',
                                          ].join('  •  '),
                                          style: GoogleFonts.poppins(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => _deleteMaterial(materialId, name),
                                    icon: const Icon(
                                      Symbols.delete,
                                      color: AppColors.error,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: (i * 40).ms),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
