import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../state/app_state.dart';
import '../utils/smooth_route.dart';
import '../widgets/app_drawer.dart';
import '../widgets/content_wrap.dart';
import '../widgets/tw_app_bar.dart';
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
  final _schoolCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _vaultGoalCtrl = TextEditingController();
  final _vaultTargetCtrl = TextEditingController();
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
    _schoolCtrl.dispose();
    _locationCtrl.dispose();
    _bioCtrl.dispose();
    _ageCtrl.dispose();
    _vaultGoalCtrl.dispose();
    _vaultTargetCtrl.dispose();
    _customSkillCtrl.dispose();
    _customInterestCtrl.dispose();
    super.dispose();
  }

  void _hydrate(AppState state) {
    if (_hydrated || state.profile == null) return;
    final p = state.profile!;
    _nameCtrl.text = p.name;
    _schoolCtrl.text = p.school ?? '';
    _locationCtrl.text = p.location ?? '';
    _bioCtrl.text = p.bio ?? '';
    _ageCtrl.text = p.age?.toString() ?? '';
    _vaultGoalCtrl.text = p.vaultGoal ?? '';
    _vaultTargetCtrl.text =
        p.vaultTargetAmount != null ? p.vaultTargetAmount!.toStringAsFixed(0) : '';
    _skills = Set<String>.from(p.skills);
    _interests = Set<String>.from(p.interests);
    if (!_modeInitialized) {
      final hasSavedDetails = (p.school?.trim().isNotEmpty ?? false) ||
          (p.location?.trim().isNotEmpty ?? false) ||
          (p.bio?.trim().isNotEmpty ?? false) ||
          (p.age != null) ||
          (p.vaultGoal?.trim().isNotEmpty ?? false) ||
          ((p.vaultTargetAmount ?? 0) > 0) ||
          p.skills.isNotEmpty ||
          p.interests.isNotEmpty;
      _editing = !hasSavedDetails;
      _modeInitialized = true;
    }
    _hydrated = true;
  }

  Future<void> _save(AppState state) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    await state.updateProfile(
      name: _nameCtrl.text.trim(),
      school: _schoolCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text.trim()),
      vaultGoal: _vaultGoalCtrl.text.trim(),
      vaultTargetAmount:
          _vaultTargetCtrl.text.trim().isEmpty ? 0 : double.tryParse(_vaultTargetCtrl.text.trim()),
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<AppState>(
      builder: (context, state, _) {
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
                  const CircularProgressIndicator(),
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
                            'Edit Profile',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Update your full name, school, skills, likes, vault goal, and more.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _field(_nameCtrl, 'Full Name', validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            if (v.trim().split(RegExp(r'\s+')).length < 2) return 'Enter first + last name';
                            return null;
                          }),
                          _field(_schoolCtrl, 'School'),
                          _field(_locationCtrl, 'Location'),
                          _field(_ageCtrl, 'Age', keyboardType: TextInputType.number),
                          _field(_bioCtrl, 'Bio / About you', maxLines: 3),
                          _field(_vaultGoalCtrl, 'Vault Goal (what are you saving for?)'),
                          _field(_vaultTargetCtrl, 'Vault Target Amount (\$)',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                          const SizedBox(height: 12),
                          _chipSection(
                            title: 'Skills',
                            options: _presetSkills,
                            selected: _skills,
                            customController: _customSkillCtrl,
                          ),
                          const SizedBox(height: 14),
                          _chipSection(
                            title: 'What you like doing',
                            options: _presetInterests,
                            selected: _interests,
                            customController: _customInterestCtrl,
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
                                  : const Text('Save Profile'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _saving ? null : () => setState(() => _editing = false),
                              child: const Text('Cancel'),
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
                          'Your Profile',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.slate900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Clean summary of your saved profile.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _profileCard(
                          'Full Name',
                          _nameCtrl.text.trim(),
                          isDark,
                        ),
                        _profileCard('School', _schoolCtrl.text.trim(), isDark),
                        _profileCard('Location', _locationCtrl.text.trim(), isDark),
                        _profileCard('Age', _ageCtrl.text.trim(), isDark),
                        _profileCard('About', _bioCtrl.text.trim(), isDark),
                        _profileCard('Vault Goal', _vaultGoalCtrl.text.trim(), isDark),
                        _profileCard(
                          'Vault Target',
                          _vaultTargetCtrl.text.trim().isEmpty
                              ? ''
                              : '\$${_vaultTargetCtrl.text.trim()}',
                          isDark,
                        ),
                        _chipsPreview('Skills', _skills, isDark),
                        const SizedBox(height: 10),
                        _chipsPreview('What you like doing', _interests, isDark),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => setState(() => _editing = true),
                            child: const Text('Edit Profile'),
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

  Widget _profileCard(String label, String value, bool isDark) {
    final display = value.trim().isEmpty ? 'Not set' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      ),
    );
  }

  Widget _chipsPreview(String title, Set<String> values, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (values.isEmpty)
          Text(
            'None added yet',
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
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(labelText: label),
      ),
    );
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
                decoration: const InputDecoration(hintText: 'Add custom item'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                final text = customController.text.trim();
                if (text.isEmpty) return;
                setState(() => selected.add(text));
                customController.clear();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ],
    );
  }
}
