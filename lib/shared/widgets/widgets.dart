import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/theme/app_theme.dart';

// ── Status Bar ──────────────────────────────────────────────────────────────

class PhoenixStatusBar extends StatelessWidget {
  const PhoenixStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('9:41',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          Row(children: const [
            Icon(Symbols.signal_cellular_alt, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Icon(Symbols.wifi, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Icon(Symbols.battery_full, color: Colors.white, size: 18),
          ]),
        ],
      ),
    );
  }
}

// ── Input Field ─────────────────────────────────────────────────────────────

class AppInput extends StatelessWidget {
  final String label;
  final String hint;
  final IconData prefixIcon;
  final Widget? suffix;
  final bool obscure;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  const AppInput({
    super.key,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.suffix,
    this.obscure = false,
    required this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(prefixIcon, color: AppColors.textMuted, size: 20),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
        ),
      ],
    );
  }
}

// ── Primary Button ───────────────────────────────────────────────────────────

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;
  final Color? color;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                  Text(label,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

// ── Glow Background ─────────────────────────────────────────────────────────

class GlowBg extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double glowRadius;
  final Alignment alignment;

  const GlowBg({
    super.key,
    required this.child,
    this.glowColor = AppColors.primary,
    this.glowRadius = 300,
    this.alignment = Alignment.topLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned(
        left: alignment == Alignment.topLeft ? -80 : null,
        right: alignment == Alignment.topRight ? -80 : null,
        top: -80,
        child: Container(
          width: glowRadius,
          height: glowRadius,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [glowColor.withOpacity(0.35), Colors.transparent]),
          ),
        ),
      ),
      child,
    ]);
  }
}

// ── Stat Card ────────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const StatCard({super.key, required this.icon, required this.value, required this.label, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            Text(label, style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── Class List Item ──────────────────────────────────────────────────────────

class ClassListTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String subtitle;
  final VoidCallback? onTap;

  const ClassListTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 76,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.13), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(name, style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle, style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12)),
            ],
          )),
          const Icon(Symbols.chevron_right, color: AppColors.textMuted, size: 20),
        ]),
      ),
    );
  }
}

// ── Student Tab Bar ──────────────────────────────────────────────────────────

class StudentTabBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const StudentTabBar({super.key, required this.currentIndex, required this.onTap});

  static const _items = [
    (Symbols.home, 'HOME'),
    (Symbols.menu_book, 'CLASSES'),
    (Symbols.description, 'MATERIAL'),
    (Symbols.sports_esports, 'QUIZ'),
    (Symbols.person, 'PROFILE'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(21, 12, 21, 21),
      color: AppColors.bg,
      child: Container(
        height: 62,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: List.generate(_items.length, (i) {
            final active = i == currentIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_items[i].$1, color: active ? Colors.white : AppColors.textMuted, size: 17),
                      const SizedBox(height: 3),
                      Text(_items[i].$2,
                          style: GoogleFonts.poppins(
                              color: active ? Colors.white : AppColors.textMuted,
                              fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Teacher Tab Bar ──────────────────────────────────────────────────────────

class TeacherTabBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const TeacherTabBar({super.key, required this.currentIndex, required this.onTap});

  static const _items = [
    (Symbols.home, 'HOME'),
    (Symbols.groups, 'CLASSES'),
    (Symbols.edit_note, 'TESTS'),
    (Symbols.live_tv, 'QUIZ'),
    (Symbols.person, 'PROFILE'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(21, 12, 21, 21),
      color: AppColors.bg,
      child: Container(
        height: 62,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: List.generate(_items.length, (i) {
            final active = i == currentIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_items[i].$1, color: active ? Colors.white : AppColors.textMuted, size: 17),
                      const SizedBox(height: 3),
                      Text(_items[i].$2,
                          style: GoogleFonts.poppins(
                              color: active ? Colors.white : AppColors.textMuted,
                              fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Menu Row ─────────────────────────────────────────────────────────────────

class MenuRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  const MenuRow({super.key, required this.icon, required this.iconColor, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))),
          const Icon(Symbols.chevron_right, color: AppColors.textMuted, size: 20),
        ]),
      ),
    );
  }
}

// ── Back Button ──────────────────────────────────────────────────────────────

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        height: 36, width: 80,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Symbols.arrow_back, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('Back', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
      ],
    );
  }
}
