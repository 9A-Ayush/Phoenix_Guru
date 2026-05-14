import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';

// ── Material Page ─────────────────────────────────────────────────────────────
class StudentMaterialPage extends StatelessWidget {
  const StudentMaterialPage({super.key});

  static const _files = [
    (Symbols.picture_as_pdf, AppColors.accent,   'Chapter 4 - Motion Notes',      'Physics  •  2.4 MB  •  PDF'),
    (Symbols.description,    AppColors.primary,  'Algebra Formula Sheet',          'Maths  •  1.1 MB  •  PDF'),
    (Symbols.image,          AppColors.success,  'History Map - India 1857',       'History  •  3.8 MB  •  Image'),
    (Symbols.picture_as_pdf, AppColors.warning,  'Maths Practice Paper Set 2',     'Maths  •  5.2 MB  •  PDF'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Text('Study Material',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: ['All', 'PDFs', 'Notes'].asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                height: 36,
                width: 80,
                decoration: BoxDecoration(
                  color: e.key == 0 ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(e.value,
                    style: GoogleFonts.poppins(
                        color: e.key == 0 ? Colors.white : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            itemCount: _files.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final f = _files[i];
              return Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: f.$2.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(14)),
                    child: Icon(f.$1, color: f.$2, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Text(f.$3,
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      Text(f.$4,
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ]),
                  ),
                  const Icon(Symbols.download, color: AppColors.primary, size: 22),
                ]),
              ).animate().fadeIn(delay: (i * 60).ms);
            },
          ),
        ),
      ]),
    );
  }
}
