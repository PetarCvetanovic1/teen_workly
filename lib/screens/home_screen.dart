import 'package:flutter/material.dart';
import '../utils/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'jobs_screen.dart';
import 'post_job_screen.dart';
import 'post_service_screen.dart';
import 'job_detail_screen.dart';
import 'service_detail_screen.dart';
import 'huddle_screen.dart';
import '../widgets/app_drawer.dart';
import '../widgets/logo_title.dart';
import '../widgets/app_bar_nav.dart';
import '../widgets/auth_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          children: const [
            Align(alignment: Alignment.centerLeft, child: LogoTitle()),
            Center(child: AppBarNav()),
          ],
        ),
        actions: const [AuthButton()],
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? null
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.indigo500.withValues(alpha: 0.08),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.4],
                ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                // Live badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.slate900.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.indigo500,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LIVE IN YOUR CITY',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: isDark
                              ? AppColors.indigo400
                              : const Color(0xFF4338CA),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Hero heading
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Work Hard.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -1,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Gradient text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        AppColors.indigo600,
                        Color(0xFF7C3AED),
                        Color(0xFFEC4899),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'Level Up.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'The safe, fun, and fast way for teens to find local gigs. Gain skills, build your network, and earn cash.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                // CTA buttons - auto-width, centered
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HeroButton(
                        label: 'Find a Gig',
                        onTap: () => Navigator.of(context).push(
                          SmoothPageRoute(
                            builder: (_) => const JobsScreen(),
                          ),
                        ),
                        filled: true,
                        isDark: isDark,
                      ),
                      if (context.watch<AppState>().canPostJobs) ...[
                        const SizedBox(width: 14),
                        _HeroButton(
                          label: 'Hire Talent',
                          onTap: () => Navigator.of(context).push(
                            SmoothPageRoute(
                              builder: (_) => const PostJobScreen(),
                            ),
                          ),
                          filled: false,
                          isDark: isDark,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 72),
                // How it works
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'How it works',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Start earning in three simple steps',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                // Three steps in a row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _StepTile(
                          number: 1,
                          title: 'Create Profile',
                          subtitle: 'Sign up in seconds',
                          icon: Icons.person_add_rounded,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StepTile(
                          number: 2,
                          title: 'Browse Gigs',
                          subtitle: 'Find local opportunities',
                          icon: Icons.search_rounded,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StepTile(
                          number: 3,
                          title: 'Get Paid',
                          subtitle: 'Earn money your way',
                          icon: Icons.account_balance_wallet_rounded,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 64),
                // Latest jobs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Latest jobs',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lawn mowing, dog walking, tutoring, and more.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          SmoothPageRoute(
                            builder: (_) => const JobsScreen(),
                          ),
                        ),
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: AppColors.indigo600,
                        ),
                        label: const Text(
                          'See All',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        SmoothPageRoute(builder: (_) => const HuddleScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.groups_rounded,
                                color: Colors.white, size: 32),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'The Huddle',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Chat, ask for help & collab with other teens',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Consumer<AppState>(
                  builder: (context, state, _) {
                    final jobs = state.jobs;
                    final canHire = state.canPostJobs;
                    final services = canHire ? state.services : <Service>[];
                    if (jobs.isEmpty && services.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _LatestJobsEmpty(isDark: isDark),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          ...services.take(2).map((s) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _LatestServiceCard(
                                    service: s, isDark: isDark),
                              )),
                          ...jobs.take(3).map((j) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _LatestJobCard(
                                    job: j, isDark: isDark),
                              )),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Website-style buttons: auto-width, large padding, rounded-2xl
class _HeroButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final bool isDark;

  const _HeroButton({
    required this.label,
    required this.onTap,
    required this.filled,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return Material(
        color: isDark ? Colors.white : AppColors.slate900,
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.slate900 : Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.slate900.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155)
              : Colors.white.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
        ),
      ),
    );
  }
}

class _LatestJobsEmpty extends StatelessWidget {
  final bool isDark;
  const _LatestJobsEmpty({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.work_outline_rounded,
            size: 40,
            color: AppColors.indigo600.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 16),
          Text(
            'There are no jobs currently.',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.watch<AppState>().canPostJobs
                ? 'Post a service to show off your skills, or post a job if you need help — be the first in your area!'
                : 'Post a service to show off your skills and be the first in your area!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              if (context.watch<AppState>().canPostJobs)
                _HeroButton(
                  label: 'Post a Job',
                  onTap: () => Navigator.of(context).push(
                    SmoothPageRoute(builder: (_) => const PostJobScreen()),
                  ),
                  filled: true,
                  isDark: isDark,
                ),
              _HeroButton(
                label: 'Post a Service',
                onTap: () => Navigator.of(context).push(
                  SmoothPageRoute(
                      builder: (_) => const PostServiceScreen()),
                ),
                filled: false,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Compact vertical tile for the 3-step row
class _StepTile extends StatelessWidget {
  final int number;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDark;

  const _StepTile({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.indigo600.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(icon, color: AppColors.indigo600, size: 22),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LatestJobCard extends StatelessWidget {
  final dynamic job;
  final bool isDark;
  const _LatestJobCard({required this.job, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          SmoothPageRoute(builder: (_) => JobDetailScreen(job: job)),
        ),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.indigo600.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.work_outline_rounded,
                    color: AppColors.indigo600, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${job.location} · ${job.type}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? const Color(0xFF334155) : AppColors.slate200,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LatestServiceCard extends StatelessWidget {
  final dynamic service;
  final bool isDark;
  const _LatestServiceCard({required this.service, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          SmoothPageRoute(
              builder: (_) => ServiceDetailScreen(service: service)),
        ),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), AppColors.indigo600],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    (service.providerName as String)
                        .split(' ')
                        .map((w) => w.isEmpty ? '' : w[0])
                        .take(2)
                        .join()
                        .toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.providerName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (service.skills as Set<String>).join(' · '),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? const Color(0xFF334155) : AppColors.slate200,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
