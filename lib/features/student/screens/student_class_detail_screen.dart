import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models.dart';
import '../../../core/providers/app_state.dart';
import '../../../shared/widgets/widgets.dart';
import 'student_test_detail_screen.dart';
import 'student_class_detail_materials_tab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Student Class Detail Screen — 3 tabs: Members · Tests · Materials
// Read-only view. No share / screenshot controls.
// ─────────────────────────────────────────────────────────────────────────────

class StudentClassDetailScreen extends StatefulWidget {
  final ClassModel cls;
  const StudentClassDetailScreen({super.key, required this.cls});

  @override
  State<StudentClassDetailScreen> createState() =>
      _StudentClassDetailScreenState();
}

class _StudentClassDetailScreenState extends State<StudentClassDetailScreen> {
  int _tab = 0;
  late final Stream<ClassModel?> _classStream;

  @override
  void initState() {
    super.initState();
    _classStream = context.read<AppState>().classStream(widget.cls.id);
  }

  IconData _subjectIcon(String s) {
    final l = s.toLowerCase();
    if (l.contains('physics'))  return Symbols.science;
    if (l.contains('math'))     return Symbols.calculate;
    if (l.contains('chem'))     return Symbols.biotech;
    if (l.contains('bio'))      return Symbols.eco;
    if (l.contains('hist'))     return Symbols.history_edu;
    if (l.contains('geo'))      return Symbols.public;
    if (l.contains('english'))  return Symbols.menu_book;
    if (l.contains('computer')) return Symbols.computer;
    if (l.contains('econ'))     return Symbols.trending_up;
    return Symbols.school;
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
            // ── Header ──────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                  24, MediaQuery.of(context).padding.top + 12, 24, 16),
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
                // Back row
                const AppBackButton(),
                const SizedBox(height: 20),

                // Class info
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 56,
                    height: 56,
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
                        '${cls.teacherName}  •  ${cls.subject}',
                        style: GoogleFonts.poppins(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${cls.studentCount} student${cls.studentCount == 1 ? '' : 's'}',
                        style: GoogleFonts.poppins(
                            color: AppColors.textMuted, fontSize: 12),
                      ),
                    ]),
                  ),
                ]),

                const SizedBox(height: 16),

                // Tab bar
                Row(
                  children: ['Members', 'Tests', 'Materials']
                      .asMap()
                      .entries
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _tab = e.key),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 36,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14),
                                decoration: BoxDecoration(
                                  color: _tab == e.key
                                      ? AppColors.primary
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
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
            ),

            // ── Tab content ──────────────────────────────────────────────────
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  _MembersTab(cls: cls),
                  _StudentTestsTab(cls: cls),
                  StudentMaterialsTab(cls: cls),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0 — Members
// ─────────────────────────────────────────────────────────────────────────────

class _MembersTab extends StatefulWidget {
  final ClassModel cls;
  const _MembersTab({required this.cls});

  @override
  State<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<_MembersTab> {
  Stream<List<UserModel>>? _stream;
  List<String> _lastUids = [];

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
  void didUpdateWidget(_MembersTab old) {
    super.didUpdateWidget(old);
    final newUids = widget.cls.studentIds;
    if (!_listEquals(newUids, _lastUids)) _rebuildStream(newUids);
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

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AppState>().currentUser?.id;

    if (widget.cls.studentIds.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Symbols.groups, color: AppColors.textMuted, size: 52),
          const SizedBox(height: 12),
          Text('No members yet',
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
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

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          itemCount: students.length + 1, // +1 for teacher card at top
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            // Teacher card at top
            if (i == 0) {
              return _MemberCard(
                name: widget.cls.teacherName,
                subtitle: 'Teacher',
                color: AppColors.primary,
                isTeacher: true,
                isSelf: false,
              ).animate().fadeIn(duration: 300.ms);
            }

            final s = students[i - 1];
            final color = _avatarColors[(i - 1) % _avatarColors.length];
            final isSelf = s.id == currentUserId;

            return _MemberCard(
              name: s.name,
              subtitle: isSelf ? 'You' : 'Student',
              color: color,
              isTeacher: false,
              isSelf: isSelf,
            ).animate().fadeIn(delay: (i * 50).ms);
          },
        );
      },
    );
  }
}

class _MemberCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final Color color;
  final bool isTeacher;
  final bool isSelf;

  const _MemberCard({
    required this.name,
    required this.subtitle,
    required this.color,
    required this.isTeacher,
    required this.isSelf,
  });

  String get _initials =>
      name.split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isSelf
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: isSelf
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
            : Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withValues(alpha: 0.18),
          child: Text(_initials,
              style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Text(name,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            Text(subtitle,
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary, fontSize: 11)),
          ]),
        ),
        if (isTeacher)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Teacher',
                style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
        if (isSelf && !isTeacher)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('You',
                style: GoogleFonts.poppins(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Tests
// ─────────────────────────────────────────────────────────────────────────────

class _StudentTestsTab extends StatelessWidget {
  final ClassModel cls;
  const _StudentTestsTab({required this.cls});

  @override
  Widget build(BuildContext context) {
    final myAttempts = context.watch<AppState>().myAttempts;
    final tests = context.watch<AppState>().testsForClass(cls.id).where((t) {
      final attemptCount = myAttempts.where((a) => a.testId == t.id).length;
      if (attemptCount > 0) return true; // Show taken tests
      return t.isPublished; // Otherwise only show if published
    }).toList();

    if (tests.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Symbols.assignment, color: AppColors.textMuted, size: 52),
          const SizedBox(height: 12),
          Text('No tests yet',
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Your teacher hasn\'t added any tests yet',
              style:
                  GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 13)),
        ]),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: tests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final t = tests[i];
        final attemptCount = myAttempts.where((a) => a.testId == t.id).length;
        final maxAttemptsReached = attemptCount >= t.maxAttempts;
        final myAttempt = attemptCount > 0
            ? myAttempts.lastWhere((a) => a.testId == t.id)
            : null;

        return GestureDetector(
          onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => StudentTestDetailScreen(test: t)),
              ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: maxAttemptsReached
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.border,
              ),
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
                const SizedBox(width: 8),
                Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: maxAttemptsReached
                        ? AppColors.successLight
                        : t.isLive
                            ? AppColors.errorLight
                            : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    maxAttemptsReached
                        ? 'Done'
                        : t.isLive
                            ? 'Live'
                            : 'Upcoming',
                    style: GoogleFonts.poppins(
                        color: maxAttemptsReached
                            ? AppColors.success
                            : t.isLive
                                ? AppColors.error
                                : AppColors.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
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
                if (myAttempt != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Symbols.emoji_events,
                      color: AppColors.success, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Rank #${myAttempt.rank}',
                    style: GoogleFonts.poppins(
                        color: AppColors.success, fontSize: 12),
                  ),
                ],
              ]),
              if (!maxAttemptsReached && !t.isExpired) ...[
                const SizedBox(height: 12),
                Container(
                  height: 38,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text('Start Test',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ]),
          ).animate().fadeIn(delay: (i * 60).ms),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Materials (read-only, view in-app only)
// ─────────────────────────────────────────────────────────────────────────────
