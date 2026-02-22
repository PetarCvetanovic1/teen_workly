import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/logo_title.dart';
import '../widgets/app_bar_nav.dart';
import '../widgets/auth_button.dart';
import '../widgets/content_wrap.dart';
import 'home_screen.dart';

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
  final Set<String> _selectedSkills = {};
  final Set<String> _selectedDays = {};
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    _otherSkillCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
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
                      _label('ABOUT YOU'),
                      const SizedBox(height: 8),
                      _field(
                        controller: _bioCtrl,
                        hint:
                            'A short intro — what makes you great at this?',
                        isDark: isDark,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 32),
                      Material(
                        color: isDark ? Colors.white : AppColors.slate900,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 4,
                        shadowColor: Colors.black.withValues(alpha: 0.15),
                        child: InkWell(
                          onTap: _submit,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Text(
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
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
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

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
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
      );
      state.addService(service);
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
  }
}
