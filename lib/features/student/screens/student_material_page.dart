import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/services/material_cache_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../viewers/secure_pdf_viewer.dart';
import '../viewers/secure_image_viewer.dart';
import '../viewers/secure_document_viewer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Student Material Page — real-time stream across all enrolled classes.
// View-only: opens in external browser. No share / download controls.
// ─────────────────────────────────────────────────────────────────────────────

class StudentMaterialPage extends StatefulWidget {
  const StudentMaterialPage({super.key});

  @override
  State<StudentMaterialPage> createState() => _StudentMaterialPageState();
}

class _StudentMaterialPageState extends State<StudentMaterialPage> {
  // Filter: 'all' | 'pdf' | 'image' | 'doc' | 'link'
  String _filter = 'all';
  
  final _cacheService = MaterialCacheService();
  final _connectivityService = ConnectivityService();
  bool _isOnline = true;
  List<Map<String, dynamic>> _recentMaterials = [];

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _loadRecentMaterials();
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

  Future<void> _loadRecentMaterials() async {
    final cached = await _cacheService.getCachedMaterials();
    if (mounted) {
      setState(() {
        _recentMaterials = cached.take(3).toList();
      });
    }
  }

  Future<void> _refreshMaterials() async {
    await _loadRecentMaterials();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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
          // External links - show warning dialog
          _showExternalLinkDialog(url);
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
        
        // Reload recent materials after viewing
        await _loadRecentMaterials();
        
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
            // Silent fail for background download
            debugPrint('Failed to cache material: $e');
            return ''; // Return empty string for error case
          });
        }
      }
    } catch (e) {
      if (mounted) _snack('Error: $e', isError: true);
    }
  }

  void _showExternalLinkDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'External Link',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will open an external website in your browser. Continue?',
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Open external link (keeping url_launcher for external links only)
              // This is acceptable as it's user-initiated and for external resources
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Open',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build a merged stream of materials from all enrolled classes ───────────

  Stream<List<Map<String, dynamic>>> _materialsStream(
      List<String> classIds) {
    if (classIds.isEmpty) return Stream.value([]);

    final firestore = context.read<AppState>().firestoreInstance;

    // One stream per class, then combine with rxdart-free approach using
    // StreamBuilder chaining. We use a simple polling approach via
    // Firestore collectionGroup or per-class streams merged manually.
    // Since we can't use rxdart, we use a StreamController that listens
    // to all class material collections and merges them.
    final streams = classIds.map((id) => firestore
        .collection('classes')
        .doc(id)
        .collection('materials')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList()));

    // Merge by combining latest values from each stream
    return _mergeStreams(streams.toList());
  }

  Stream<List<Map<String, dynamic>>> _mergeStreams(
      List<Stream<List<Map<String, dynamic>>>> streams) {
    if (streams.isEmpty) return Stream.value([]);

    final controller =
        StreamController<List<Map<String, dynamic>>>.broadcast();
    final latest = List<List<Map<String, dynamic>>>.filled(
        streams.length, [], growable: false);
    var initialized = 0;
    final subs = <StreamSubscription>[];

    for (var i = 0; i < streams.length; i++) {
      final idx = i;
      final sub = streams[idx].listen(
        (data) {
          latest[idx] = data;
          if (initialized < streams.length) initialized++;
          if (initialized == streams.length) {
            final merged = latest.expand((l) => l).toList();
            // Sort by uploadedAt descending
            merged.sort((a, b) {
              final aDate = a['uploadedAt'] as String? ?? '';
              final bDate = b['uploadedAt'] as String? ?? '';
              return bDate.compareTo(aDate);
            });
            if (!controller.isClosed) controller.add(merged);
          }
        },
        onError: (e) {
          if (!controller.isClosed) controller.addError(e);
        },
      );
      subs.add(sub);
    }

    controller.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };

    return controller.stream;
  }

  @override
  Widget build(BuildContext context) {
    final classIds =
        context.watch<AppState>().myClasses.map((c) => c.id).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Header ─────────────────────────────────────────────────────────────
      Padding(
        padding: EdgeInsets.fromLTRB(
            24, MediaQuery.of(context).padding.top + 12, 24, 0),
        child: Row(
          children: [
            Expanded(
              child: Text('Study Material',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
            ),
            // Connection status indicator
            if (!_isOnline)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Symbols.wifi_off,
                      color: AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Offline',
                      style: GoogleFonts.poppins(
                        color: AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // ── Filter chips ────────────────────────────────────────────────────────
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            _FilterChip(label: 'All', value: 'all', current: _filter,
                onTap: () => setState(() => _filter = 'all')),
            const SizedBox(width: 8),
            _FilterChip(label: 'PDFs', value: 'pdf', current: _filter,
                onTap: () => setState(() => _filter = 'pdf')),
            const SizedBox(width: 8),
            _FilterChip(label: 'Images', value: 'image', current: _filter,
                onTap: () => setState(() => _filter = 'image')),
            const SizedBox(width: 8),
            _FilterChip(label: 'Docs', value: 'doc', current: _filter,
                onTap: () => setState(() => _filter = 'doc')),
            const SizedBox(width: 8),
            _FilterChip(label: 'Links', value: 'link', current: _filter,
                onTap: () => setState(() => _filter = 'link')),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // ── Content ─────────────────────────────────────────────────────────────
      Expanded(
        child: classIds.isEmpty
            ? _emptyState(
                icon: Symbols.menu_book,
                title: 'No classes yet',
                subtitle: 'Join a class to see study materials',
              )
            : RefreshIndicator(
                onRefresh: _refreshMaterials,
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _materialsStream(classIds),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return _buildShimmerLoading();
                    }

                    final all = snapshot.data ?? [];
                    final filtered = _filter == 'all'
                        ? all
                        : all
                            .where((m) =>
                                (m['type'] as String? ?? '').toLowerCase() ==
                                _filter)
                            .toList();

                    if (filtered.isEmpty) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: _emptyState(
                            icon: Symbols.folder_open,
                            title: 'No materials found',
                            subtitle: _filter == 'all'
                                ? 'Your teachers haven\'t uploaded anything yet'
                                : 'No ${_filter.toUpperCase()} files available',
                          ),
                        ),
                      );
                    }

                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // Recent Materials Section
                        if (_recentMaterials.isNotEmpty && _filter == 'all')
                          SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Symbols.history,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Continue Reading',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 100,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    itemCount: _recentMaterials.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                                    itemBuilder: (_, i) {
                                      final m = _recentMaterials[i];
                                      return _buildRecentMaterialCard(m);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Text(
                                    'All Materials',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),

                        // All Materials List
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) {
                                final m = filtered[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildMaterialCard(m, i),
                                );
                              },
                              childCount: filtered.length,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
      ),
    ]);
  }

  Widget _emptyState(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: AppColors.textMuted, size: 52),
        const SizedBox(height: 12),
        Text(title,
            style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: GoogleFonts.poppins(
                color: AppColors.textMuted, fontSize: 13),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildMaterialCard(Map<String, dynamic> m, int index) {
    final type = (m['type'] as String? ?? '').toLowerCase();
    final icon = _typeIcon(type);
    final color = _typeColor(type);
    final size = _formatSize(m['sizeBytes'] as int? ?? 0);
    final name = m['name'] as String? ?? 'Untitled';
    final subject = m['subject'] as String? ?? '';
    final materialId = m['id'] as String? ?? '';

    return FutureBuilder<bool>(
      future: _cacheService.isCached(materialId),
      builder: (context, snapshot) {
        final isCached = snapshot.data ?? false;
        
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
              // Icon container
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
              
              // Content
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
                        if (subject.isNotEmpty) subject,
                        type.toUpperCase(),
                        if (size.isNotEmpty) size,
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
          ).animate().fadeIn(delay: (index * 40).ms),
        );
      },
    );
  }

  Widget _buildRecentMaterialCard(Map<String, dynamic> m) {
    final type = (m['format'] as String? ?? '').toLowerCase();
    final icon = _typeIcon(type);
    final color = _typeColor(type);
    final name = m['name'] as String? ?? 'Untitled';
    final materialId = m['materialId'] as String? ?? '';

    return FutureBuilder<Map<String, dynamic>?>(
      future: _cacheService.getLastViewedPosition(materialId),
      builder: (context, snapshot) {
        final lastViewed = snapshot.data;
        String progressText = '';
        
        if (lastViewed != null) {
          if (lastViewed['page'] != null) {
            progressText = 'Page ${lastViewed['page']}';
          } else if (lastViewed['videoPosition'] != null) {
            final seconds = lastViewed['videoPosition'] as int;
            final minutes = seconds ~/ 60;
            progressText = '${minutes}m ${seconds % 60}s';
          }
        }

        return GestureDetector(
          onTap: () => _openMaterial(m),
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (progressText.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          progressText,
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        return Container(
          height: 76,
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
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 150,
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate(
          onPlay: (controller) => controller.repeat(),
        ).shimmer(
          duration: 1500.ms,
          color: AppColors.surface2.withValues(alpha: 0.3),
        );
      },
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = value == current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? AppColors.primary : AppColors.border),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: GoogleFonts.poppins(
                color: active ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ),
    );
  }
}
