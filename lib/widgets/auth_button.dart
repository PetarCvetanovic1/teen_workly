import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../state/app_state.dart';
import '../screens/login_screen.dart';
import '../screens/profile_editor_screen.dart';

class AuthButton extends StatelessWidget {
  const AuthButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppState>(
      builder: (context, state, _) {
        final profile = state.profile;
        if (state.isLoggedIn) {
          final fallbackName = (() {
            final user = FirebaseAuth.instance.currentUser;
            final display = (user?.displayName ?? '').trim();
            if (display.isNotEmpty) return display;
            final email = (user?.email ?? '').trim();
            if (email.contains('@')) return email.split('@').first;
            if (email.isNotEmpty) return email;
            return 'User';
          })();
          String computeInitials(String raw) {
            final parts = raw
                .split(RegExp(r'[\s._\-]+'))
                .map((p) => p.trim())
                .where((p) => p.isNotEmpty)
                .toList();
            if (parts.length >= 2) {
              return (parts.first[0] + parts.last[0]).toUpperCase();
            }
            final compact = raw.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
            if (compact.length >= 2) {
              return compact.substring(0, 2).toUpperCase();
            }
            if (compact.isNotEmpty) return compact[0].toUpperCase();
            return 'U';
          }

          final initials = profile?.initials ?? computeInitials(fallbackName);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: profile == null
                  ? null
                  : () => Navigator.of(context).push(
                        SmoothPageRoute(builder: (_) => const ProfileScreen()),
                      ),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.indigo600, Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    (initials.isEmpty ? 'U' : initials).toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SmallBtn(
                label: 'Log in',
                filled: false,
                isDark: isDark,
                onTap: () => Navigator.of(context).push(
                  SmoothPageRoute(builder: (_) => const LoginScreen()),
                ),
              ),
              const SizedBox(width: 6),
              _SmallBtn(
                label: 'Join now',
                filled: true,
                isDark: isDark,
                onTap: () => Navigator.of(context).push(
                  SmoothPageRoute(builder: (_) => const SignUpScreen()),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final bool filled;
  final bool isDark;
  final VoidCallback onTap;

  const _SmallBtn({
    required this.label,
    required this.filled,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled
          ? (isDark ? Colors.white : AppColors.slate900)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: filled
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : AppColors.slate200,
                  ),
                ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: filled
                  ? (isDark ? AppColors.slate900 : Colors.white)
                  : (isDark ? Colors.white : AppColors.slate900),
            ),
          ),
        ),
      ),
    );
  }
}
