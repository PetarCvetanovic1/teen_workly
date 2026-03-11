import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../services/moderation.dart';
import '../state/app_state.dart';
import '../utils/smooth_route.dart';
import '../widgets/app_drawer.dart';
import '../widgets/content_wrap.dart';
import '../widgets/tw_app_bar.dart';
import '../widgets/walking_dog_loader.dart';
import 'home_screen.dart';

const _presetSkills = <String>[
  'Lawn Care',
  'Dog Walking',
  'Tutoring',
  'Babysitting',
  'Cleaning',
  'Tech Help',
  'Photography',
  'Cooking',
];

const _presetInterests = <String>[
  'Sports',
  'Gaming',
  'Music',
  'Animals',
  'Technology',
  'Art',
  'Reading',
  'Fitness',
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _customSkillCtrl = TextEditingController();
  final _customInterestCtrl = TextEditingController();

  Set<String> _skills = <String>{};
  Set<String> _interests = <String>{};
  bool _hydrated = false;
  bool _saving = false;
  bool _requestedProfileLoad = false;
  bool _editing = true;
  bool _modeInitialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _bioCtrl.dispose();
    _ageCtrl.dispose();
    _customSkillCtrl.dispose();
    _customInterestCtrl.dispose();
    super.dispose();
  }

  void _hydrate(AppState state) {
    if (_hydrated || state.profile == null) return;
    final p = state.profile!;
    _nameCtrl.text = p.name;
    _locationCtrl.text = p.location ?? '';
    _bioCtrl.text = p.bio ?? '';
    _ageCtrl.text = p.age?.toString() ?? '';
    _skills = Set<String>.from(p.skills);
    _interests = Set<String>.from(p.interests);
    if (!_modeInitialized) {
      final hasSavedDetails = (p.location?.trim().isNotEmpty ?? false) ||
          (p.bio?.trim().isNotEmpty ?? false) ||
          (p.age != null) ||
          p.skills.isNotEmpty ||
          p.interests.isNotEmpty;
      _editing = !hasSavedDetails;
      _modeInitialized = true;
    }
    _hydrated = true;
  }

  Future<void> _save(AppState state) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    for (final tag in _skills) {
      final check = ModerationService.validateProfileField('skill', tag);
      if (!check.approved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(check.reason ?? 'That skill is not allowed.')),
        );
        return;
      }
    }
    for (final tag in _interests) {
      final check = ModerationService.validateProfileField('interest', tag);
      if (!check.approved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(check.reason ?? 'That interest is not allowed.')),
        );
        return;
      }
    }
    setState(() => _saving = true);
    try {
      await state.updateProfile(
        name: _nameCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        age: int.tryParse(_ageCtrl.text.trim()),
        skills: _skills,
        interests: _interests,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _editing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (!state.isLoggedIn) {
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
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'You are logged out.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      SmoothPageRoute(builder: (_) => const HomeScreen()),
                      (_) => false,
                    ),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          );
        }

        final p = state.profile;
        if (p == null) {
          if (!_requestedProfileLoad) {
            _requestedProfileLoad = true;
            Future.microtask(() async {
              await state.ensureProfileLoaded();
              if (mounted) setState(() {});
            });
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
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const WalkingDogLoader(label: 'Loading your profile...'),
                  const SizedBox(height: 12),
                  Text(
                    'Loading your profile...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      await context.read<AppState>().ensureProfileLoaded();
                      if (mounted) setState(() {});
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        _hydrate(state);
        final ageValue = int.tryParse(_ageCtrl.text.trim()) ?? p.age ?? 16;
        final isUnder16 = ageValue < 16;
        final postedCount = state.myPostedJobs.length;
        final appliedCount = state.myAppliedJobs.length;
        final locationLocked = (p.location ?? '').trim().isNotEmpty;
        final completion = _profileCompletion(
          name: _nameCtrl.text,
          location: _locationCtrl.text,
          bio: _bioCtrl.text,
          ageText: _ageCtrl.text,
          skills: _skills,
          interests: _interests,
        );

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
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ContentWrap(
              child: _editing
                  ? Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            'Welcome back, ${_nameCtrl.text.trim().isEmpty ? p.name : _nameCtrl.text.trim()}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Profile glow-up',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isUnder16
                                ? 'Keep it real: show your strengths, interests, and personality.'
                                : 'Build trust fast with clear info and a strong bio.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.indigo600.withValues(alpha: 0.20)
                                  : AppColors.indigo600.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.indigo600.withValues(alpha: 0.24),
                              ),
                            ),
                            child: Text(
                              'Tip: keep it simple and real. A friendly profile gets more replies.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.slate900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _profileStrengthCard(
                            isDark: isDark,
                            completion: completion,
                          ),
                          const SizedBox(height: 12),
                          _firstImpressionCard(
                            isDark: isDark,
                            name: _nameCtrl.text.trim(),
                            location: _locationCtrl.text.trim(),
                            bio: _bioCtrl.text.trim(),
                            skills: _skills,
                          ),
                          const SizedBox(height: 20),
                          _editSectionHeader(
                            isDark: isDark,
                            icon: Icons.person_outline_rounded,
                            title: 'Basics',
                            subtitle: 'Core info people see first',
                            accent: AppColors.indigo600,
                          ),
                          const SizedBox(height: 8),
                          _editSectionCard(
                            isDark: isDark,
                            accent: AppColors.indigo600,
                            child: Column(
                              children: [
                                _field(_nameCtrl, 'Name', validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Required';
                                  if (v.trim().split(RegExp(r'\s+')).length < 2) return 'Enter first + last name';
                                  return null;
                                }, readOnly: true, helperText: 'Name is locked for account safety.'),
                                _field(
                                  _locationCtrl,
                                  'Area',
                                  readOnly: locationLocked,
                                  helperText: locationLocked
                                      ? 'Locked after map location is set. Change it from the map.'
                                      : null,
                                ),
                                _field(_ageCtrl, 'Age', keyboardType: TextInputType.number),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    'Age can only increase by 1, once every 12 months.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _editSectionHeader(
                            isDark: isDark,
                            icon: Icons.notes_rounded,
                            title: 'About You',
                            subtitle: 'Keep this short and friendly',
                            accent: const Color(0xFF7C3AED),
                          ),
                          const SizedBox(height: 8),
                          _editSectionCard(
                            isDark: isDark,
                            accent: const Color(0xFF7C3AED),
                            child: Column(
                              children: [
                                _field(
                                  _bioCtrl,
                                  'Bio',
                                  minLines: 1,
                                  maxLines: 4,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    'Try: "I can help with ___. I am usually free on ___."',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _editSectionHeader(
                            isDark: isDark,
                            icon: Icons.bolt_rounded,
                            title: 'Skills & Interests',
                            subtitle: 'Pick a few so your profile feels real',
                            accent: const Color(0xFF0EA5A4),
                          ),
                          const SizedBox(height: 8),
                          _editSectionCard(
                            isDark: isDark,
                            accent: const Color(0xFF0EA5A4),
                            child: Column(
                              children: [
                                _chipSection(
                                  title: 'What you can help with',
                                  options: _presetSkills,
                                  selected: _skills,
                                  customController: _customSkillCtrl,
                                ),
                                const SizedBox(height: 14),
                                _chipSection(
                                  title: 'Stuff you are into',
                                  options: _presetInterests,
                                  selected: _interests,
                                  customController: _customInterestCtrl,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _saving ? null : () => _save(state),
                              child: _saving
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Save my profile'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _saving ? null : () => setState(() => _editing = false),
                              child: const Text('Done for now'),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'Welcome back, ${_nameCtrl.text.trim().isEmpty ? p.name : _nameCtrl.text.trim()}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.slate900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your profile vibes',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.slate900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This is what people see first.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap any section to edit it (except location).',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _profileStrengthCard(
                          isDark: isDark,
                          completion: completion,
                        ),
                        const SizedBox(height: 20),
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => setState(() => _editing = true),
                          child: _profileTypeCard(
                            isDark: isDark,
                            under16: isUnder16,
                            postedCount: postedCount,
                            appliedCount: appliedCount,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _profileCard(
                          'Full Name',
                          _nameCtrl.text.trim(),
                          isDark,
                          onTap: () => setState(() => _editing = true),
                        ),
                        _profileCard(
                          'Location',
                          _cityOnlyLocation(_locationCtrl.text.trim()),
                          isDark,
                        ),
                        _profileCard(
                          'Age',
                          _ageCtrl.text.trim(),
                          isDark,
                          onTap: () => setState(() => _editing = true),
                        ),
                        _profileCard(
                          'About',
                          _bioCtrl.text.trim(),
                          isDark,
                          onTap: () => setState(() => _editing = true),
                        ),
                        _chipsPreview(
                          'Skills',
                          _skills,
                          isDark,
                          onTap: () => setState(() => _editing = true),
                        ),
                        const SizedBox(height: 10),
                        _chipsPreview(
                          'What you like doing',
                          _interests,
                          isDark,
                          onTap: () => setState(() => _editing = true),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => setState(() => _editing = true),
                            child: const Text('Customize profile'),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _profileCard(
    String label,
    String value,
    bool isDark, {
    VoidCallback? onTap,
  }) {
    final display = value.trim().isEmpty ? 'Not set' : value.trim();
    final base = isDark ? const Color(0xFF1E293B) : Colors.white;
    final tint = AppColors.indigo600.withValues(alpha: isDark ? 0.10 : 0.04);
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint, base],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.slate200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            display,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: onTap == null
          ? card
          : InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: card,
            ),
    );
  }

  Widget _profileTypeCard({
    required bool isDark,
    required bool under16,
    required int postedCount,
    required int appliedCount,
  }) {
    final title = under16 ? 'Under 16 profile' : '16+ work profile';
    final subtitle = under16
        ? 'Community-first mode. Keep growing your skills and applying.'
        : 'Work mode. You can post jobs and manage applicants.';
    final stat = under16
        ? 'Applied jobs: $appliedCount'
        : 'Posted jobs: $postedCount';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.indigo600.withValues(alpha: isDark ? 0.12 : 0.06),
            isDark ? const Color(0xFF1E293B) : Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.slate200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stat,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.indigo600,
            ),
          ),
        ],
      ),
    );
  }

  double _profileCompletion({
    required String name,
    required String location,
    required String bio,
    required String ageText,
    required Set<String> skills,
    required Set<String> interests,
  }) {
    var score = 0;
    if (name.trim().split(RegExp(r'\s+')).length >= 2) score++;
    if (location.trim().isNotEmpty) score++;
    if (bio.trim().length >= 20) score++;
    if (int.tryParse(ageText.trim()) != null) score++;
    if (skills.isNotEmpty) score++;
    if (interests.isNotEmpty) score++;
    return score / 6.0;
  }

  Widget _profileStrengthCard({
    required bool isDark,
    required double completion,
  }) {
    final pct = (completion * 100).round().clamp(0, 100);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.slate200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile strength: $pct%',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completion,
              minHeight: 7,
              backgroundColor: isDark ? const Color(0xFF334155) : AppColors.slate200,
              color: AppColors.indigo600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pct >= 85
                ? 'Looking strong. People will trust this profile.'
                : 'Add a little more detail to boost trust.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _firstImpressionCard({
    required bool isDark,
    required String name,
    required String location,
    required String bio,
    required Set<String> skills,
  }) {
    final previewName = name.isEmpty ? 'Your name' : name;
    final previewLocation = _cityOnlyLocation(location);
    final previewBio = bio.isEmpty
        ? 'Add a short bio so people know what you are about.'
        : bio;
    final skillLine = skills.isEmpty
        ? 'No skills selected yet'
        : skills.take(3).join(' · ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.slate200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'First impression preview',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            previewName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            previewLocation,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            previewBio,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            skillLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.indigo600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipsPreview(
    String title,
    Set<String> values,
    bool isDark, {
    VoidCallback? onTap,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          'Tap to pick, or add your own',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 8),
        if (values.isEmpty)
          Text(
            'Nothing here yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values
                .map(
                  (v) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.indigo600.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : AppColors.slate200,
                      ),
                    ),
                    child: Text(
                      v,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.indigo600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: content,
    );
  }

  Widget _editSectionHeader({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: isDark ? 0.24 : 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.slate900,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _editSectionCard({
    required bool isDark,
    required Color accent,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isDark ? 0.14 : 0.07),
            isDark ? const Color(0xFF1E293B) : Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? accent.withValues(alpha: 0.34)
              : accent.withValues(alpha: 0.22),
        ),
      ),
      child: child,
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    int minLines = 1,
    int? maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        minLines: minLines,
        maxLines: maxLines,
        readOnly: readOnly,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          suffixIcon: readOnly
              ? const Icon(Icons.lock_rounded, size: 18, color: Color(0xFF94A3B8))
              : null,
        ),
      ),
    );
  }

  String _cityOnlyLocation(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'Local area';
    final parts = value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final first = parts.isEmpty ? value : parts.first;
    if (RegExp(r'\d').hasMatch(first) && parts.length > 1) {
      return parts[1];
    }
    if (RegExp(r'\d').hasMatch(first)) return 'Local area';
    return first;
  }

  Widget _chipSection({
    required String title,
    required List<String> options,
    required Set<String> selected,
    required TextEditingController customController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map(
                (o) => FilterChip(
                  label: Text(o),
                  selected: selected.contains(o),
                  onSelected: (v) {
                    setState(() {
                      v ? selected.add(o) : selected.remove(o);
                    });
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: customController,
                decoration: const InputDecoration(hintText: 'Add your own'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                final text = customController.text.trim();
                if (text.isEmpty) return;
                final check = ModerationService.validateProfileField(
                  title.toLowerCase(),
                  text,
                );
                if (!check.approved) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        check.reason ??
                            'That tag is not allowed. Please keep it appropriate.',
                      ),
                    ),
                  );
                  return;
                }
                setState(() => selected.add(text));
                customController.clear();
              },
              child: const Text('Add tag'),
            ),
          ],
        ),
      ],
    );
  }
}
