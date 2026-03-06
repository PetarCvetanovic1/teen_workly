import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../state/app_state.dart';
import '../utils/smooth_route.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tw_app_bar.dart';
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
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Appearance',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 8),
                _Card(
                  isDark: isDark,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
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
                Text(
                  'Map Privacy',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 8),
                _Card(
                  isDark: isDark,
                  child: SwitchListTile(
                    value: state.privacyBubbleEnabled,
                    onChanged: (v) => state.setPrivacyBubbleEnabled(v),
                    secondary: const Icon(Icons.shield_moon_rounded,
                        color: AppColors.indigo600),
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
                Text(
                  'Legal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
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
