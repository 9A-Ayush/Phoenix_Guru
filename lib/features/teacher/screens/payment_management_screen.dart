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

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  String _filterStatus = 'all'; // all, paid, due, overdue

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final payments = state.allPayments;
    
    // Filter payments
    final filteredPayments = _filterStatus == 'all'
        ? payments
        : payments.where((p) => p.status.name == _filterStatus).toList();

    // Stats
    final paidCount = payments.where((p) => p.isPaid).length;
    final dueCount = payments.where((p) => p.isDue).length;
    final overdueCount = payments.where((p) => p.isOverdue).length;
    final totalAmount = payments.fold<double>(0, (sum, p) => sum + p.amount);
    final paidAmount = payments.where((p) => p.isPaid).fold<double>(0, (sum, p) => sum + p.amount);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.chevron_left_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text('Payment Management',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 8),

                // Stats cards
                Row(children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Paid',
                      value: '$paidCount',
                      color: AppColors.success,
                      icon: Symbols.check_circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: 'Due',
                      value: '$dueCount',
                      color: AppColors.warning,
                      icon: Symbols.schedule,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: 'Overdue',
                      value: '$overdueCount',
                      color: AppColors.error,
                      icon: Symbols.error,
                    ),
                  ),
                ]).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 16),

                // Amount summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1C1240), Color(0xFF0A0A1A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Collected',
                              style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                          Text('₹${paidAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                  color: AppColors.success,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Total Expected',
                              style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                          Text('₹${totalAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 20),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: _filterStatus == 'all',
                      onTap: () => setState(() => _filterStatus = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Paid',
                      isSelected: _filterStatus == 'paid',
                      onTap: () => setState(() => _filterStatus = 'paid'),
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Due',
                      isSelected: _filterStatus == 'due',
                      onTap: () => setState(() => _filterStatus = 'due'),
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Overdue',
                      isSelected: _filterStatus == 'overdue',
                      onTap: () => setState(() => _filterStatus = 'overdue'),
                      color: AppColors.error,
                    ),
                  ]),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 16),

                // Payment list
                if (filteredPayments.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text('No payments found',
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary)),
                    ),
                  )
                else
                  ...filteredPayments.asMap().entries.map((e) {
                    final i = e.key;
                    final payment = e.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PaymentCard(
                        payment: payment,
                        onStatusChange: (newStatus) {
                          context.read<AppState>().updatePaymentStatus(
                                payment.id,
                                newStatus,
                              );
                        },
                      ),
                    ).animate().fadeIn(delay: (250 + i * 50).ms);
                  }),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value,
            style: GoogleFonts.poppins(
                color: color, fontSize: 20, fontWeight: FontWeight.w700)),
        Text(label,
            style: GoogleFonts.poppins(
                color: AppColors.textSecondary, fontSize: 11)),
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

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.border,
          ),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }
}

// ── Payment Card ──────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  final StudentPayment payment;
  final Function(PaymentStatus) onStatusChange;

  const _PaymentCard({
    required this.payment,
    required this.onStatusChange,
  });

  Color get _statusColor {
    switch (payment.status) {
      case PaymentStatus.paid:
        return AppColors.success;
      case PaymentStatus.due:
        return AppColors.warning;
      case PaymentStatus.overdue:
        return AppColors.error;
    }
  }

  IconData get _statusIcon {
    switch (payment.status) {
      case PaymentStatus.paid:
        return Symbols.check_circle;
      case PaymentStatus.due:
        return Symbols.schedule;
      case PaymentStatus.overdue:
        return Symbols.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_statusIcon, color: _statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(payment.studentName,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  Text(payment.className,
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Text('₹${payment.amount.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Due: ${_formatDate(payment.dueDate)}',
                style: GoogleFonts.poppins(
                    color: AppColors.textMuted, fontSize: 11),
              ),
              if (payment.isPaid && payment.paidDate != null)
                Text(
                  'Paid: ${_formatDate(payment.paidDate!)}',
                  style: GoogleFonts.poppins(
                      color: AppColors.success, fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: payment.isPaid
                    ? null
                    : () => onStatusChange(PaymentStatus.paid),
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: payment.isPaid
                        ? AppColors.successLight
                        : AppColors.success,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    payment.isPaid ? 'Paid ✓' : 'Mark as Paid',
                    style: GoogleFonts.poppins(
                        color: payment.isPaid
                            ? AppColors.success
                            : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            if (!payment.isPaid) ...[
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => onStatusChange(
                      payment.isDue ? PaymentStatus.overdue : PaymentStatus.due),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      payment.isDue ? 'Mark Overdue' : 'Mark Due',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ]),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
