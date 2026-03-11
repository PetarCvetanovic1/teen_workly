import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../state/app_state.dart';
import '../utils/smooth_route.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tw_app_bar.dart';
import '../widgets/walking_dog_loader.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'terms_view_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loginRedirectQueued = false;

  void _queueLoginRedirectIfNeeded(AppState state) {
    if (_loginRedirectQueued || state.isLoggedIn) return;
    _loginRedirectQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        SmoothPageRoute(builder: (_) => const LoginScreen(lockBackUntilAuth: true)),
        (_) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<AppState>();
    _queueLoginRedirectIfNeeded(state);

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
      body: !state.isLoggedIn
          ? const WalkingDogLoader(label: 'Walking the dog...')
          : Center(
              child: FractionallySizedBox(
                widthFactor: 0.8,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                              : const [Color(0xFFE0E7FF), Color(0xFFF8FAFC)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : AppColors.indigo600.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.indigo600.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: AppColors.indigo600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Settings',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : AppColors.slate900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Make TeenWorkly feel right for you.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionTitle(label: 'Appearance'),
                    const SizedBox(height: 8),
                    _Card(
                      isDark: isDark,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SegmentedButton<ThemeMode>(
                              showSelectedIcon: false,
                              segments: const [
                                ButtonSegment(
                                  value: ThemeMode.light,
                                  icon: Icon(Icons.light_mode_rounded),
                                  label: Text('Light'),
                                ),
                                ButtonSegment(
                                  value: ThemeMode.dark,
                                  icon: Icon(Icons.dark_mode_rounded),
                                  label: Text('Dark'),
                                ),
                                ButtonSegment(
                                  value: ThemeMode.system,
                                  icon: Icon(Icons.phone_android_rounded),
                                  label: Text('System'),
                                ),
                              ],
                              selected: {state.themeMode},
                              onSelectionChanged: (selection) {
                                final picked = selection.first;
                                state.setThemeMode(picked);
                              },
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Choose light, dark, or follow your device setting.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionTitle(label: 'Map Privacy'),
                    const SizedBox(height: 8),
                    _Card(
                      isDark: isDark,
                      child: SwitchListTile(
                        value: state.privacyBubbleEnabled,
                        onChanged: (v) => state.setPrivacyBubbleEnabled(v),
                        secondary: const Icon(
                          Icons.shield_moon_rounded,
                          color: AppColors.indigo600,
                        ),
                        title: Text(
                          'Privacy Bubble on map',
                          style:
                              GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          'Show neighborhood circles instead of precise worker pins.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionTitle(label: 'Legal'),
                    const SizedBox(height: 8),
                    _Card(
                      isDark: isDark,
                      child: ListTile(
                        leading:
                            const Icon(Icons.gavel_rounded, color: AppColors.indigo600),
                        title: Text(
                          'Terms of Service',
                          style:
                              GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          'Open and review the full terms anytime.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          SmoothPageRoute(builder: (_) => const TermsViewScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
        color: const Color(0xFF94A3B8),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _Card({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.slate200,
        ),
      ),
      child: child,
    );
  }
}
