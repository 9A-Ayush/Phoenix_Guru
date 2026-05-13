import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../shared/widgets/widgets.dart';
import 'create_test_screen.dart';
import 'test_results_screen.dart';
import 'material_upload_screen.dart';

class ClassDetailScreen extends StatefulWidget {
  final ClassModel cls;
  const ClassDetailScreen({super.key, required this.cls});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  int _tab = 0;

  // Notifiers owned here, passed down to _StudentsTab
  final ValueNotifier<bool> _selectionMode = ValueNotifier(false);
  final ValueNotifier<Set<String>> _selectedIds = ValueNotifier({});

  // Cache the stream to prevent "already listened to" error
  late final Stream<ClassModel?> _classStream;

  @override
  void initState() {
    super.initState();
    _classStream = context.read<AppState>().classStream(widget.cls.id);
  }

  @override
  void dispose() {
    _selectionMode.dispose();
    _selectedIds.dispose();
    super.dispose();
  }

  // Subject → icon mapping
  IconData _subjectIcon(String s) {
    final lower = s.toLowerCase();
    if (lower.contains('physics'))  return Symbols.science;
    if (lower.contains('math'))     return Symbols.calculate;
    if (lower.contains('chem'))     return Symbols.biotech;
    if (lower.contains('bio'))      return Symbols.eco;
    if (lower.contains('hist'))     return Symbols.history_edu;
    if (lower.contains('geo'))      return Symbols.public;
    if (lower.contains('english'))  return Symbols.menu_book;
    if (lower.contains('computer')) return Symbols.computer;
    if (lower.contains('econ'))     return Symbols.trending_up;
    return Symbols.school;
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Code copied!',
          style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showMenu(BuildContext context, ClassModel cls) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: false,
      builder: (_) => _ClassMenuSheet(
        cls: cls,
        onEdit: () {
          Navigator.pop(context);
          _showEditSheet(context, cls);
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(context, cls);
        },
        onRemoveStudents: cls.studentIds.isNotEmpty
            ? () {
                Navigator.pop(context);
                _selectionMode.value = true;
                _selectedIds.value = {};
                setState(() => _tab = 0);
              }
            : null,
      ),
    );
  }

  void _showEditSheet(BuildContext context, ClassModel cls) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: false,
      builder: (_) => _EditClassSheet(cls: cls),
    );
  }

  void _confirmDelete(BuildContext context, ClassModel cls) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Class',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            'Are you sure you want to delete "${cls.name}"?\n\nThis will also delete all tests in this class. This cannot be undone.',
            style: GoogleFonts.poppins(
                color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final err = await context
                  .read<AppState>()
                  .deleteClass(cls.id);
              if (!mounted) return;
              if (err != null) {
                messenger.showSnackBar(SnackBar(
                  content: Text(err,
                      style: GoogleFonts.poppins(color: Colors.white)),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              } else {
                nav.pop();
                messenger.showSnackBar(SnackBar(
                  content: Text('Class deleted',
                      style: GoogleFonts.poppins(color: Colors.white)),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
            child: Text('Delete',
                style: GoogleFonts.poppins(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ClassModel?>(
      stream: _classStream,
      initialData: widget.cls,
      builder: (context, snapshot) {
        final cls = snapshot.data ?? widget.cls;

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Column(children: [
              // ── Header ──────────────────────────────────────────────────
              ValueListenableBuilder<bool>(
                valueListenable: _selectionMode,
                builder: (context, inSelection, _) {
                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 12, 24, 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1C1240), AppColors.bg],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          inSelection
                              ? GestureDetector(
                                  onTap: () {
                                    _selectionMode.value = false;
                                    _selectedIds.value = {};
                                  },
                                  child: Container(
                                    height: 36, width: 80,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                      const Icon(Icons.close_rounded,
                                          color: Colors.white, size: 18),
                                      const SizedBox(width: 6),
                                      Text('Cancel',
                                          style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500)),
                                    ]),
                                  ),
                                )
                              : const AppBackButton(),
                          if (!inSelection)
                            GestureDetector(
                              onTap: () => _showMenu(context, cls),
                              child: Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Icon(Icons.more_vert_rounded,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (inSelection) ...[
                        Text('Select students',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        ValueListenableBuilder<Set<String>>(
                          valueListenable: _selectedIds,
                          builder: (_, ids, __) => Text(
                            ids.isEmpty
                                ? 'Tap students to select'
                                : '${ids.length} selected',
                            style: GoogleFonts.poppins(
                                color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ),
                      ] else ...[
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(_subjectIcon(cls.subject),
                                color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(cls.name,
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                '${cls.studentCount} student${cls.studentCount == 1 ? '' : 's'}  •  ${cls.subject}',
                                style: GoogleFonts.poppins(
                                    color: AppColors.textSecondary,
                                    fontSize: 13),
                              ),
                            ]),
                          ),
                        ]),

                        const SizedBox(height: 12),

                        // Class code chip
                        GestureDetector(
                          onTap: () => _copyCode(cls.classCode),
                          child: Container(
                            height: 32,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Symbols.key,
                                  color: AppColors.primary, size: 14),
                              const SizedBox(width: 8),
                              Text('Code: ${cls.classCode}',
                                  style: GoogleFonts.poppins(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 6),
                              const Icon(Symbols.content_copy,
                                  color: AppColors.primary, size: 12),
                            ]),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Tabs
                      Row(
                        children: ['Students', 'Tests', 'Material']
                            .asMap()
                            .entries
                            .map((e) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _tab = e.key),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      height: 36,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: _tab == e.key
                                            ? AppColors.primary
                                            : AppColors.surface,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(e.value,
                                          style: GoogleFonts.poppins(
                                              color: _tab == e.key
                                                  ? Colors.white
                                                  : AppColors.textSecondary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ]),
                  );
                },
              ),

              // ── Tab content ──────────────────────────────────────────────
              Expanded(
                child: IndexedStack(
                  index: _tab,
                  children: [
                    _StudentsTab(
                      cls: cls,
                      selectionMode: _selectionMode,
                      selectedIds: _selectedIds,
                    ),
                    _TestsTab(cls: cls),
                    _MaterialTab(cls: cls),
                  ],
                ),
              ),
            ]),
        );
      },
    );
  }
}

// ── Students Tab ──────────────────────────────────────────────────────────────

class _StudentsTab extends StatefulWidget {
  final ClassModel cls;
  final ValueNotifier<bool> selectionMode;
  final ValueNotifier<Set<String>> selectedIds;

  const _StudentsTab({
    required this.cls,
    required this.selectionMode,
    required this.selectedIds,
  });

  @override
  State<_StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<_StudentsTab> {
  Stream<List<UserModel>>? _stream;
  List<String> _lastUids = [];
  bool _removing = false;

  static const _avatarColors = [
    AppColors.primary,
    AppColors.warning,
    AppColors.accent,
    AppColors.success,
    Color(0xFF1565C0),
    Color(0xFF7C3AED),
  ];

  @override
  void initState() {
    super.initState();
    _rebuildStream(widget.cls.studentIds);
  }

  @override
  void didUpdateWidget(_StudentsTab old) {
    super.didUpdateWidget(old);
    final newUids = widget.cls.studentIds;
    if (!_listEquals(newUids, _lastUids)) {
      _rebuildStream(newUids);
    }
  }

  void _rebuildStream(List<String> uids) {
    _lastUids = List<String>.from(uids);
    if (uids.isEmpty) {
      _stream = Stream.value([]);
      return;
    }
    _stream = context
        .read<AppState>()
        .firestoreInstance
        .collection('users')
        .where('id', whereIn: uids.take(30).toList())
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => UserModel.fromMap(d.data())).toList());
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _toggleSelection(String id) {
    final current = Set<String>.from(widget.selectedIds.value);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    widget.selectedIds.value = current;
  }

  Future<void> _confirmRemove(BuildContext ctx) async {
    if (_removing) return;
    final ids = widget.selectedIds.value.toList();
    if (ids.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove Students',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'Remove ${ids.length} student${ids.length == 1 ? '' : 's'} from this class? This cannot be undone.',
          style: GoogleFonts.poppins(
              color: AppColors.textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove',
                style: GoogleFonts.poppins(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return; // dialog dismissed — preserve selection
    if (!mounted) return;

    setState(() => _removing = true);
    final messenger = ScaffoldMessenger.of(context);
    final err = await context.read<AppState>().removeStudents(
          classId: widget.cls.id,
          studentIds: ids,
        );
    if (!mounted) return;
    setState(() => _removing = false);

    if (err != null) {
      messenger.showSnackBar(SnackBar(
        content: Text(err, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      // Stay in selection mode on error
    } else {
      widget.selectionMode.value = false;
      widget.selectedIds.value = {};
      messenger.showSnackBar(SnackBar(
        content: Text(
          'Removed ${ids.length} student${ids.length == 1 ? '' : 's'}',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cls.studentIds.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Symbols.groups, color: AppColors.textMuted, size: 52),
          const SizedBox(height: 12),
          Text('No students yet',
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Share the class code to invite students',
              style: GoogleFonts.poppins(
                  color: AppColors.textMuted, fontSize: 13)),
        ]),
      );
    }

    return StreamBuilder<List<UserModel>>(
      stream: _stream,
      builder: (context, snapshot) {
        final students = snapshot.data ?? [];
        final loading = snapshot.connectionState == ConnectionState.waiting &&
            students.isEmpty;

        if (loading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        return ValueListenableBuilder<bool>(
          valueListenable: widget.selectionMode,
          builder: (context, inSelection, _) {
            return Stack(
              children: [
                // ── Student list ──────────────────────────────────────────
                ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  itemCount: students.length + (inSelection ? 0 : 1),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    // Share code card at the bottom (normal mode only)
                    if (!inSelection && i == students.length) {
                      return _ShareCodeCard(classCode: widget.cls.classCode);
                    }

                    final s = students[i];
                    final color = _avatarColors[i % _avatarColors.length];

                    if (inSelection) {
                      return ValueListenableBuilder<Set<String>>(
                        valueListenable: widget.selectedIds,
                        builder: (_, ids, __) {
                          final selected = ids.contains(s.id);
                          return GestureDetector(
                            onTap: () => _toggleSelection(s.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              height: 64,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary.withValues(alpha: 0.08)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border(
                                  left: BorderSide(
                                    color: selected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Row(children: [
                                // Circular checkbox
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: selected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.textMuted,
                                      width: 2,
                                    ),
                                  ),
                                  child: selected
                                      ? const Icon(Icons.check_rounded,
                                          color: Colors.white, size: 14)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      color.withValues(alpha: 0.2),
                                  child: Text(s.avatarInitials,
                                      style: GoogleFonts.poppins(
                                          color: color,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(s.name,
                                          style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600)),
                                      Text(s.email,
                                          style: GoogleFonts.poppins(
                                              color: AppColors.textSecondary,
                                              fontSize: 11),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ]),
                            ),
                          );
                        },
                      );
                    }

                    // Normal mode — Dismissible
                    return Dismissible(
                      key: Key(s.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Symbols.person_remove,
                            color: AppColors.error, size: 22),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: AppColors.surface2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            title: Text('Remove Student',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                            content: Text(
                                'Remove ${s.name} from this class?',
                                style: GoogleFonts.poppins(
                                    color: AppColors.textSecondary)),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: Text('Cancel',
                                    style: GoogleFonts.poppins(
                                        color: AppColors.textSecondary)),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: Text('Remove',
                                    style: GoogleFonts.poppins(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) async {
                        final err = await context
                            .read<AppState>()
                            .removeStudent(
                                classId: widget.cls.id, studentId: s.id);
                        if (err != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(err,
                                style:
                                    GoogleFonts.poppins(color: Colors.white)),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ));
                        }
                      },
                      child: Container(
                        height: 64,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: color.withValues(alpha: 0.2),
                            child: Text(s.avatarInitials,
                                style: GoogleFonts.poppins(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(s.name,
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                Text(s.email,
                                    style: GoogleFonts.poppins(
                                        color: AppColors.textSecondary,
                                        fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Container(
                            height: 24,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            alignment: Alignment.center,
                            child: Text('Active',
                                style: GoogleFonts.poppins(
                                    color: AppColors.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ]),
                      ).animate().fadeIn(delay: (i * 50).ms),
                    );
                  },
                ),

                // ── Floating Remove button (selection mode) ───────────────
                if (inSelection)
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 24,
                    child: ValueListenableBuilder<Set<String>>(
                      valueListenable: widget.selectedIds,
                      builder: (_, ids, __) {
                        final hasSelection = ids.isNotEmpty;
                        return AnimatedSlide(
                          offset: hasSelection
                              ? Offset.zero
                              : const Offset(0, 1.5),
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          child: AnimatedOpacity(
                            opacity: hasSelection ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: GestureDetector(
                              onTap: _removing
                                  ? null
                                  : () => _confirmRemove(context),
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.error
                                          .withValues(alpha: 0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: _removing
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Symbols.person_remove,
                                              color: Colors.white, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Remove (${ids.length})',
                                            style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

// ── Tests Tab ─────────────────────────────────────────────────────────────────

class _TestsTab extends StatelessWidget {
  final ClassModel cls;
  const _TestsTab({required this.cls});

  @override
  Widget build(BuildContext context) {
    final tests = context.watch<AppState>().testsForClass(cls.id);

    if (tests.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Symbols.assignment, color: AppColors.textMuted, size: 52),
          const SizedBox(height: 12),
          Text('No tests yet',
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Create a test and assign it to this class',
              style: GoogleFonts.poppins(
                  color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CreateTestScreen())),
              child: Container(
                height: 54,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Symbols.add, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('Create Test',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: tests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final t = tests[i];
        final attempts = context.read<AppState>().attemptsForTest(t.id);

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeacherTestResultsScreen(test: t),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                Expanded(
                  child: Text(t.title,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
                Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: t.isLive
                        ? AppColors.errorLight
                        : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(t.isLive ? 'Live' : 'Upcoming',
                      style: GoogleFonts.poppins(
                          color: t.isLive
                              ? AppColors.error
                              : AppColors.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Symbols.schedule,
                    color: AppColors.textMuted, size: 14),
                const SizedBox(width: 4),
                Text('${t.durationMinutes} mins',
                    style: GoogleFonts.poppins(
                        color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(width: 12),
                const Icon(Symbols.help,
                    color: AppColors.textMuted, size: 14),
                const SizedBox(width: 4),
                Text('${t.questionCount} questions',
                    style: GoogleFonts.poppins(
                        color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(width: 12),
                const Icon(Symbols.person,
                    color: AppColors.textMuted, size: 14),
                const SizedBox(width: 4),
                Text('${attempts.length} attempted',
                    style: GoogleFonts.poppins(
                        color: AppColors.textMuted, fontSize: 12)),
              ]),
            ]),
          ).animate().fadeIn(delay: (i * 60).ms),
        );
      },
    );
  }
}

// ── Material Tab ──────────────────────────────────────────────────────────────

class _MaterialTab extends StatelessWidget {
  final ClassModel cls;
  const _MaterialTab({required this.cls});

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'image':
        return Icons.image_rounded;
      case 'doc':
        return Icons.description_rounded;
      case 'link':
        return Icons.link_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return const Color(0xFFEF4444);
      case 'image':
        return const Color(0xFF8B5CF6);
      case 'doc':
        return const Color(0xFF3B82F6);
      case 'link':
        return const Color(0xFF10B981);
      default:
        return AppColors.textMuted;
    }
  }

  String _formatSize(int bytes) {
    if (bytes == 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final cloudinary = CloudinaryService();
    
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: cloudinary.materialsStream(cls.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final materials = snapshot.data ?? [];

        if (materials.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Symbols.folder_open, color: AppColors.textMuted, size: 52),
              const SizedBox(height: 12),
              Text('No materials yet', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Upload study materials for your students', style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _UploadButton(cls: cls),
              ),
            ],
          );
        }

        return Column(
          children: [
            // Upload button at top
            Padding(
              padding: const EdgeInsets.all(16),
              child: _UploadButton(cls: cls),
            ),
            // Materials list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: materials.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final material = materials[index];
                  return _MaterialCard(
                    material: material,
                    typeIcon: _getTypeIcon(material['type'] ?? ''),
                    typeColor: _getTypeColor(material['type'] ?? ''),
                    sizeText: _formatSize(material['sizeBytes'] ?? 0),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Upload Button ─────────────────────────────────────────────────────────────

class _UploadButton extends StatelessWidget {
  final ClassModel cls;
  const _UploadButton({required this.cls});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => MaterialUploadScreen(preselectedClass: cls),
      )),
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Symbols.upload, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('Upload Material', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// ── Material Card ─────────────────────────────────────────────────────────────

class _MaterialCard extends StatelessWidget {
  final Map<String, dynamic> material;
  final IconData typeIcon;
  final Color typeColor;
  final String sizeText;

  const _MaterialCard({
    required this.material,
    required this.typeIcon,
    required this.typeColor,
    required this.sizeText,
  });

  void _openMaterial(BuildContext context) async {
    final url = material['url'] as String?;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No URL available', style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot open this link', style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening link: $e', style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = material['name'] as String? ?? 'Untitled';
    final subject = material['subject'] as String? ?? '';
    
    return GestureDetector(
      onTap: () => _openMaterial(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(typeIcon, color: typeColor, size: 24),
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
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        subject,
                        style: GoogleFonts.poppins(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      if (sizeText.isNotEmpty) ...[
                        const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                        Text(
                          sizeText,
                          style: GoogleFonts.poppins(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Arrow icon
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Share code card ───────────────────────────────────────────────────────────

class _ShareCodeCard extends StatelessWidget {
  final String classCode;
  const _ShareCodeCard({required this.classCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x116C47FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Symbols.share, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Invite Students',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('Share code  $classCode  with your students',
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary, fontSize: 12)),
          ]),
        ),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: classCode));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Code copied!',
                  style: GoogleFonts.poppins(color: Colors.white)),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ));
          },
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text('Copy',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

// ── Class menu bottom sheet ───────────────────────────────────────────────────

class _ClassMenuSheet extends StatelessWidget {
  final ClassModel cls;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onRemoveStudents;

  const _ClassMenuSheet({
    required this.cls,
    required this.onEdit,
    required this.onDelete,
    this.onRemoveStudents,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),

        // Class name header
        Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Symbols.school, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cls.name,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(cls.subject,
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary, fontSize: 12)),
            ]),
          ),
        ]),

        const SizedBox(height: 20),
        const Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 12),

        // Edit option
        _MenuOption(
          icon: Symbols.edit,
          iconColor: AppColors.primary,
          label: 'Edit Class',
          subtitle: 'Change name, subject or description',
          onTap: onEdit,
        ),

        const SizedBox(height: 8),

        // Remove Students option (only when there are students)
        if (onRemoveStudents != null) ...[
          _MenuOption(
            icon: Symbols.person_remove,
            iconColor: AppColors.warning,
            label: 'Remove Students',
            subtitle: 'Select and remove students from this class',
            onTap: onRemoveStudents!,
          ),
          const SizedBox(height: 8),
        ],

        // Delete option
        _MenuOption(
          icon: Symbols.delete,
          iconColor: AppColors.error,
          label: 'Delete Class',
          subtitle: 'Permanently remove this class and its tests',
          onTap: onDelete,
          destructive: true,
        ),
      ]),
    );
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const _MenuOption({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: destructive
              ? AppColors.errorLight
              : AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: destructive
                ? AppColors.error.withValues(alpha: 0.2)
                : AppColors.border,
          ),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      color: destructive ? AppColors.error : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: GoogleFonts.poppins(
                      color: destructive
                          ? AppColors.error.withValues(alpha: 0.7)
                          : AppColors.textSecondary,
                      fontSize: 12)),
            ]),
          ),
          Icon(Symbols.chevron_right,
              color: destructive
                  ? AppColors.error.withValues(alpha: 0.5)
                  : AppColors.textMuted,
              size: 18),
        ]),
      ),
    );
  }
}

// ── Edit class bottom sheet ───────────────────────────────────────────────────

class _EditClassSheet extends StatefulWidget {
  final ClassModel cls;
  const _EditClassSheet({required this.cls});

  @override
  State<_EditClassSheet> createState() => _EditClassSheetState();
}

class _EditClassSheetState extends State<_EditClassSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late String _subject;
  bool _saving = false;
  String? _error;

  static const _subjects = [
    'Physics', 'Mathematics', 'Chemistry', 'Biology',
    'History', 'Geography', 'English', 'Computer Science',
    'Economics', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.cls.name);
    _descCtrl = TextEditingController(text: widget.cls.description);
    _subject  = widget.cls.subject;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    final err = await context.read<AppState>().updateClass(
      classId:     widget.cls.id,
      name:        _nameCtrl.text.trim(),
      subject:     _subject,
      description: _descCtrl.text.trim(),
    );
    if (!mounted) return;
    if (err != null) {
      setState(() { _saving = false; _error = err; });
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Class updated!',
            style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Edit Class',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.textMuted, size: 18),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Class name
            _SheetLabel('Class Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name required' : null,
              decoration: InputDecoration(
                hintText: 'e.g. Physics — Class 12A',
                prefixIcon: const Icon(Symbols.edit,
                    color: AppColors.textMuted, size: 18),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 14),

            // Subject dropdown
            _SheetLabel('Subject'),
            const SizedBox(height: 8),
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _subject,
                  dropdownColor: AppColors.surface2,
                  icon: const Icon(Symbols.keyboard_arrow_down,
                      color: AppColors.textMuted, size: 18),
                  isExpanded: true,
                  items: _subjects.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s,
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 14)),
                  )).toList(),
                  onChanged: (v) =>
                      setState(() => _subject = v ?? _subject),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Description
            _SheetLabel('Description'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Brief description...',
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2)),
                filled: true,
                fillColor: AppColors.surface2,
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_error!,
                    style: GoogleFonts.poppins(
                        color: AppColors.error, fontSize: 13)),
              ),
            ],

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text('Save Changes',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text,
          style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500)),
    );
  }
}
