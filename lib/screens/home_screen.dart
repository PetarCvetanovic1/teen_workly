import 'dart:async';

import 'package:flutter/material.dart';
import '../utils/smooth_route.dart';
import '../utils/auth_navigation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../services/firestore_service.dart';
import 'jobs_screen.dart';
import 'post_job_screen.dart';
import 'post_service_screen.dart';
import 'job_detail_screen.dart';
import 'service_detail_screen.dart';
import 'chat_screen.dart';
import 'huddle_screen.dart';
import 'dashboard_screen.dart';
import 'conversations_screen.dart';
import 'profile_editor_screen.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tw_app_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appState = context.watch<AppState>();
    final isLoggedIn = appState.isLoggedIn;
    final profile = appState.profile;

    return Scaffold(
      appBar: TwAppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
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
            child: Center(
              child: FractionallySizedBox(
                widthFactor: 0.8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                if (isLoggedIn && profile != null) ...[
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _SignedInHomeHeader(state: appState, isDark: isDark),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        appRoute(
                          builder: (_) => const HuddleScreen(),
                          requiresAuth: true,
                        ),
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
                  const SizedBox(height: 24),
                ] else ...[
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
                            appRoute(
                              builder: (_) => const PostJobScreen(),
                              requiresAuth: true,
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
                ],
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
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          SmoothPageRoute(
                            builder: (_) => const JobsScreen(),
                          ),
                        ),
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'See All',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.indigo600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<AppState>(
                  builder: (context, state, _) {
                    final myId = state.currentUserId;
                    final jobs = state.jobs
                        .where((j) =>
                            j.status != JobStatus.completed &&
                            j.posterId != myId &&
                            !state.isBlocked(j.posterId) &&
                            !state.isJobHidden(j.id) &&
                            !j.applicantIds.contains(myId) &&
                            j.hiredId != myId)
                        .toList();
                    final canHire = state.canPostJobs;
                    final services = canHire
                        ? state.services
                            .where((s) =>
                                s.providerId != myId &&
                                !state.isBlocked(s.providerId) &&
                                !state.isServiceHidden(s.id))
                            .toList()
                        : <Service>[];
                    if (jobs.isEmpty && services.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _LatestJobsEmpty(isDark: isDark),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (jobs.isNotEmpty) ...[
                            Text(
                              'LATEST JOBS',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...jobs.take(3).map((j) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _LatestJobCard(
                                      job: j, isDark: isDark),
                                )),
                          ],
                          if (services.isNotEmpty) ...[
                            if (jobs.isNotEmpty) const SizedBox(height: 8),
                            Text(
                              'LATEST SERVICES',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...services.take(2).map((s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _LatestServiceCard(
                                      service: s, isDark: isDark),
                                )),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                if (isLoggedIn && profile != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _HomeActivityPanel(state: appState, isDark: isDark),
                  ),
                ],
                const SizedBox(height: 16),
                if (!isLoggedIn || profile == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        appRoute(
                          builder: (_) => const HuddleScreen(),
                          requiresAuth: true,
                        ),
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
                const SizedBox(height: 48),
              ],
                ),
              ),
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

class _SignedInHomeHeader extends StatelessWidget {
  final AppState state;
  final bool isDark;

  const _SignedInHomeHeader({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final name = state.profile?.name ?? 'there';
    final age = state.profile?.age;
    final showVault = age == null || age <= 20;
    final goal = state.vaultGoal?.trim() ?? '';
    final hasGoal = state.hasVaultGoal && goal.isNotEmpty;
    final remaining = state.vaultRemainingAmount.toStringAsFixed(0);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Welcome back, $name',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your personal TeenWorkly space',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
              ),
            ),
            if (showVault) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.indigo600.withValues(alpha: 0.12),
                      const Color(0xFF7C3AED).withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.indigo600.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasGoal ? 'Vault: $goal' : 'Vault',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasGoal
                          ? 'You are only \$$remaining away. Keep going.'
                          : 'Set your vault goal in Profile to track progress.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: hasGoal ? state.vaultProgress : 0,
                        minHeight: 7,
                        backgroundColor:
                            isDark ? const Color(0xFF334155) : AppColors.slate200,
                        color: AppColors.indigo600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _HeroButton(
                  label: 'My Profile',
                  onTap: () => Navigator.of(context).push(
                    appRoute(
                      builder: (_) => const ProfileScreen(),
                      requiresAuth: true,
                    ),
                  ),
                  filled: true,
                  isDark: isDark,
                ),
                _HeroButton(
                  label: 'Dashboard',
                  onTap: () => Navigator.of(context).push(
                    appRoute(
                      builder: (_) => const DashboardScreen(),
                      requiresAuth: true,
                    ),
                  ),
                  filled: false,
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeActivityPanel extends StatelessWidget {
  final AppState state;
  final bool isDark;

  const _HomeActivityPanel({
    required this.state,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final applied = state.myAppliedJobs
        .where((j) => j.status != JobStatus.completed)
        .toList();
    final posted = state.myPostedJobs
        .where((j) => j.status != JobStatus.completed)
        .toList();
    final myServices = state.myServices;

    return StreamBuilder<List<Conversation>>(
      stream: state.conversationsStream,
      builder: (context, snapshot) {
        final convos = snapshot.data ?? const <Conversation>[];
        return StreamBuilder<List<HuddlePost>>(
          stream: FirestoreService.huddleStream(state.myAgeGroup),
          builder: (context, huddleSnap) {
            final huddlePosts = huddleSnap.data ?? const <HuddlePost>[];
            final huddleSeenAt = state.profile?.huddleRepliesSeenAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final hasHuddleReplyAlert = huddlePosts.any(
              (p) =>
                  p.authorId == state.currentUserId &&
                  (p.replyCount > 0) &&
                  (p.lastReplyAuthorId ?? '').isNotEmpty &&
                  p.lastReplyAuthorId != state.currentUserId &&
                  p.lastReplyAt != null &&
                  p.lastReplyAt!.isAfter(huddleSeenAt),
            );
            final hasAnything = applied.isNotEmpty ||
                posted.isNotEmpty ||
                myServices.isNotEmpty ||
                convos.isNotEmpty ||
                hasHuddleReplyAlert;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(
                    'Your activity',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Applied jobs, posted jobs, messages, and Huddle updates.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!hasAnything) _activityEmpty(context),
                  if (applied.isNotEmpty)
                    _activitySection(
                      context: context,
                      title: 'Jobs you applied to',
                      tint: const Color(0xFFDBEAFE),
                      border: const Color(0xFF93C5FD),
                      isDark: isDark,
                      child: Column(
                        children: applied.take(2).map((job) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _jobStateTile(
                              context: context,
                              icon: Icons.send_rounded,
                              title: job.title,
                              subtitle: job.displayLocation,
                              detailText: 'Your application is active',
                              detailColor: const Color(0xFF2563EB),
                              statusText: _appliedStatusLabel(job),
                              statusColor: _appliedStatusColor(job),
                              onTap: () => Navigator.of(context).push(
                                SmoothPageRoute(
                                  builder: (_) => JobDetailScreen(job: job),
                                ),
                              ),
                              isDark: isDark,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  if (posted.isNotEmpty)
                    _activitySection(
                      context: context,
                      title: 'Jobs you posted',
                      tint: const Color(0xFFFFEDD5),
                      border: const Color(0xFFFDBA74),
                      isDark: isDark,
                      child: Column(
                        children: posted.take(2).map((job) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _jobStateTile(
                              context: context,
                              icon: Icons.inventory_2_rounded,
                              title: job.title,
                              subtitle: job.displayLocation,
                              detailText:
                                  'Applicants: ${job.applicantIds.length}',
                              detailColor: _applicantCountColor(job),
                              statusText: _postedStatusLabel(job),
                              statusColor: _postedStatusColor(job),
                              onTap: () => Navigator.of(context).push(
                                SmoothPageRoute(
                                  builder: (_) => JobDetailScreen(job: job),
                                ),
                              ),
                              isDark: isDark,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  if (myServices.isNotEmpty)
                    _activitySection(
                      context: context,
                      title: 'Your services',
                      tint: const Color(0xFFEDE9FE),
                      border: const Color(0xFFC4B5FD),
                      isDark: isDark,
                      child: Column(
                        children: myServices.take(2).map((service) {
                          final msgCount =
                              _serviceMessageCount(service, convos);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _jobStateTile(
                              context: context,
                              icon: Icons.handyman_rounded,
                              title: service.skills.join(', '),
                              subtitle:
                                  '${service.displayLocation} · ${service.workRadiusKm.toStringAsFixed(0)} km',
                              detailText: 'People messaged: $msgCount',
                              detailColor: const Color(0xFF7C3AED),
                              statusText: '$msgCount msg',
                              statusColor: const Color(0xFF7C3AED),
                              onTap: () => Navigator.of(context).push(
                                SmoothPageRoute(
                                  builder: (_) =>
                                      ServiceDetailScreen(service: service),
                                ),
                              ),
                              isDark: isDark,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  if (hasHuddleReplyAlert)
                    _activityTile(
                      context: context,
                      icon: Icons.mark_chat_unread_rounded,
                      title: 'New Huddle replies',
                      subtitle: 'Someone replied to a Huddle post you started.',
                      onTap: () => Navigator.of(context).push(
                        appRoute(
                          builder: (_) => const HuddleScreen(),
                          requiresAuth: true,
                        ),
                      ),
                      beforeTap: () => unawaited(state.markHuddleRepliesSeen()),
                    ),
                  if (convos.isNotEmpty)
                    _activityTile(
                      context: context,
                      icon: Icons.chat_bubble_rounded,
                      title: 'Message: ${convos.first.otherUserName}',
                      subtitle: convos.first.lastMessagePreview,
                      onTap: () => Navigator.of(context).push(
                        appRoute(
                          builder: (_) => ChatScreen(
                            conversationId: convos.first.id,
                            otherUserName: convos.first.otherUserName,
                            contextLabel: convos.first.contextLabel,
                          ),
                          requiresAuth: true,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _miniAction(
                        context: context,
                        icon: Icons.dashboard_rounded,
                        label: 'Dashboard',
                        onTap: () => Navigator.of(context).push(
                          appRoute(
                            builder: (_) => const DashboardScreen(),
                            requiresAuth: true,
                          ),
                        ),
                      ),
                      _miniAction(
                        context: context,
                        icon: Icons.forum_rounded,
                        label: 'Messages',
                        onTap: () => Navigator.of(context).push(
                          appRoute(
                            builder: (_) => const ConversationsScreen(),
                            requiresAuth: true,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        );
      },
    );
  }

  String _appliedStatusLabel(Job job) {
    if (job.status == JobStatus.open) return 'Applied';
    if (job.status == JobStatus.inProgress) return 'Accepted';
    if (job.status == JobStatus.pendingCompletion) return 'Pending completion';
    return 'Finished';
  }

  String _postedStatusLabel(Job job) {
    if (job.status == JobStatus.open) return 'Posted';
    if (job.status == JobStatus.inProgress) return 'In progress';
    if (job.status == JobStatus.pendingCompletion) return 'Pending confirmation';
    return 'Finished';
  }

  Color _appliedStatusColor(Job job) {
    if (job.status == JobStatus.open) return const Color(0xFF2563EB); // Applied
    if (job.status == JobStatus.inProgress) return const Color(0xFF059669); // Accepted
    if (job.status == JobStatus.pendingCompletion) {
      return const Color(0xFFF59E0B); // Pending completion
    }
    return const Color(0xFF16A34A); // Finished
  }

  Color _postedStatusColor(Job job) {
    if (job.status == JobStatus.open) return const Color(0xFFEA580C); // Posted
    if (job.status == JobStatus.inProgress) return const Color(0xFF7C3AED); // In progress
    if (job.status == JobStatus.pendingCompletion) {
      return const Color(0xFFF59E0B); // Pending confirmation
    }
    return const Color(0xFF16A34A); // Finished
  }

  Color _applicantCountColor(Job job) {
    final count = job.applicantIds.length;
    if (count <= 0) return const Color(0xFF94A3B8);
    if (count <= 2) return const Color(0xFFF59E0B);
    return const Color(0xFF16A34A);
  }

  int _serviceMessageCount(Service service, List<Conversation> convos) {
    final keys = service.skills.map((s) => s.toLowerCase().trim()).toList();
    final senders = <String>{};
    for (final c in convos) {
      final label = (c.contextLabel ?? '').toLowerCase().trim();
      if (!label.startsWith('service:')) continue;
      if (keys.isEmpty) continue;
      final matches = keys.every((k) => label.contains(k));
      if (!matches) continue;
      senders.add(c.otherUserId);
    }
    return senders.length;
  }

  Widget _activityEmpty(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.55)
            : AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.slate200,
        ),
      ),
      child: Text(
        'No active applications or messages yet. Apply to a job or message a service provider and it will show here.',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _activityTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    VoidCallback? beforeTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          beforeTap?.call();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withValues(alpha: 0.55)
                : AppColors.slate50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : AppColors.slate200,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.indigo600, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activitySection({
    required BuildContext context,
    required String title,
    required Color tint,
    required Color border,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : tint.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _jobStateTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String detailText,
    Color? detailColor,
    required String statusText,
    required Color statusColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B)
              : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : AppColors.slate200,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.indigo600, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detailText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: detailColor ??
                          (isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    appRoute(
                      builder: (_) => const PostJobScreen(),
                      requiresAuth: true,
                    ),
                  ),
                  filled: true,
                  isDark: isDark,
                ),
              _HeroButton(
                label: 'Post a Service',
                onTap: () => Navigator.of(context).push(
                  appRoute(
                    builder: (_) => const PostServiceScreen(),
                    requiresAuth: true,
                  ),
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
                      '${job.displayLocation} · ${job.type}',
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
