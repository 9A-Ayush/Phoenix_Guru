import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models.dart';
import '../../../core/providers/app_state.dart';

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  State<PaymentManagementScreen> createState() => _PaymentManagementScreenState();
}

// Combines a student + their class with an optional existing payment record
class _StudentEntry {
  final UserModel student;
  final ClassModel cls;
  final StudentPayment? payment;
  _StudentEntry({required this.student, required this.cls, this.payment});
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  String _filterStatus = 'all';
  List<_StudentEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    final state = context.read<AppState>();
    final pairs = await state.fetchStudentsForTeacher();
    final payments = state.allPayments;

    // Build a lookup: studentId+classId → payment
    final Map<String, StudentPayment> payMap = {
      for (final p in payments) '${p.studentId}_${p.classId}': p,
    };

    setState(() {
      _entries = pairs.map((pair) {
        final key = '${pair.student.id}_${pair.cls.id}';
        return _StudentEntry(
          student: pair.student,
          cls: pair.cls,
          payment: payMap[key],
        );
      }).toList();
      _loading = false;
    });
  }

  List<_StudentEntry> get _filtered {
    if (_filterStatus == 'all') return _entries;
    if (_filterStatus == 'unpaid') {
      return _entries.where((e) => e.payment == null || !e.payment!.isPaid).toList();
    }
    return _entries.where((e) {
      if (e.payment == null) return false;
      return e.payment!.status.name == _filterStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Re-overlay payments whenever AppState updates (real-time Firestore)
    final payments = context.watch<AppState>().allPayments;
    final Map<String, StudentPayment> payMap = {
      for (final p in payments) '${p.studentId}_${p.classId}': p,
    };
    final entries = _entries.map((e) {
      final key = '${e.student.id}_${e.cls.id}';
      return _StudentEntry(student: e.student, cls: e.cls, payment: payMap[key]);
    }).toList();

    final filtered = _filterStatus == 'all'
        ? entries
        : _filterStatus == 'unpaid'
            ? entries.where((e) => e.payment == null || !e.payment!.isPaid).toList()
            : entries.where((e) => e.payment?.status.name == _filterStatus).toList();

    final paidCount = entries.where((e) => e.payment?.isPaid == true).length;
    final dueCount = entries.where((e) => e.payment?.isDue == true).length;
    final overdueCount = entries.where((e) => e.payment?.isOverdue == true).length;
    final unmarkedCount = entries.where((e) => e.payment == null).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 20),
            color: AppColors.bg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chevron_left_rounded,
                              color: AppColors.textSecondary, size: 18),
                          const SizedBox(width: 6),
                          Text('Back',
                              style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _loadStudents,
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Symbols.refresh,
                            color: AppColors.textMuted, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Payment Management',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Track and manage student fee payments',
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.normal)),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Symbols.group,
                                color: AppColors.textMuted, size: 48),
                            const SizedBox(height: 12),
                            Text('No students in your classes yet',
                                style: GoogleFonts.poppins(
                                    color: AppColors.textSecondary,
                                    fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          const SizedBox(height: 8),

                          // ── Stats row ──────────────────────────────────────
                          Row(children: [
                            Expanded(child: _StatCard(
                                label: 'Paid', value: '$paidCount',
                                color: AppColors.success, icon: Symbols.check_circle)),
                            const SizedBox(width: 8),
                            Expanded(child: _StatCard(
                                label: 'Due', value: '$dueCount',
                                color: AppColors.warning, icon: Symbols.schedule)),
                            const SizedBox(width: 8),
                            Expanded(child: _StatCard(
                                label: 'Overdue', value: '$overdueCount',
                                color: AppColors.error, icon: Symbols.error)),
                            const SizedBox(width: 8),
                            Expanded(child: _StatCard(
                                label: 'Unmarked', value: '$unmarkedCount',
                                color: AppColors.textMuted, icon: Symbols.help_outline)),
                          ]).animate().fadeIn(delay: 100.ms),

                          const SizedBox(height: 16),

                          // ── Filter chips ───────────────────────────────────
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(children: [
                              _FilterChip(label: 'All', isSelected: _filterStatus == 'all',
                                  onTap: () => setState(() => _filterStatus = 'all')),
                              const SizedBox(width: 8),
                              _FilterChip(label: 'Paid', isSelected: _filterStatus == 'paid',
                                  color: AppColors.success,
                                  onTap: () => setState(() => _filterStatus = 'paid')),
                              const SizedBox(width: 8),
                              _FilterChip(label: 'Due', isSelected: _filterStatus == 'due',
                                  color: AppColors.warning,
                                  onTap: () => setState(() => _filterStatus = 'due')),
                              const SizedBox(width: 8),
                              _FilterChip(label: 'Overdue', isSelected: _filterStatus == 'overdue',
                                  color: AppColors.error,
                                  onTap: () => setState(() => _filterStatus = 'overdue')),
                              const SizedBox(width: 8),
                              _FilterChip(label: 'Unpaid', isSelected: _filterStatus == 'unpaid',
                                  color: AppColors.textSecondary,
                                  onTap: () => setState(() => _filterStatus = 'unpaid')),
                            ]),
                          ).animate().fadeIn(delay: 150.ms),

                          const SizedBox(height: 16),

                          if (filtered.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text('No students match this filter',
                                    style: GoogleFonts.poppins(
                                        color: AppColors.textSecondary)),
                              ),
                            )
                          else
                            ...filtered.asMap().entries.map((e) {
                              final i = e.key;
                              final entry = e.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _StudentPaymentCard(
                                  entry: entry,
                                  onMarkPaid: () => _markStatus(
                                      entry, PaymentStatus.paid),
                                  onMarkDue: () => _markStatus(
                                      entry, PaymentStatus.due),
                                  onMarkOverdue: () => _markStatus(
                                      entry, PaymentStatus.overdue),
                                ),
                              ).animate().fadeIn(delay: (200 + i * 40).ms);
                            }),

                          const SizedBox(height: 24),
                        ],
                      ),
          ),
        ]),
    );
  }

  Future<void> _markStatus(_StudentEntry entry, PaymentStatus status) async {
    final state = context.read<AppState>();

    if (entry.payment != null) {
      // Update existing record
      await state.updatePaymentStatus(entry.payment!.id, status);
    } else {
      // Create new record with a default amount of 0 (teacher can edit later)
      await state.createPayment(
        studentId: entry.student.id,
        studentName: entry.student.name,
        classId: entry.cls.id,
        className: entry.cls.name,
        amount: 0,
        dueDate: DateTime.now(),
        status: status,
      );
    }
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.poppins(
                color: color, fontSize: 18, fontWeight: FontWeight.w700)),
        Text(label,
            style: GoogleFonts.poppins(
                color: AppColors.textSecondary, fontSize: 10)),
      ]),
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  const _FilterChip(
      {required this.label,
      required this.isSelected,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? c : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? c : AppColors.border),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }
}

