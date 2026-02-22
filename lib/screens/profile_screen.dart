import 'package:flutter/material.dart';
import '../utils/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/logo_title.dart';
import '../widgets/app_bar_nav.dart';
import '../widgets/auth_button.dart';
import '../widgets/content_wrap.dart';
import '../services/moderation.dart';
import 'home_screen.dart';

const _allSkills = [
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
  'Photography',
  'Music',
  'Sports',
];

const _allInterests = [
  'Making Money',
  'Helping People',
  'Animals',
  'Technology',
  'Art & Design',
  'Fitness',
  'Nature',
  'Gaming',
  'Music',
  'Cooking',
  'Reading',
  'Social Media',
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _schoolCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _bioCtrl;
  late Set<String> _skills;
  late Set<String> _interests;
  bool _isEditing = false;
  bool _aiGenerating = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().profile!;
    _nameCtrl = TextEditingController(text: p.name);
    _locationCtrl = TextEditingController(text: p.location ?? '');
    _schoolCtrl = TextEditingController(text: p.school ?? '');
    _ageCtrl = TextEditingController(
        text: p.age != null ? p.age.toString() : '');
    _bioCtrl = TextEditingController(text: p.bio ?? '');
    _skills = Set.from(p.skills);
    _interests = Set.from(p.interests);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _schoolCtrl.dispose();
    _ageCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppState>(
      builder: (context, state, _) {
        final p = state.profile!;

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
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ContentWrap(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Avatar + name header
                  Container(
                    width: 80,
                    height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.indigo600, Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      p.initials,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      p.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                    if (state.amVerified) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.verified_rounded,
                          color: Color(0xFF059669), size: 24),
                    ],
                  ],
                ),
                if (state.myReviewCount > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...List.generate(5, (i) => Icon(
                            i < state.myRating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 16,
                            color: i < state.myRating.round()
                                ? const Color(0xFFEAB308)
                                : const Color(0xFF94A3B8),
                          )),
                      const SizedBox(width: 6),
                      Text(
                        '${state.myRating.toStringAsFixed(1)} (${state.myReviewCount} reviews)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
                if (p.location != null && p.location!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 15, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        p.location!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                // AI Profile Builder button
                if (!_isEditing)
                  Material(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    elevation: isDark ? 0 : 2,
                    shadowColor: Colors.black.withValues(alpha: 0.06),
                    child: InkWell(
                      onTap: () => _showAiBuilder(context, isDark),
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.indigo600,
                                    Color(0xFF7C3AED),
                                    Color(0xFFEC4899),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.auto_awesome_rounded,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI Profile Builder',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.slate900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tell us about yourself and we\'ll craft your perfect profile',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : AppColors.slate200),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Edit / View toggle
                if (!_isEditing)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit Profile'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                // Profile info cards or edit form
                if (_isEditing)
                  _buildEditForm(isDark)
                else
                  _buildProfileView(isDark, p),
                const SizedBox(height: 48),
              ],
            ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileView(bool isDark, dynamic p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (p.bio != null && (p.bio as String).isNotEmpty) ...[
          _sectionLabel('ABOUT ME'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Text(
              p.bio,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.6,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if ((p.skills as Set).isNotEmpty) ...[
          _sectionLabel('SKILLS'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (p.skills as Set<String>).map((s) => _tag(s, AppColors.indigo600)).toList(),
          ),
          const SizedBox(height: 24),
        ],
        if ((p.interests as Set).isNotEmpty) ...[
          _sectionLabel('INTERESTS'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (p.interests as Set<String>).map((s) => _tag(s, const Color(0xFF7C3AED))).toList(),
          ),
          const SizedBox(height: 24),
        ],
        if ((p.school != null && (p.school as String).isNotEmpty) ||
            p.age != null) ...[
          _sectionLabel('DETAILS'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              children: [
                if (p.school != null && (p.school as String).isNotEmpty)
                  _detailRow(Icons.school_rounded, 'School', p.school),
                if (p.age != null)
                  _detailRow(Icons.cake_rounded, 'Age', '${p.age}'),
              ],
            ),
          ),
        ],
        if (p.bio == null &&
            (p.skills as Set).isEmpty &&
            (p.interests as Set).isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : AppColors.slate200,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 40,
                    color: AppColors.indigo600.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  'Your profile is empty',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Use the AI Profile Builder above or edit manually to get started!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEditForm(bool isDark) {
    return Container(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _formLabel('NAME'),
          const SizedBox(height: 8),
          _formField(_nameCtrl, 'Your name', isDark),
          const SizedBox(height: 20),
          _formLabel('LOCATION'),
          const SizedBox(height: 8),
          _formField(_locationCtrl, 'City, Province', isDark),
          const SizedBox(height: 20),
          _formLabel('SCHOOL'),
          const SizedBox(height: 8),
          _formField(_schoolCtrl, 'Your school name', isDark),
          const SizedBox(height: 20),
          _formLabel('AGE'),
          const SizedBox(height: 8),
          _formField(_ageCtrl, '16', isDark,
              keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          _formLabel('SKILLS'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allSkills.map((s) {
              final sel = _skills.contains(s);
              return _selectableChip(s, sel, AppColors.indigo600, isDark,
                  () {
                setState(() {
                  sel ? _skills.remove(s) : _skills.add(s);
                });
              });
            }).toList(),
          ),
          const SizedBox(height: 20),
          _formLabel('INTERESTS'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allInterests.map((s) {
              final sel = _interests.contains(s);
              return _selectableChip(
                  s, sel, const Color(0xFF7C3AED), isDark, () {
                setState(() {
                  sel ? _interests.remove(s) : _interests.add(s);
                });
              });
            }).toList(),
          ),
          const SizedBox(height: 20),
          _formLabel('BIO'),
          const SizedBox(height: 8),
          _formField(_bioCtrl, 'Tell people about yourself...', isDark,
              maxLines: 4),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isEditing = false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Material(
                  color: isDark ? Colors.white : AppColors.slate900,
                  borderRadius: BorderRadius.circular(14),
                  elevation: 2,
                  child: InkWell(
                    onTap: _saveProfile,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Save',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.slate900 : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _saveProfile() {
    final nameCheck = ModerationService.validateName(_nameCtrl.text.trim());
    if (!nameCheck.approved) {
      _showValidationError(nameCheck.reason!);
      return;
    }

    final locCheck = ModerationService.validateLocation(_locationCtrl.text.trim());
    if (!locCheck.approved) {
      _showValidationError(locCheck.reason!);
      return;
    }

    final ageCheck = ModerationService.validateAge(_ageCtrl.text.trim());
    if (!ageCheck.approved) {
      _showValidationError(ageCheck.reason!);
      return;
    }

    final bioCheck = ModerationService.validateBio(_bioCtrl.text.trim());
    if (!bioCheck.approved) {
      _showValidationError(bioCheck.reason!);
      return;
    }

    final schoolCheck = ModerationService.validateProfileField(
        'school', _schoolCtrl.text.trim());
    if (!schoolCheck.approved) {
      _showValidationError(schoolCheck.reason!);
      return;
    }

    context.read<AppState>().updateProfile(
          name: _nameCtrl.text.trim(),
          location: _locationCtrl.text.trim(),
          school: _schoolCtrl.text.trim(),
          age: int.tryParse(_ageCtrl.text.trim()),
          bio: _bioCtrl.text.trim(),
          skills: Set.from(_skills),
          interests: Set.from(_interests),
        );
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile updated!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showValidationError(String reason) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(reason),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFDC2626),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ---- AI Builder ----

  void _showAiBuilder(BuildContext context, bool isDark) {
    final skillCtrl = TextEditingController();
    final likeCtrl = TextEditingController();
    final personalityCtrl = TextEditingController();
    final goalCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155)
                            : AppColors.slate200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (b) => const LinearGradient(
                        colors: [
                          AppColors.indigo600,
                          Color(0xFF7C3AED),
                          Color(0xFFEC4899),
                        ],
                      ).createShader(b),
                      child: const Icon(Icons.auto_awesome_rounded, size: 40),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'AI Profile Builder',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Answer a few quick questions and we\'ll write a standout profile for you.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _aiField(
                      'What are you good at?',
                      'e.g. mowing lawns, math, cooking, tech stuff',
                      skillCtrl,
                      isDark,
                    ),
                    const SizedBox(height: 16),
                    _aiField(
                      'What do you enjoy doing?',
                      'e.g. playing guitar, walking dogs, coding',
                      likeCtrl,
                      isDark,
                    ),
                    const SizedBox(height: 16),
                    _aiField(
                      'Describe yourself in a few words',
                      'e.g. hard-working, funny, reliable, creative',
                      personalityCtrl,
                      isDark,
                    ),
                    const SizedBox(height: 16),
                    _aiField(
                      'What\'s your goal?',
                      'e.g. save for a car, build experience, help my community',
                      goalCtrl,
                      isDark,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: isDark ? Colors.white : AppColors.slate900,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 4,
                        shadowColor: Colors.black.withValues(alpha: 0.15),
                        child: InkWell(
                          onTap: _aiGenerating
                              ? null
                              : () async {
                                  setSheetState(
                                      () => _aiGenerating = true);

                                  final validation =
                                      await ModerationService
                                          .validateAiBuilderInputs(
                                    skills: skillCtrl.text.trim(),
                                    likes: likeCtrl.text.trim(),
                                    personality:
                                        personalityCtrl.text.trim(),
                                    goal: goalCtrl.text.trim(),
                                  );

                                  if (!validation.approved) {
                                    setSheetState(
                                        () => _aiGenerating = false);
                                    if (!ctx.mounted) return;
                                    ScaffoldMessenger.of(ctx)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            validation.reason ??
                                                'Invalid input'),
                                        behavior:
                                            SnackBarBehavior.floating,
                                        backgroundColor:
                                            const Color(0xFFDC2626),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    12)),
                                      ),
                                    );
                                    return;
                                  }

                                  await Future.delayed(
                                      const Duration(
                                          milliseconds: 1500));
                                  final result = _generateAiProfile(
                                    skills: skillCtrl.text.trim(),
                                    likes: likeCtrl.text.trim(),
                                    personality:
                                        personalityCtrl.text.trim(),
                                    goal: goalCtrl.text.trim(),
                                  );
                                  setSheetState(
                                      () => _aiGenerating = false);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  setState(() {
                                    _bioCtrl.text = result['bio']!;
                                    _skills = Set.from(
                                        result['skills']!.split(','));
                                    _interests = Set.from(
                                        result['interests']!.split(','));
                                  });
                                  if (!context.mounted) return;
                                  context.read<AppState>().updateProfile(
                                    bio: result['bio'],
                                    skills: _skills,
                                    interests: _interests,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                            'Profile built! You can edit it anytime.'),
                                        behavior:
                                            SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  }
                                },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 18),
                            child: _aiGenerating
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: isDark
                                              ? AppColors.slate900
                                              : Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Building your profile...',
                                        style:
                                            GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? AppColors.slate900
                                              : Colors.white,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                          Icons
                                              .auto_awesome_rounded,
                                          size: 18,
                                          color: isDark
                                              ? AppColors.slate900
                                              : Colors.white),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Generate My Profile',
                                        style:
                                            GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? AppColors.slate900
                                              : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, String> _generateAiProfile({
    required String skills,
    required String likes,
    required String personality,
    required String goal,
  }) {
    final skillWords = skills.isNotEmpty
        ? skills
            .split(RegExp(r'[,;]+'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList()
        : <String>[];
    final likeWords = likes.isNotEmpty
        ? likes
            .split(RegExp(r'[,;]+'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList()
        : <String>[];
    final traits = personality.isNotEmpty
        ? personality
            .split(RegExp(r'[,;]+'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList()
        : <String>[];

    final mappedSkills = <String>{};
    final mappedInterests = <String>{};

    for (final w in skillWords) {
      final lower = w.toLowerCase();
      if (lower.contains('lawn') || lower.contains('mow') || lower.contains('yard')) {
        mappedSkills.add('Lawn Care');
      } else if (lower.contains('dog') || lower.contains('walk')) {
        mappedSkills.add('Dog Walking');
      } else if (lower.contains('tutor') || lower.contains('math') || lower.contains('teach')) {
        mappedSkills.add('Tutoring');
      } else if (lower.contains('baby') || lower.contains('kid') || lower.contains('child')) {
        mappedSkills.add('Babysitting');
      } else if (lower.contains('pet') || lower.contains('cat') || lower.contains('animal')) {
        mappedSkills.add('Pet Sitting');
      } else if (lower.contains('clean')) {
        mappedSkills.add('Cleaning');
      } else if (lower.contains('cook') || lower.contains('bak')) {
        mappedSkills.add('Cooking');
      } else if (lower.contains('tech') || lower.contains('computer') || lower.contains('code') || lower.contains('program')) {
        mappedSkills.add('Tech Help');
      } else if (lower.contains('errand') || lower.contains('deliver')) {
        mappedSkills.add('Errands');
      } else if (lower.contains('creat') || lower.contains('art') || lower.contains('design') || lower.contains('draw')) {
        mappedSkills.add('Creative Work');
      } else if (lower.contains('event') || lower.contains('party') || lower.contains('set up')) {
        mappedSkills.add('Event Help');
      } else if (lower.contains('photo') || lower.contains('camera')) {
        mappedSkills.add('Photography');
      } else if (lower.contains('music') || lower.contains('guitar') || lower.contains('piano') || lower.contains('drum') || lower.contains('sing')) {
        mappedSkills.add('Music');
      } else if (lower.contains('sport') || lower.contains('coach') || lower.contains('fitness')) {
        mappedSkills.add('Sports');
      }
    }

    for (final w in likeWords) {
      final lower = w.toLowerCase();
      if (lower.contains('money') || lower.contains('earn') || lower.contains('save')) {
        mappedInterests.add('Making Money');
      } else if (lower.contains('help') || lower.contains('volunteer')) {
        mappedInterests.add('Helping People');
      } else if (lower.contains('animal') || lower.contains('dog') || lower.contains('pet') || lower.contains('cat')) {
        mappedInterests.add('Animals');
      } else if (lower.contains('tech') || lower.contains('code') || lower.contains('computer') || lower.contains('program')) {
        mappedInterests.add('Technology');
      } else if (lower.contains('art') || lower.contains('design') || lower.contains('draw') || lower.contains('paint')) {
        mappedInterests.add('Art & Design');
      } else if (lower.contains('fit') || lower.contains('gym') || lower.contains('sport') || lower.contains('run')) {
        mappedInterests.add('Fitness');
      } else if (lower.contains('nature') || lower.contains('hike') || lower.contains('outside') || lower.contains('outdoor')) {
        mappedInterests.add('Nature');
      } else if (lower.contains('game') || lower.contains('gaming') || lower.contains('play')) {
        mappedInterests.add('Gaming');
      } else if (lower.contains('music') || lower.contains('guitar') || lower.contains('sing') || lower.contains('listen')) {
        mappedInterests.add('Music');
      } else if (lower.contains('cook') || lower.contains('bak') || lower.contains('food')) {
        mappedInterests.add('Cooking');
      } else if (lower.contains('read') || lower.contains('book')) {
        mappedInterests.add('Reading');
      } else if (lower.contains('social') || lower.contains('content') || lower.contains('video') || lower.contains('tiktok')) {
        mappedInterests.add('Social Media');
      }
    }

    if (mappedSkills.isEmpty && skillWords.isNotEmpty) {
      mappedSkills.add(skillWords.first);
    }
    if (mappedInterests.isEmpty && likeWords.isNotEmpty) {
      mappedInterests.add(likeWords.first);
    }

    final traitStr = traits.isNotEmpty ? traits.join(', ') : 'motivated and reliable';
    final skillStr = skillWords.isNotEmpty ? skillWords.join(', ') : 'various tasks';
    final goalStr = goal.isNotEmpty ? goal : 'gain experience and earn money';
    final likeStr = likeWords.isNotEmpty ? likeWords.join(' and ') : 'trying new things';

    final bio = 'Hey there! I\'m a $traitStr teen who loves $likeStr. '
        'I\'m skilled at $skillStr and always looking for new opportunities to learn and grow. '
        'My goal is to $goalStr, and I\'m ready to put in the work to make it happen. '
        'I take every job seriously and pride myself on being dependable — '
        'if you need someone you can count on, I\'m your person!';

    return {
      'bio': bio,
      'skills': mappedSkills.join(','),
      'interests': mappedInterests.join(','),
    };
  }

  Widget _aiField(
      String label, String hint, TextEditingController ctrl, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.slate900,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : AppColors.slate900,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: const Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                : AppColors.slate100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  // ---- Shared helpers ----

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          color: const Color(0xFF94A3B8),
        ),
      );

  Widget _tag(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );

  Widget _detailRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.indigo600),
            const SizedBox(width: 10),
            Text(
              '$label: ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.slate900,
              ),
            ),
          ],
        ),
      );

  Widget _formLabel(String text) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          color: const Color(0xFF94A3B8),
        ),
      );

  Widget _formField(
    TextEditingController ctrl,
    String hint,
    bool isDark, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
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
      );

  Widget _selectableChip(String label, bool selected, Color color,
          bool isDark, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? color
                : isDark
                    ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? color
                  : isDark
                      ? const Color(0xFF334155)
                      : AppColors.slate100,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
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
