import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';

// ── Shared helpers used across teacher pages ──────────────────────────────────

String getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning 🌤';
  if (hour < 17) return 'Good Afternoon ☀️';
  if (hour < 21) return 'Good Evening 🌆';
  return 'Good Night 🌙';
}

IconData subjectIcon(String s) {
  if (s.toLowerCase().contains('physics')) return Symbols.science;
  if (s.toLowerCase().contains('math')) return Symbols.calculate;
  if (s.toLowerCase().contains('hist')) return Symbols.history_edu;
  return Symbols.school;
}

Color teacherColor(int i) {
  const c = [
    AppColors.primary,
    AppColors.warning,
    AppColors.success,
    AppColors.accent
  ];
  return c[i % c.length];
}

// ── Empty State ───────────────────────────────────────────────────────────────

class TeacherEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  final String? actionLabel;
  final VoidCallback? onAction;

  const TeacherEmptyState({
    super.key,
    required this.icon,
    required this.message,
    required this.sub,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: AppColors.textMuted, size: 52),
      const SizedBox(height: 12),
      Text(message,
          style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(sub,
          style:
              GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 13),
          textAlign: TextAlign.center),
      if (actionLabel != null) ...[
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onAction,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(actionLabel!,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    ]);
  }
}

// ── Menu Item (used in test menu sheet) ───────────────────────────────────────

class TeacherMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const TeacherMenuItem({
    super.key,
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
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: destructive ? AppColors.errorLight : AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: destructive
                ? AppColors.error.withValues(alpha: 0.2)
                : AppColors.border,
          ),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
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