// ── Student Payment Card ──────────────────────────────────────────────────────

class _StudentPaymentCard extends StatelessWidget {
  final _StudentEntry entry;
  final VoidCallback onMarkPaid;
  final VoidCallback onMarkDue;
  final VoidCallback onMarkOverdue;

  const _StudentPaymentCard({
    required this.entry,
    required this.onMarkPaid,
    required this.onMarkDue,
    required this.onMarkOverdue,
  });

  Color get _statusColor {
    if (entry.payment == null) return AppColors.textMuted;
    switch (entry.payment!.status) {
      case PaymentStatus.paid:
        return AppColors.success;
      case PaymentStatus.due:
        return AppColors.warning;
      case PaymentStatus.overdue:
        return AppColors.error;
    }
  }

  IconData get _statusIcon {
    if (entry.payment == null) return Symbols.help_outline;
    switch (entry.payment!.status) {
      case PaymentStatus.paid:
        return Symbols.check_circle;
      case PaymentStatus.due:
        return Symbols.schedule;
      case PaymentStatus.overdue:
        return Symbols.error;
    }
  }

  String get _statusLabel {
    if (entry.payment == null) return 'Unmarked';
    return entry.payment!.statusLabel;
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = entry.payment?.isPaid == true;
    final isDue = entry.payment?.isDue == true;
    final isOverdue = entry.payment?.isOverdue == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: entry.payment == null
              ? AppColors.border
              : _statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Student info row
        Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              entry.student.avatarInitials,
              style: GoogleFonts.poppins(
                  color: _statusColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.student.name,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Text(entry.cls.name,
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary, fontSize: 12)),
            ]),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_statusIcon, color: _statusColor, size: 12),
              const SizedBox(width: 4),
              Text(_statusLabel,
                  style: GoogleFonts.poppins(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),

        if (entry.payment?.paidDate != null) ...[
          const SizedBox(height: 6),
          Text('Paid on ${_fmt(entry.payment!.paidDate!)}',
              style: GoogleFonts.poppins(
                  color: AppColors.success, fontSize: 11)),
        ],

        const SizedBox(height: 12),

        // Action buttons
        Row(children: [
          // Mark Paid
          Expanded(
            child: GestureDetector(
              onTap: isPaid ? null : onMarkPaid,
              child: Container(
                height: 34,
                decoration: BoxDecoration(
                  color: isPaid ? AppColors.successLight : AppColors.success,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(
                    isPaid ? Symbols.check_circle : Symbols.payments,
                    color: isPaid ? AppColors.success : Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(isPaid ? 'Paid ✓' : 'Mark Paid',
                      style: GoogleFonts.poppins(
                          color: isPaid ? AppColors.success : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Mark Due
          Expanded(
            child: GestureDetector(
              onTap: isDue ? null : onMarkDue,
              child: Container(
                height: 34,
                decoration: BoxDecoration(
                  color: isDue
                      ? AppColors.warningLight
                      : AppColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isDue ? AppColors.warning : AppColors.border),
                ),
                alignment: Alignment.center,
                child: Text('Due',
                    style: GoogleFonts.poppins(
                        color: isDue
                            ? AppColors.warning
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Mark Overdue
          Expanded(
            child: GestureDetector(
              onTap: isOverdue ? null : onMarkOverdue,
              child: Container(
                height: 34,
                decoration: BoxDecoration(
                  color: isOverdue
                      ? AppColors.errorLight
                      : AppColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isOverdue ? AppColors.error : AppColors.border),
                ),
                alignment: Alignment.center,
                child: Text('Overdue',
                    style: GoogleFonts.poppins(
                        color: isOverdue
                            ? AppColors.error
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  String _fmt(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}
