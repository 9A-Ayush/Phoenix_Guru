import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';

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
    if (url == null || url.isEmpty) {
      _snack('No URL available', isError: true);
      return;
    }
    try {
      final launched =
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!launched && mounted) _snack('Cannot open this file', isError: true);
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
        child: Text('Study Material',
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700)),
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
            : StreamBuilder<List<Map<String, dynamic>>>(
                stream: _materialsStream(classIds),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary));
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
                    return _emptyState(
                      icon: Symbols.folder_open,
                      title: 'No materials found',
                      subtitle: _filter == 'all'
                          ? 'Your teachers haven\'t uploaded anything yet'
                          : 'No ${_filter.toUpperCase()} files available',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final m = filtered[i];
                      final type =
                          (m['type'] as String? ?? '').toLowerCase();
                      final icon = _typeIcon(type);
                      final color = _typeColor(type);
                      final size =
                          _formatSize(m['sizeBytes'] as int? ?? 0);
                      final name =
                          m['name'] as String? ?? 'Untitled';
                      final subject =
                          m['subject'] as String? ?? '';

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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                                      color: AppColors.textSecondary,
                                      fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ]),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Symbols.open_in_new,
                                color: AppColors.primary, size: 20),
                          ]),
                        ).animate().fadeIn(delay: (i * 40).ms),
                      );
                    },
                  );
                },
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
