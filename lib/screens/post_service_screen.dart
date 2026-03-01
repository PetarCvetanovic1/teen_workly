import 'package:flutter/material.dart';
import '../utils/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../services/location_service.dart';
import '../services/moderation.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tw_app_bar.dart';
import '../widgets/content_wrap.dart';
import 'home_screen.dart';
import 'login_screen.dart';

const _skills = [
  'Lawn Care',
  'Dog Walking',
  'Tutoring',
  'Babysitting',
  'Pet Sitting',
  'Cleaning',
  'Cooking',
  'Tech Help',
  'Errands',
  'Creative Work',
  'Event Help',
  'Other',
];

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class PostServiceScreen extends StatefulWidget {
  const PostServiceScreen({super.key});

  @override
  State<PostServiceScreen> createState() => _PostServiceScreenState();
}

class _PostServiceScreenState extends State<PostServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _otherSkillCtrl = TextEditingController();
  final _minPriceCtrl = TextEditingController();
  final _maxPriceCtrl = TextEditingController();
  final Set<String> _selectedSkills = {};
  final Set<String> _selectedDays = {};
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  bool _prefilled = false;
  bool _loginRedirectQueued = false;

  void _queueLoginRedirectIfNeeded(AppState state) {
    if (_loginRedirectQueued || state.isLoggedIn) return;
    _loginRedirectQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        SmoothPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_prefilled) {
      final state = context.read<AppState>();
      final loc = state.userLocationText.isNotEmpty
          ? state.userLocationText
          : state.profile?.location ?? '';
      if (loc.isNotEmpty && _locationCtrl.text.isEmpty) {
        _locationCtrl.text = loc;
      }
      if (state.isLoggedIn && _nameCtrl.text.isEmpty) {
        _nameCtrl.text = state.currentUserName;
      }
      _prefilled = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    _otherSkillCtrl.dispose();
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<AppState>();
    _queueLoginRedirectIfNeeded(state);

    if (!state.isLoggedIn) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: TwAppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        onLogoTap: () => Navigator.of(context).pushAndRemoveUntil(
          SmoothPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        ),
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
                  'Offer Your Skills',
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
                'Let people in your area know what you can do and when you\'re free.',
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
                      _label('YOUR NAME'),
                      const SizedBox(height: 8),
                      _field(
                        controller: _nameCtrl,
                        hint: 'e.g. Alex Johnson',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                      _label('YOUR NEIGHBORHOOD'),
                      const SizedBox(height: 8),
                      _field(
                        controller: _locationCtrl,
                        hint: 'e.g. Waterloo, ON',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'You can offer service at nearby places (like a library), up to 10 km from your map home location.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _label('WHAT CAN YOU DO?'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _skills.map((s) {
                          final sel = _selectedSkills.contains(s);
                          return _chip(
                            label: s,
                            selected: sel,
                            isDark: isDark,
                            color: const Color(0xFF7C3AED),
                            onTap: () => setState(() {
                              sel
                                  ? _selectedSkills.remove(s)
                                  : _selectedSkills.add(s);
                            }),
                          );
                        }).toList(),
                      ),
                      if (_selectedSkills.contains('Other')) ...[
                        const SizedBox(height: 16),
                        _label('DESCRIBE YOUR SKILL'),
                        const SizedBox(height: 8),
                        _field(
                          controller: _otherSkillCtrl,
                          hint: 'Tell us what else you can do...',
                          isDark: isDark,
                        ),
                      ],
                      const SizedBox(height: 24),
                      _label('WHEN ARE YOU FREE?'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _days.map((d) {
                          final sel = _selectedDays.contains(d);
                          return _chip(
                            label: d,
                            selected: sel,
                            isDark: isDark,
                            color: AppColors.indigo600,
                            onTap: () => setState(() {
                              sel
                                  ? _selectedDays.remove(d)
                                  : _selectedDays.add(d);
                            }),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _timePicker(
                              label: 'FROM',
                              time: _startTime,
                              isDark: isDark,
                              onTap: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: _startTime,
                                );
                                if (t != null) setState(() => _startTime = t);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _timePicker(
                              label: 'TO',
                              time: _endTime,
                              isDark: isDark,
                              onTap: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: _endTime,
                                );
                                if (t != null) setState(() => _endTime = t);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _label('YOUR PRICE RANGE (\$/HR)'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _minPriceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: isDark ? Colors.white : AppColors.slate900,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Min',
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
                                    color: isDark ? const Color(0xFF334155) : AppColors.slate100,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark ? const Color(0xFF334155) : AppColors.slate100,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: const Color(0xFF059669).withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Required';
                                final n = double.tryParse(v.trim());
                                if (n == null) return 'Number';
                                if (n < 5) return 'Min \$5';
                                if (n > 75) return 'Max \$75/hr';
                                return null;
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '–',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _maxPriceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: isDark ? Colors.white : AppColors.slate900,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Max',
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
                                    color: isDark ? const Color(0xFF334155) : AppColors.slate100,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark ? const Color(0xFF334155) : AppColors.slate100,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: const Color(0xFF059669).withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Required';
                                final n = double.tryParse(v.trim());
                                if (n == null) return 'Number';
                                if (n < 5) return 'Min \$5';
                                if (n > 75) return 'Max \$75/hr';
                                final minVal = double.tryParse(_minPriceCtrl.text.trim()) ?? 0;
                                if (n < minVal) return 'Must be ≥ min';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Hourly rate range — max and min must be different, realistic numbers',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _label('ABOUT YOU'),
                      const SizedBox(height: 8),
                      _field(
                        controller: _bioCtrl,
                        hint:
                            'A short intro — what makes you great at this?',
                        isDark: isDark,
                        maxLines: 4,
                        minLength: 8,
                      ),
                      const SizedBox(height: 32),
                      Material(
                        color: isDark ? Colors.white : AppColors.slate900,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 4,
                        shadowColor: Colors.black.withValues(alpha: 0.15),
                        child: InkWell(
                          onTap: _submitting ? null : _submit,
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
                                    'Publish Your Service',
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

  Widget _label(String text) {
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

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    int? minLength,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
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
            color: isDark ? const Color(0xFF334155) : AppColors.slate100,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : AppColors.slate100,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.indigo600.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        suffixIcon: readOnly
            ? const Icon(Icons.lock_rounded, color: Color(0xFF94A3B8), size: 18)
            : null,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (minLength != null && v.trim().length < minLength) {
          return 'At least $minLength characters';
        }
        return null;
      },
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required bool isDark,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color
              : isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? color
                : isDark
                    ? const Color(0xFF334155)
                    : AppColors.slate100,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
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

  Widget _timePicker({
    required String label,
    required TimeOfDay time,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0F172A).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : AppColors.slate100,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 18,
              color: AppColors.indigo600,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time.format(context),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _submitting = false;

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final appState = context.read<AppState>();
    if (appState.amReportSuspended) {
      final left = appState.reportSuspensionTimeLeft(appState.currentUserId);
      final days = (left.inHours / 24).ceil();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.block_rounded, color: Color(0xFFDC2626)),
              SizedBox(width: 8),
              Text('Account Suspended'),
            ],
          ),
          content: Text(
            'Your account has been suspended due to multiple reports. '
            'Suspension ends in ${days > 0 ? "$days day${days == 1 ? "" : "s"}" : "a few hours"}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final homeLocation = appState.userLocationText.isNotEmpty
        ? appState.userLocationText
        : (appState.profile?.location ?? '');
    final locationValidation = await LocationService.validateWithinHomeRadius(
      homeLocation: homeLocation,
      postingLocation: _locationCtrl.text.trim(),
    );
    if (locationValidation != null) {
      if (!mounted) return;
      _showModerationWarning(locationValidation);
      return;
    }

    setState(() => _submitting = true);

    final result = await ModerationService.moderateService(
      providerName: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      skills: Set.from(_selectedSkills),
      otherSkill: _selectedSkills.contains('Other')
          ? _otherSkillCtrl.text.trim()
          : null,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (!result.approved) {
      _showModerationWarning(result.reason!);
      return;
    }

    final state = context.read<AppState>();
    final service = Service(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      providerName: _nameCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      skills: Set.from(_selectedSkills),
      otherSkill: _selectedSkills.contains('Other')
          ? _otherSkillCtrl.text.trim()
          : null,
      availableDays: Set.from(_selectedDays),
      startTime: _startTime,
      endTime: _endTime,
      bio: _bioCtrl.text.trim(),
      providerId: state.currentUserId,
      createdAt: DateTime.now(),
      minPrice: double.tryParse(_minPriceCtrl.text.trim()) ?? 0,
      maxPrice: double.tryParse(_maxPriceCtrl.text.trim()) ?? 0,
    );
    await state.addService(service);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Service posted! Check your Dashboard.'),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
