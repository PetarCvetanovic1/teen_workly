import 'package:flutter/material.dart';
import '../utils/auth_navigation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';
import '../screens/jobs_screen.dart';
import '../screens/post_job_screen.dart';
import '../screens/post_service_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/huddle_screen.dart';
import '../screens/conversations_screen.dart';

DateTime? _lastNavTapAt;

bool _canNavigateFromTopNav() {
  final now = DateTime.now();
  final last = _lastNavTapAt;
  if (last != null && now.difference(last) < const Duration(milliseconds: 450)) {
    return false;
  }
  _lastNavTapAt = now;
  return true;
}

/// Pill-shaped nav bar.
/// On wide screens it renders inline (for the title Stack).
/// On narrow screens (<600 px) it renders as a compact icon-only strip
/// designed to sit in [AppBar.bottom].
class AppBarNav extends StatelessWidget implements PreferredSizeWidget {
  const AppBarNav({super.key});

  static const double _bottomHeight = 52;

  @override
  Size get preferredSize => const Size.fromHeight(_bottomHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final compact = MediaQuery.of(context).size.width < 750;

    void replaceTopLevel(Widget page, {bool requiresAuth = false}) {
      if (!_canNavigateFromTopNav()) return;
      Navigator.of(context).pushReplacement(
        appRoute(builder: (_) => page, requiresAuth: requiresAuth),
      );
    }

    return Padding(
      padding: compact
          ? const EdgeInsets.only(bottom: 8)
          : EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.slate900.withValues(alpha: 0.8)
              : AppColors.slate100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF334155)
                : AppColors.slate200.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NavChip(
              label: 'Post a Job',
              icon: Icons.add_rounded,
              color: AppColors.indigo600,
              compact: compact,
              onTap: () => replaceTopLevel(
                const PostJobScreen(),
                requiresAuth: true,
              ),
              isDark: isDark,
            ),
            const SizedBox(width: 4),
            _NavChip(
              label: 'The Huddle',
              icon: Icons.groups_rounded,
              color: const Color(0xFFF59E0B),
              compact: compact,
              onTap: () => replaceTopLevel(
                const HuddleScreen(),
                requiresAuth: true,
              ),
              isDark: isDark,
            ),
            const SizedBox(width: 4),
            _NavChip(
              label: 'Post a Service',
              icon: Icons.handyman_rounded,
              color: const Color(0xFF059669),
              compact: compact,
              onTap: () => replaceTopLevel(
                const PostServiceScreen(),
                requiresAuth: true,
              ),
              isDark: isDark,
            ),
            const SizedBox(width: 4),
            _NavChip(
              label: 'Find a Job',
              icon: Icons.search_rounded,
              color: const Color(0xFF7C3AED),
              compact: compact,
              onTap: () => replaceTopLevel(const JobsScreen()),
              isDark: isDark,
            ),
            const SizedBox(width: 4),
            _NavChip(
              label: 'Dashboard',
              icon: Icons.dashboard_rounded,
              color: const Color(0xFFEA580C),
              compact: compact,
              onTap: () => replaceTopLevel(
                const DashboardScreen(),
                requiresAuth: true,
              ),
              isDark: isDark,
            ),
            const SizedBox(width: 4),
            _NavChip(
              label: 'Messages',
              icon: Icons.chat_rounded,
              color: const Color(0xFF0EA5E9),
              compact: compact,
              onTap: () => replaceTopLevel(
                const ConversationsScreen(),
                requiresAuth: true,
              ),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;
  final bool compact;

  const _NavChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: compact ? label : '',
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(13),
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: compact
                ? const EdgeInsets.all(10)
                : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: compact
                ? Icon(icon, size: 18, color: color)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 15, color: color),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
