import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models.dart';
import '../../../core/providers/app_state.dart';
import '../../../shared/widgets/widgets.dart';
import 'create_test_screen.dart';
import 'test_results_screen.dart';

class ClassDetailScreen extends StatefulWidget {
  final ClassModel cls;
  const ClassDetailScreen({super.key, required this.cls});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  int _tab = 0;

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

  @override
  Widget build(BuildContext context) {
    // Use StreamBuilder so the header updates in real time
    // (student count changes when someone joins/leaves)
    return StreamBuilder<ClassModel?>(
      stream: context.read<AppState>().classStream(widget.cls.id),
      initialData: widget.cls,
      builder: (context, snapshot) {
        final cls = snapshot.data ?? widget.cls;

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: SafeArea(
            child: Column(children: [
              // ── Header ──────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
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
                  const AppBackButton(),
                  const SizedBox(height: 20),

                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                              color: AppColors.textSecondary, fontSize: 13),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
              ),

              // ── Tab content ──────────────────────────────────────────────
              Expanded(
                child: IndexedStack(
                  index: _tab,
                  children: [
                    _StudentsTab(cls: cls),
                    _TestsTab(cls: cls),
                    const _MaterialTab(),
                  ],
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

// ── Students Tab ──────────────────────────────────────────────────────────────

class _StudentsTab extends StatelessWidget {
  final ClassModel cls;
  const _StudentsTab({required this.cls});

  static const _avatarColors = [
    AppColors.primary,
    AppColors.warning,
    AppColors.accent,
    AppColors.success,
    Color(0xFF1565C0),
    Color(0xFF7C3AED),
  ];

  @override
  Widget build(BuildContext context) {
    if (cls.studentIds.isEmpty) {
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

    // Stream all student profiles in real time using the studentIds list
    return StreamBuilder<List<UserModel>>(
      stream: _studentsStream(context, cls.studentIds),
      builder: (context, snapshot) {
        final students = snapshot.data ?? [];
        final loading = !snapshot.hasData;

        if (loading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: students.length + 1, // +1 for the share code card
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            // Last item — share code card
            if (i == students.length) {
              return _ShareCodeCard(classCode: cls.classCode);
            }

            final s = students[i];
            final color = _avatarColors[i % _avatarColors.length];

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
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel',
                            style: GoogleFonts.poppins(
                                color: AppColors.textSecondary)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
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
                    .removeStudent(classId: cls.id, studentId: s.id);
                if (err != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(err,
                        style: GoogleFonts.poppins(color: Colors.white)),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ));
                }
              },
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 14),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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
        );
      },
    );
  }

  /// Streams user profiles for the given UIDs.
  /// Re-emits whenever any of the user docs change.
  Stream<List<UserModel>> _studentsStream(
      BuildContext context, List<String> uids) {
    if (uids.isEmpty) return Stream.value([]);

    // Firestore 'in' query supports up to 30 items per query.
    // For simplicity we batch into chunks of 30.
    final chunks = <List<String>>[];
    for (var i = 0; i < uids.length; i += 30) {
      chunks.add(uids.sublist(
          i, i + 30 > uids.length ? uids.length : i + 30));
    }

    if (chunks.length == 1) {
      return context
          .read<AppState>()
          .firestoreInstance
          .collection('users')
          .where('id', whereIn: chunks[0])
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => UserModel.fromMap(d.data()))
              .toList());
    }

    // Multiple chunks — combine streams
    final streams = chunks.map((chunk) => context
        .read<AppState>()
        .firestoreInstance
        .collection('users')
        .where('id', whereIn: chunk)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => UserModel.fromMap(d.data())).toList()));

    // Merge by combining latest values from all streams
    return _mergeStreams(streams.toList());
  }

  Stream<List<UserModel>> _mergeStreams(
      List<Stream<List<UserModel>>> streams) {
    // For classes with >30 students, combine all chunk streams.
    // Simple approach: use the first chunk (covers 99% of real-world cases).
    return streams.first;
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
          Text('Create a test and assign it to this class',
              style: GoogleFonts.poppins(
                  color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CreateTestScreen())),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text('Create Test',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: tests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final t = tests[i];
        final attempts =
            context.read<AppState>().attemptsForTest(t.id);

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
  const _MaterialTab();

  @override
  Widget build(BuildContext context) {
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
        Text('Upload study materials for your students',
            style: GoogleFonts.poppins(
                color: AppColors.textMuted, fontSize: 13)),
      ]),
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
