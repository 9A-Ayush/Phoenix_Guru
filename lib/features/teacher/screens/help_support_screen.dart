import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/theme/app_theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _expandedIndex;

  static const _faqs = [
    (
      'How do I create a class?',
      'Go to the Classes tab and tap "New Class". Fill in the class name, subject, and description. A 6-digit join code is auto-generated for your students.',
    ),
    (
      'How do students join my class?',
      'Share the 6-digit class code with your students. They can enter it in the "Join Class" section of their student app.',
    ),
    (
      'How do I create and publish a test?',
      'Go to the Tests tab and tap "New Test". Add a title, select a class, set the duration, and add questions using the question builder. Tap "Publish" when ready.',
    ),
    (
      'How does Live Quiz work?',
      'Go to the Quiz tab and tap "Start Live Quiz". Students join using the PIN shown on screen. You can reveal answers and move to the next question in real time.',
    ),
    (
      'Can I edit a test after publishing?',
      'Currently, published tests cannot be edited. You can delete and recreate the test if changes are needed.',
    ),
    (
      'How do I view test results?',
      'Go to the Quiz tab and tap "Test Results". You can see individual scores, grade distribution, and flagged questions.',
    ),
    (
      'How do I change my password?',
      'Go to Profile → Change Password. Enter your current password and your new password. This only works for email/password accounts.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final hPad = screenWidth < 360 ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Text('Help & Support',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
            ]),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
              children: [
                // Hero banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1C1240), Color(0xFF0A0A1A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: Row(children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Symbols.support_agent, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('How can we help?',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('Browse FAQs or contact our support team',
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ])),
                  ]),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                // FAQ section
                Text('Frequently Asked Questions',
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8))
                    .animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 10),

                ..._faqs.asMap().entries.map((e) {
                  final i = e.key;
                  final faq = e.value;
                  final isOpen = _expandedIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _expandedIndex = isOpen ? null : i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        decoration: BoxDecoration(
                          color: isOpen ? AppColors.surface2 : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isOpen ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
                          ),
                        ),
                        child: Column(children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(children: [
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  color: isOpen ? AppColors.primaryLight : AppColors.surface2,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text('Q',
                                    style: GoogleFonts.poppins(
                                        color: isOpen ? AppColors.primary : AppColors.textMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(faq.$1,
                                    style: GoogleFonts.poppins(
                                        color: isOpen ? Colors.white : AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 8),
                              AnimatedRotation(
                                turns: isOpen ? 0.5 : 0,
                                duration: const Duration(milliseconds: 250),
                                child: Icon(
                                  Symbols.keyboard_arrow_down,
                                  color: isOpen ? AppColors.primary : AppColors.textMuted,
                                  size: 20,
                                ),
                              ),
                            ]),
                          ),
                          if (isOpen)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                              child: Text(faq.$2,
                                  style: GoogleFonts.poppins(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      height: 1.5)),
                            ),
                        ]),
                      ),
                    ).animate().fadeIn(delay: (100 + i * 40).ms),
                  );
                }),

                const SizedBox(height: 24),

                // Contact section
                Text('Contact Support',
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8))
                    .animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 10),

                ...[
                  (Symbols.mail, AppColors.primary, 'Email Support', 'support@phoenixguru.app', 'Typically replies in 24h'),
                  (Symbols.chat, AppColors.success, 'Live Chat', 'Available 9AM – 6PM IST', 'Mon – Sat'),
                ].asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: item.$2.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(item.$1, color: item.$2, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item.$3,
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          Text(item.$4,
                              style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary, fontSize: 12)),
                          Text(item.$5,
                              style: GoogleFonts.poppins(
                                  color: AppColors.textMuted, fontSize: 11)),
                        ])),
                        Icon(Symbols.chevron_right, color: AppColors.textMuted, size: 20),
                      ]),
                    ).animate().fadeIn(delay: (480 + i * 60).ms).slideX(begin: 0.05, end: 0),
                  );
                }),

                const SizedBox(height: 24),

                // App version
                Center(
                  child: Text('Phoenix Guru v1.0.0',
                      style: GoogleFonts.poppins(
                          color: AppColors.textMuted, fontSize: 12)),
                ).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
