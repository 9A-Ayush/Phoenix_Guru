import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../core/models.dart';
import '../../core/providers/app_state.dart';
import '../../core/services/feedback_service.dart';
import '../../core/theme/app_theme.dart';

class FeedbackFormScreen extends StatefulWidget {
  const FeedbackFormScreen({super.key});

  @override
  State<FeedbackFormScreen> createState() => _FeedbackFormScreenState();
}

class _FeedbackFormScreenState extends State<FeedbackFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _feedbackService = FeedbackService();

  FeedbackType _selectedType = FeedbackType.bug;
  FeedbackPriority? _selectedPriority;
  String? _selectedCategory;
  bool _isSubmitting = false;
  int _remainingSubmissions = 3;
  int _todaySubmissions = 0;

  static const _categories = [
    'UI/UX',
    'Performance',
    'Content',
    'Authentication',
    'Classes',
    'Tests & Quizzes',
    'Live Sessions',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadSubmissionCount();
  }

  Future<void> _loadSubmissionCount() async {
    final appState = context.read<AppState>();
    if (appState.currentUser == null) return;

    try {
      final count = await _feedbackService.getTodaySubmissionCount(appState.currentUser!.id);
      setState(() {
        _todaySubmissions = count;
        _remainingSubmissions = 3 - count;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = context.read<AppState>();
    if (appState.currentUser == null) {
      _showError('You must be logged in to submit feedback');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final feedback = FeedbackModel(
        userId: appState.currentUser!.id,
        userName: appState.currentUser!.name,
        userRole: appState.currentUser!.role,
        type: _selectedType,
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        category: _selectedCategory,
      );

      await _feedbackService.submitFeedback(feedback);

      if (!mounted) return;

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _SuccessDialog(ticketId: feedback.id),
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final hPad = screenWidth < 360 ? 16.0 : 24.0;
    final isLimitReached = _remainingSubmissions <= 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────────
                Row(
                  children: [
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
                    Text(
                      'Submit Feedback',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Submission counter ───────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isLimitReached
                        ? AppColors.errorLight
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLimitReached ? AppColors.error : AppColors.primary,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isLimitReached ? Symbols.block : Symbols.info,
                        color: isLimitReached ? AppColors.error : AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isLimitReached
                              ? 'Daily limit reached ($_todaySubmissions/3). Try again tomorrow.'
                              : 'Submissions today: $_todaySubmissions/3 • $_remainingSubmissions remaining',
                          style: GoogleFonts.poppins(
                            color: isLimitReached
                                ? AppColors.error
                                : AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

                const SizedBox(height: 24),

                // ── Issue Type ───────────────────────────────────────────────
                _buildSectionLabel('Issue Type *'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildTypeChip(
                      type: FeedbackType.bug,
                      label: 'Bug Report',
                      icon: Symbols.bug_report,
                    ),
                    const SizedBox(width: 8),
                    _buildTypeChip(
                      type: FeedbackType.feature,
                      label: 'Feature Request',
                      icon: Symbols.lightbulb,
                    ),
                    const SizedBox(width: 8),
                    _buildTypeChip(
                      type: FeedbackType.general,
                      label: 'General',
                      icon: Symbols.chat,
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 24),

                // ── Subject ──────────────────────────────────────────────────
                _buildSectionLabel('Subject *'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _subjectController,
                  maxLength: 100,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Brief title of your issue or suggestion',
                    counterStyle: GoogleFonts.poppins(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Subject is required';
                    }
                    if (value.trim().length < 5) {
                      return 'Subject must be at least 5 characters';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 20),

                // ── Description ──────────────────────────────────────────────
                _buildSectionLabel('Description *'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descriptionController,
                  maxLength: 1000,
                  maxLines: 6,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText:
                        'Provide detailed information about the issue or your suggestion...',
                    counterStyle: GoogleFonts.poppins(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Description is required';
                    }
                    if (value.trim().length < 20) {
                      return 'Please provide more details (min 20 characters)';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 20),

                // ── Category ─────────────────────────────────────────────────
                _buildSectionLabel('Category (Optional)'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  dropdownColor: AppColors.surface,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(hintText: 'Select a category'),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCategory = value),
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 20),

                // ── Priority ─────────────────────────────────────────────────
                _buildSectionLabel('Priority (Optional)'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildPriorityChip(FeedbackPriority.low, 'Low'),
                    const SizedBox(width: 8),
                    _buildPriorityChip(FeedbackPriority.medium, 'Medium'),
                    const SizedBox(width: 8),
                    _buildPriorityChip(FeedbackPriority.high, 'High'),
                  ],
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 32),

                // ── Submit Button ─────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLimitReached || _isSubmitting
                        ? null
                        : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.surface2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Submit Feedback',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isLimitReached
                                  ? AppColors.textMuted
                                  : Colors.white,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTypeChip({
    required FeedbackType type,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(FeedbackPriority priority, String label) {
    final isSelected = _selectedPriority == priority;
    Color chipColor;
    switch (priority) {
      case FeedbackPriority.low:
        chipColor = AppColors.success;
        break;
      case FeedbackPriority.medium:
        chipColor = AppColors.warning;
        break;
      case FeedbackPriority.high:
        chipColor = AppColors.error;
        break;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPriority = priority),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? chipColor.withValues(alpha: 0.2) : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? chipColor : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: isSelected ? chipColor : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final String ticketId;

  const _SuccessDialog({required this.ticketId});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Symbols.check_circle,
                color: AppColors.success,
                size: 36,
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 20),
            Text(
              'Feedback Submitted!',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Thank you for your feedback. We\'ll review it and get back to you soon.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ticket ID: ',
                    style: GoogleFonts.poppins(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    ticketId.substring(0, 8).toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
