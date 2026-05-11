import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Local toggle state — loaded from Firestore on init
  bool _classActivity = true;
  bool _testReminders = true;
  bool _studentJoins = true;
  bool _quizResults = false;
  bool _appUpdates = false;
  bool _loading = true;
  bool _saving = false;
  DateTime? _lastSave;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final uid = context.read<AppState>().currentUser?.id;
    if (uid == null) { setState(() => _loading = false); return; }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final prefs = doc.data()?['notificationPrefs'] as Map<String, dynamic>?;
      if (prefs != null && mounted) {
        setState(() {
          _classActivity = prefs['classActivity'] ?? true;
          _testReminders = prefs['testReminders'] ?? true;
          _studentJoins  = prefs['studentJoins']  ?? true;
          _quizResults   = prefs['quizResults']   ?? false;
          _appUpdates    = prefs['appUpdates']    ?? false;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final now = DateTime.now();
    if (_lastSave != null && now.difference(_lastSave!) < const Duration(seconds: 3)) {
      return; // debounce
    }
    _lastSave = now;
    final uid = context.read<AppState>().currentUser?.id;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'notificationPrefs': {
          'classActivity': _classActivity,
          'testReminders': _testReminders,
          'studentJoins':  _studentJoins,
          'quizResults':   _quizResults,
          'appUpdates':    _appUpdates,
        },
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Preferences saved',
            style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save: $e',
            style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
    if (mounted) setState(() => _saving = false);
  }

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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                Text('Notifications',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                // Save button
                GestureDetector(
                  onTap: _saving ? null : _save,
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: _saving
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Save',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ListView(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    children: [
                      _SectionLabel('Class Activity').animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 8),
                      _NotifTile(
                        icon: Symbols.groups,
                        iconColor: AppColors.primary,
                        title: 'Class Activity',
                        subtitle: 'Student joins, leaves and activity',
                        value: _classActivity,
                        onChanged: (v) => setState(() => _classActivity = v),
                        delay: 120,
                      ),
                      _NotifTile(
                        icon: Symbols.person_add,
                        iconColor: AppColors.warning,
                        title: 'Student Joins',
                        subtitle: 'When a student joins your class',
                        value: _studentJoins,
                        onChanged: (v) => setState(() => _studentJoins = v),
                        delay: 160,
                      ),

                      const SizedBox(height: 20),
                      _SectionLabel('Tests & Quizzes').animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 8),
                      _NotifTile(
                        icon: Symbols.assignment,
                        iconColor: AppColors.success,
                        title: 'Test Reminders',
                        subtitle: 'Upcoming test alerts',
                        value: _testReminders,
                        onChanged: (v) => setState(() => _testReminders = v),
                        delay: 220,
                      ),
                      _NotifTile(
                        icon: Symbols.bar_chart,
                        iconColor: AppColors.accent,
                        title: 'Quiz Results',
                        subtitle: 'When students complete a quiz',
                        value: _quizResults,
                        onChanged: (v) => setState(() => _quizResults = v),
                        delay: 260,
                      ),

                      const SizedBox(height: 20),
                      _SectionLabel('General').animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 8),
                      _NotifTile(
                        icon: Symbols.system_update,
                        iconColor: AppColors.textSecondary,
                        title: 'App Updates',
                        subtitle: 'New features and improvements',
                        value: _appUpdates,
                        onChanged: (v) => setState(() => _appUpdates = v),
                        delay: 320,
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8));
  }
}

class _NotifTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final int delay;

  const _NotifTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        )),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          activeTrackColor: AppColors.primaryLight,
          inactiveThumbColor: AppColors.textMuted,
          inactiveTrackColor: AppColors.surface2,
        ),
      ]),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.05, end: 0);
  }
}
