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
import 'contact_screen.dart';
import 'dashboard_screen.dart';

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
  final Service? initialService;
  const PostServiceScreen({super.key, this.initialService});

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
  bool _pickedStartTime = false;
  bool _pickedEndTime = false;
  double _workRadiusKm = 5;
  String? _editingServiceId;
  DateTime? _editingCreatedAt;
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
      _prefilled = true;
      final state = context.read<AppState>();
      if (state.isLoggedIn && _nameCtrl.text.isEmpty) {
        _nameCtrl.text = state.currentUserName;
      }
      final target = widget.initialService ??
          (state.myServices.isNotEmpty ? state.myServices.first : null);
      if (target != null) {
        _loadExistingService(target);
      }
      Future.microtask(_prefillLocationField);
    }
  }

  void _loadExistingService(Service service) {
    _editingServiceId = service.id;
    _editingCreatedAt = service.createdAt;
    _nameCtrl.text = service.providerName;
    _locationCtrl.text = service.location;
    _bioCtrl.text = service.bio;
    _selectedSkills
      ..clear()
      ..addAll(service.skills);
    if ((service.otherSkill ?? '').trim().isNotEmpty) {
      _selectedSkills.add('Other');
      _otherSkillCtrl.text = service.otherSkill!.trim();
    } else {
      _otherSkillCtrl.clear();
    }
    _selectedDays
      ..clear()
      ..addAll(service.availableDays);
    _startTime = service.startTime;
    _endTime = service.endTime;
    _pickedStartTime = true;
    _pickedEndTime = true;
    _workRadiusKm = service.workRadiusKm;
    _minPriceCtrl.text =
        service.minPrice > 0 ? service.minPrice.toStringAsFixed(0) : '';
    _maxPriceCtrl.text =
        service.maxPrice > 0 ? service.maxPrice.toStringAsFixed(0) : '';
  }

  Future<void> _prefillLocationField() async {
    if (_locationCtrl.text.isNotEmpty) return;
    final postal = await LocationService.fetchCurrentPostalCode();
    if (!mounted) return;
    if (postal != null && postal.isNotEmpty) {
      _locationCtrl.text = postal;
      return;
    }
    final state = context.read<AppState>();
    final loc = state.userLocationText.isNotEmpty
        ? state.userLocationText
        : state.profile?.location ?? '';
    if (loc.isNotEmpty && _locationCtrl.text.isEmpty) {
      _locationCtrl.text = loc;
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
                  _editingServiceId == null ? 'Offer Your Skills' : 'Edit Your Service',
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
                _editingServiceId == null
                    ? 'Let people in your area know what you can do and when you\'re free.'
                    : 'You can only publish one service. Update your existing one below.',
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
              if (state.myServices.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Make sure everything is correct - you can only publish one service.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF92400E),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
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
                      const SizedBox(height: 14),
                      _label('HOW FAR WILL YOU TRAVEL FOR WORK?'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : AppColors.slate100,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.near_me_rounded,
                                    size: 16, color: AppColors.indigo600),
                                const SizedBox(width: 8),
                                Text(
                                  'Up to ${_workRadiusKm.toStringAsFixed(0)} km from your home area',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.slate900,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _workRadiusKm,
                              min: 1,
                              max: 10,
                              divisions: 9,
                              label: '${_workRadiusKm.toStringAsFixed(0)} km',
                              onChanged: (v) =>
                                  setState(() => _workRadiusKm = v),
                            ),
                          ],
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
                                if (t != null) {
                                  setState(() {
                                    _startTime = t;
                                    _pickedStartTime = true;
                                  });
                                }
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
                                if (t != null) {
                                  setState(() {
                                    _endTime = t;
                                    _pickedEndTime = true;
                                  });
                                }
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
                                    _editingServiceId == null
                                        ? 'Publish Your Service'
                                        : 'Update Your Service',
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
    if (_selectedDays.isEmpty) {
      if (!mounted) return;
      _showModerationWarning(
          'Please select at least one available day before posting.');
      return;
    }
    if (!_pickedStartTime || !_pickedEndTime) {
      if (!mounted) return;
      _showModerationWarning(
          'Please pick both start and end time so people know your exact hours.');
      return;
    }
    final startMins = _startTime.hour * 60 + _startTime.minute;
    final endMins = _endTime.hour * 60 + _endTime.minute;
    if (endMins <= startMins) {
      if (!mounted) return;
      _showModerationWarning('End time must be after start time.');
      return;
    }

    final appState = context.read<AppState>();
    if (appState.amReportSuspended) {
      _showReportBanAppealDialog(appState);
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
    final isMinorProvider = (state.profile?.age ?? 18) < 18;
    final rawLocation = _locationCtrl.text.trim();
    final publicLocation = isMinorProvider
        ? LocationService.approximatePublicLocation(rawLocation,
            radiusMeters: 500)
        : null;
    final service = Service(
      id: _editingServiceId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      providerName: _nameCtrl.text.trim(),
      location: rawLocation,
      isMinorProvider: isMinorProvider,
      publicLocation: publicLocation,
      skills: Set.from(_selectedSkills),
      otherSkill: _selectedSkills.contains('Other')
          ? _otherSkillCtrl.text.trim()
          : null,
      availableDays: Set.from(_selectedDays),
      startTime: _startTime,
      endTime: _endTime,
      bio: _bioCtrl.text.trim(),
      providerId: state.currentUserId,
      createdAt: _editingCreatedAt ?? DateTime.now(),
      workRadiusKm: _workRadiusKm,
      minPrice: double.tryParse(_minPriceCtrl.text.trim()) ?? 0,
      maxPrice: double.tryParse(_maxPriceCtrl.text.trim()) ?? 0,
    );
    try {
      if (_editingServiceId != null) {
        await state.updateService(service);
      } else {
        await state.addService(service);
      }
    } catch (e) {
      if (!mounted) return;
      _showModerationWarning(e.toString().replaceFirst('Exception: ', ''));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _editingServiceId == null
              ? 'Service posted! Check your Dashboard.'
              : 'Service updated! Check your Dashboard.',
        ),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.of(context).pushAndRemoveUntil(
      SmoothPageRoute(builder: (_) => const DashboardScreen()),
      (_) => false,
    );
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

  void _showReportBanAppealDialog(AppState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPermanent = state.isUserReportPermanentlyBanned(state.currentUserId);
    final left = state.reportSuspensionTimeLeft(state.currentUserId);
    final days = (left.inHours / 24).ceil();
    final statusText = isPermanent
        ? 'Your account is currently suspended from posting due to report limits (20 all-time).'
        : 'Your account is currently suspended from posting due to report limits. '
            'Time left: ${days > 0 ? "$days day${days == 1 ? "" : "s"}" : "a few hours"}.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Expanded(child: Text('Posting Suspended')),
          ],
        ),
        content: Text(
          '$statusText\n\nIf you think this ban is unfair, contact us and explain what happened and where we should review.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                SmoothPageRoute(
                  builder: (_) => const ContactScreen.prefilled(
                    initialSubject: 'Ban appeal - report suspension',
                    initialMessage:
                        'I think my report ban may be unfair.\n\nWhat happened:\n- \n\nWhere to review:\n- (job/service/post/conversation ID)\n\nAnything else that may help:\n- ',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.mail_outline_rounded, size: 16),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.indigo600,
            ),
            label: const Text('Contact us'),
          ),
        ],
      ),
    );
  }
}
