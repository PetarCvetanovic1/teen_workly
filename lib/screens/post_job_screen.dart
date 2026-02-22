import 'package:flutter/material.dart';
import '../utils/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../services/moderation.dart';
import '../widgets/app_drawer.dart';
import '../widgets/logo_title.dart';
import '../widgets/app_bar_nav.dart';
import '../widgets/auth_button.dart';
import '../widgets/content_wrap.dart';
import 'home_screen.dart';

const _jobTypes = ['Part-time', 'Seasonal', 'One-time'];

const _serviceCategories = [
  'Outdoor',
  'Pet Care',
  'Tutoring',
  'Retail',
  'Tech',
  'Events',
  'Housework',
  'Creative',
  'Other',
];

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _otherServiceCtrl = TextEditingController();
  final _payCtrl = TextEditingController();
  String _selectedType = _jobTypes.first;
  final Set<String> _selectedServices = {};
  bool _locationPrefilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_locationPrefilled) {
      final state = context.read<AppState>();
      final loc = state.userLocationText.isNotEmpty
          ? state.userLocationText
          : state.profile?.location ?? '';
      if (loc.isNotEmpty && _locationCtrl.text.isEmpty) {
        _locationCtrl.text = loc;
      }
      _locationPrefilled = true;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _otherServiceCtrl.dispose();
    _payCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 4,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: LogoTitle(
                onTap: () => Navigator.of(context).pushAndRemoveUntil(
                  SmoothPageRoute(builder: (_) => const HomeScreen()),
                  (_) => false,
                ),
              ),
            ),
            const Center(child: AppBarNav()),
          ],
        ),
        actions: const [AuthButton()],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: ContentWrap(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Hire Local Talent',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : AppColors.slate900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Post a gig and let teens near you find it instantly.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Form card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 40,
                            offset: const Offset(0, 10),
                          ),
                        ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildLabel('JOB TITLE'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _titleCtrl,
                        hint: 'e.g. Pet Sitter for the Weekend',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                      _buildLabel('JOB TYPE'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _jobTypes.map((type) {
                          final selected = _selectedType == type;
                          return _buildChip(
                            label: type,
                            selected: selected,
                            isDark: isDark,
                            onTap: () =>
                                setState(() => _selectedType = type),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      _buildLabel('WORK LOCATION'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _locationCtrl,
                        hint: 'Neighborhood or Street',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                      _buildLabel('DESCRIPTION'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _descCtrl,
                        hint: 'Tell the teens what they\'ll be doing...',
                        isDark: isDark,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 24),
                      _buildLabel('SERVICES NEEDED'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _serviceCategories.map((svc) {
                          final selected = _selectedServices.contains(svc);
                          return _buildChip(
                            label: svc,
                            selected: selected,
                            isDark: isDark,
                            onTap: () => setState(() {
                              if (selected) {
                                _selectedServices.remove(svc);
                              } else {
                                _selectedServices.add(svc);
                              }
                            }),
                          );
                        }).toList(),
                      ),
                      if (_selectedServices.contains('Other')) ...[
                        const SizedBox(height: 16),
                        _buildLabel('TELL US MORE'),
                        const SizedBox(height: 8),
                        _buildField(
                          controller: _otherServiceCtrl,
                          hint: 'Describe the specific services you\'re looking for...',
                          isDark: isDark,
                          maxLines: 3,
                        ),
                      ],
                      const SizedBox(height: 24),
                      _buildLabel('PAY (TOTAL \$)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _payCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. 25',
                          prefixText: '\$ ',
                          prefixStyle: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: const Color(0xFF059669),
                          ),
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : AppColors.slate100,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : AppColors.slate100,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: const Color(0xFF059669).withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter how much you\'ll pay';
                          final amount = double.tryParse(v.trim());
                          if (amount == null) return 'Enter a valid number';
                          if (amount < 5) return 'Pay must be at least \$5';
                          if (amount > 500) return 'Max \$500 — keep it realistic';
                          return null;
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Total amount you\'ll pay for the job',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Material(
                        color: isDark ? Colors.white : AppColors.slate900,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 4,
                        shadowColor: Colors.black.withValues(alpha: 0.15),
                        child: InkWell(
                          onTap: _submitting ? null : _submitForm,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: _submitting
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: isDark
                                              ? AppColors.slate900
                                              : Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Checking content...',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? AppColors.slate900
                                              : Colors.white,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Launch Job Posting',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? AppColors.slate900
                                          : Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        color: const Color(0xFF94A3B8),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : AppColors.slate900,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w500,
          color: const Color(0xFF94A3B8),
        ),
        filled: true,
        fillColor: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF334155)
                : AppColors.slate100,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF334155)
                : AppColors.slate100,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.indigo600.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.indigo600
              : isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.indigo600
                : isDark
                    ? const Color(0xFF334155)
                    : AppColors.slate100,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.indigo600.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: selected
                ? Colors.white
                : isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  bool _submitting = false;

  void _submitForm() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final state = context.read<AppState>();

    if (state.amReportSuspended) {
      final left = state.reportSuspensionTimeLeft(state.currentUserId);
      final days = (left.inHours / 24).ceil();
      _showModerationWarning(
        'Your account has been suspended due to multiple reports from other users. '
        'Suspension ends in ${days > 0 ? "$days day${days == 1 ? "" : "s"}" : "a few hours"}.',
      );
      return;
    }

    if (state.isPostingSuspended) {
      final hours = state.suspensionTimeLeft.inHours;
      final days = (hours / 24).ceil();
      _showModerationWarning(
        'You\'re currently suspended from posting jobs for '
        '${days > 0 ? "$days day${days == 1 ? "" : "s"}" : "a few hours"}. '
        'This happened because you deleted 3 jobs that already had applicants. '
        'Please wait for the suspension to end.',
      );
      return;
    }

    if (!state.canPostMoreJobs) {
      _showModerationWarning(
        state.isTrustedPoster
            ? 'You\'ve reached the limit of 5 active job postings. '
                'Wait for some to finish before posting more.'
            : 'You can have up to 3 active job postings at a time. '
                'Complete or delete existing jobs to post more. '
                'Trusted posters (5+ completed jobs) can post up to 5.',
      );
      return;
    }

    setState(() => _submitting = true);

    final result = await ModerationService.moderateJob(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      type: _selectedType,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (!result.approved) {
      _showModerationWarning(result.reason!);
      return;
    }

    final job = Job(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      type: _selectedType,
      location: _locationCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      services: Set.from(_selectedServices),
      otherService: _selectedServices.contains('Other')
          ? _otherServiceCtrl.text.trim()
          : null,
      posterId: state.currentUserId,
      posterName: state.currentUserName,
      createdAt: DateTime.now(),
      payment: double.tryParse(_payCtrl.text.trim()) ?? 0,
    );
    state.addJob(job);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Job posted! Check your Dashboard.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  void _showModerationWarning(String reason) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shield_rounded,
                  color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Post Blocked',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.slate900,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          reason,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Got it, I\'ll fix it',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
