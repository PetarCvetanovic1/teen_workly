import 'package:flutter/material.dart';
import '../utils/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';
import '../screens/jobs_screen.dart';
import '../screens/post_job_screen.dart';
import '../screens/post_service_screen.dart';
import '../screens/dashboard_screen.dart';

/// Pill-shaped nav with "Post a Job", "Post a Service", "Find a Job", and "Dashboard" for the app bar.
class AppBarNav extends StatelessWidget {
  const AppBarNav({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
            onTap: () => Navigator.of(context).push(
              SmoothPageRoute(builder: (_) => const PostJobScreen()),
            ),
            isDark: isDark,
          ),
          const SizedBox(width: 4),
          _NavChip(
            label: 'Post a Service',
            icon: Icons.handyman_rounded,
            color: const Color(0xFF059669),
            onTap: () => Navigator.of(context).push(
              SmoothPageRoute(builder: (_) => const PostServiceScreen()),
            ),
            isDark: isDark,
          ),
          const SizedBox(width: 4),
          _NavChip(
            label: 'Find a Job',
            icon: Icons.search_rounded,
            color: const Color(0xFF7C3AED),
            onTap: () => Navigator.of(context).push(
              SmoothPageRoute(builder: (_) => const JobsScreen()),
            ),
            isDark: isDark,
          ),
          const SizedBox(width: 4),
          _NavChip(
            label: 'Dashboard',
            icon: Icons.dashboard_rounded,
            color: const Color(0xFFEA580C),
            onTap: () => Navigator.of(context).push(
              SmoothPageRoute(builder: (_) => const DashboardScreen()),
            ),
            isDark: isDark,
          ),
        ],
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

  const _NavChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(13),
      elevation: 0.5,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
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
    );
  }
}
