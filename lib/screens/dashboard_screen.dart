import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../utils/auth_navigation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tw_app_bar.dart';
import '../widgets/content_wrap.dart';
import 'home_screen.dart';
import 'job_detail_screen.dart';
import 'chat_screen.dart';
import 'login_screen.dart';
import 'post_service_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _hideCompletedItems = true;
  bool _loginRedirectQueued = false;

  void _queueLoginRedirectIfNeeded(AppState state) {
    if (_loginRedirectQueued || state.isLoggedIn) return;
    _loginRedirectQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        appRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: TwAppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        onLogoTap: () => Navigator.of(context).pushAndRemoveUntil(
          appRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        ),
      ),
      drawer: const AppDrawer(),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          _queueLoginRedirectIfNeeded(state);
          if (!state.isLoggedIn) {
            return const Center(child: CircularProgressIndicator());
          }
          final posted = _hideCompletedItems
              ? state.myPostedJobs.where((j) => j.status != JobStatus.completed).toList()
              : state.myPostedJobs;
          final applied = state.myAppliedJobs;
          final visibleApplied = _hideCompletedItems
              ? applied.where((j) => j.status != JobStatus.completed).toList()
              : applied;
          final current = state.myCurrentJobs;
          final myServices = state.myServices;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ContentWrap(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                Text(
                  'Dashboard',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your activity at a glance',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _hideCompletedItems = !_hideCompletedItems;
                    }),
                    icon: Icon(
                      _hideCompletedItems
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 16,
                      color: AppColors.indigo600,
                    ),
                    label: Text(
                      _hideCompletedItems ? 'Show Completed Items' : 'Hide Completed Items',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.indigo600,
                      ),
                    ),
                  ),
                ),
                if (state.hasVaultGoal) ...[
                  const SizedBox(height: 16),
                  _VaultGoalCard(
                    isDark: isDark,
                    goal: state.vaultGoal ?? '',
                    saved: state.vaultSavedAmount,
                    target: state.vaultTargetAmount ?? 0,
                    progress: state.vaultProgress,
                    nudge: state.vaultNudgeMessage,
                  ),
                ],
                const SizedBox(height: 16),
                Builder(builder: (context) {
                  final tier = state.myWorkerTier;
                  late final String title;
                  late final String subtitle;
                  late final Color accent;
                  late final IconData icon;
                  switch (tier) {
                    case WorkerTier.topRated:
                      title = 'Top Rated';
                      subtitle =
                          '${state.myCompletedJobs.length} jobs completed · ${state.myRating.toStringAsFixed(1)} avg rating';
                      accent = const Color(0xFFF59E0B);
                      icon = Icons.workspace_premium_rounded;
                      break;
                    case WorkerTier.reliable:
                      title = 'Reliable';
                      subtitle =
                          '${state.myCompletedJobs.length} jobs completed · ${state.myRating.toStringAsFixed(1)} avg rating';
                      accent = const Color(0xFF059669);
                      icon = Icons.verified_rounded;
                      break;
                    case WorkerTier.newWorker:
                      title = 'New';
                      subtitle =
                          'Complete 5+ jobs with a 3.5+ rating to become Reliable.';
                      accent = const Color(0xFF94A3B8);
                      icon = Icons.new_releases_rounded;
                      break;
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.14),
                          (isDark ? const Color(0xFF1E293B) : Colors.white),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accent.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                ),
                              ),
                              Text(
                                subtitle,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'Performance',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        appRoute(
                          builder: (_) => const DashboardProgressScreen(),
                          requiresAuth: true,
                        ),
                      ),
                      icon: const Icon(Icons.insights_rounded, size: 16),
                      label: Text(
                        'See more',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Stats grid
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.attach_money_rounded,
                        label: 'Earned',
                        value: '\$${state.moneyEarned.toStringAsFixed(0)}',
                        color: const Color(0xFF059669),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.people_rounded,
                        label: 'Hired',
                        value: '${state.peopleHired}',
                        color: AppColors.indigo600,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle_rounded,
                        label: 'Completed',
                        value: '${state.myCompletedJobs.length}',
                        color: const Color(0xFF7C3AED),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.star_rounded,
                        label: 'Rating',
                        value: state.myReviewCount == 0
                            ? 'N/A'
                            : '${state.myRating.toStringAsFixed(1)} / 5',
                        color: const Color(0xFFEAB308),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (state.canPostJobs) ...[
                      Expanded(
                        child: _LimitIndicator(
                          label: 'Jobs Posted',
                          current: state.myActivePostedJobs,
                          max: state.maxPostableJobs,
                          color: AppColors.indigo600,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: _LimitIndicator(
                        label: 'Active Work',
                        current: state.myActiveHiredJobs,
                        max: 3,
                        color: const Color(0xFF059669),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                if (state.amReportSuspended) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.gavel_rounded,
                            color: Color(0xFFDC2626), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account Suspended — Community Reports',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Builder(builder: (context) {
                                final left = state.reportSuspensionTimeLeft(
                                    state.currentUserId);
                                final days = (left.inHours / 24).ceil();
                                final count = state.uniqueReportCountForUser(
                                    state.currentUserId);
                                return Text(
                                  'You\'ve been reported by $count '
                                  'user${count == 1 ? '' : 's'}. '
                                  'Suspension ends in ${days > 0 ? "$days day${days == 1 ? "" : "s"}" : "a few hours"}. '
                                  'Reports reset monthly.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (state.canPostJobs && state.isPostingSuspended) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.block_rounded,
                            color: Color(0xFFDC2626), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Posting Suspended',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Builder(builder: (context) {
                                final hours =
                                    state.suspensionTimeLeft.inHours;
                                final days = (hours / 24).ceil();
                                return Text(
                                  'You deleted too many jobs with applicants. '
                                  'Posting resumes in ${days > 0 ? "$days day${days == 1 ? "" : "s"}" : "a few hours"}.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (state.canPostJobs && state.deleteStrikeCount > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFEA580C), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${state.deleteStrikeCount}/3 deletion strikes this week. '
                            '${state.strikesRemaining} left before posting suspension.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEA580C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                // Current jobs
                if (current.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'In Progress',
                    count: current.length,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  ...current.map((j) => _JobCard(
                        job: j,
                        badge: j.status == JobStatus.pendingCompletion
                            ? 'AWAITING CONFIRMATION'
                            : 'IN PROGRESS',
                        badgeColor: j.status == JobStatus.pendingCompletion
                            ? const Color(0xFFEA580C)
                            : const Color(0xFF059669),
                        isDark: isDark,
                      )),
                  const SizedBox(height: 24),
                ],
                // Pending confirmation (for posters)
                if (state.myPendingConfirmJobs.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Needs Your Confirmation',
                    count: state.myPendingConfirmJobs.length,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  ...state.myPendingConfirmJobs.map((j) => _JobCard(
                        job: j,
                        badge: 'WORKER FINISHED',
                        badgeColor: const Color(0xFFEA580C),
                        isDark: isDark,
                      )),
                  const SizedBox(height: 24),
                ],
                if (state.canPostJobs) ...[
                  // Posted jobs
                  _SectionHeader(
                    title: 'Your Posted Jobs',
                    count: posted.length,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  if (posted.isEmpty)
                    _EmptyCard(
                      message: 'You haven\'t posted any jobs yet.',
                      isDark: isDark,
                    )
                  else
                    ...posted.map((j) => _JobCard(
                          job: j,
                          badge: j.status == JobStatus.open
                              ? 'OPEN · ${j.applicantIds.length} applicants'
                              : j.status == JobStatus.inProgress
                                  ? 'IN PROGRESS'
                                  : j.status == JobStatus.pendingCompletion
                                      ? 'NEEDS CONFIRMATION'
                                      : 'COMPLETED',
                          badgeColor: j.status == JobStatus.open
                              ? AppColors.indigo600
                              : j.status == JobStatus.inProgress
                                  ? const Color(0xFF059669)
                                  : j.status == JobStatus.pendingCompletion
                                      ? const Color(0xFFEA580C)
                                      : const Color(0xFF7C3AED),
                          isDark: isDark,
                          actionLabel: j.status == JobStatus.open ? 'Delete' : null,
                          actionColor: const Color(0xFFDC2626),
                          actionIcon: Icons.delete_outline_rounded,
                          onAction: j.status == JobStatus.open
                              ? () => _confirmJobDelete(
                                    context,
                                    state: state,
                                    job: j,
                                    isDark: isDark,
                                  )
                              : null,
                        )),
                  const SizedBox(height: 24),
                ],
                // Applied jobs
                Row(
                  children: [
                    _SectionHeader(
                      title: 'Jobs You Applied To',
                      count: visibleApplied.length,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (visibleApplied.isEmpty)
                  _EmptyCard(
                    message: 'You haven\'t applied to any jobs yet.',
                    isDark: isDark,
                  )
                else
                  ...visibleApplied.map((j) {
                    String badge;
                    Color badgeColor;
                    final canCancel = j.hiredId != state.currentUserId &&
                        j.status == JobStatus.open;
                    if (j.status == JobStatus.completed &&
                        j.hiredId == state.currentUserId) {
                      badge = 'FINISHED';
                      badgeColor = const Color(0xFF7C3AED);
                    } else if (j.status == JobStatus.completed) {
                      badge = 'COMPLETED';
                      badgeColor = const Color(0xFF94A3B8);
                    } else if (j.hiredId == state.currentUserId) {
                      badge = 'HIRED!';
                      badgeColor = const Color(0xFF059669);
                    } else if (j.hiredId != null) {
                      badge = 'SOMEONE ELSE HIRED';
                      badgeColor = const Color(0xFF94A3B8);
                    } else {
                      badge = 'PENDING';
                      badgeColor = const Color(0xFFEA580C);
                    }
                    return _JobCard(
                      job: j,
                      badge: badge,
                      badgeColor: badgeColor,
                      isDark: isDark,
                      actionLabel: canCancel ? 'Withdraw' : null,
                      actionColor: const Color(0xFFDC2626),
                      actionIcon: Icons.close_rounded,
                      onAction: canCancel
                          ? () => _confirmDelete(
                                context,
                                isDark: isDark,
                                title: 'Withdraw Application',
                                message: 'Cancel your application for "${j.title}"?',
                                onConfirm: () async => await state.withdrawApplication(j.id),
                              )
                          : null,
                    );
                  }),
                const SizedBox(height: 24),
                // Your services
                _SectionHeader(
                  title: 'Your Services',
                  count: myServices.length,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                if (myServices.isEmpty)
                  _EmptyCard(
                    message: 'You haven\'t posted any services yet.',
                    isDark: isDark,
                  )
                else
                  StreamBuilder<List<Conversation>>(
                    stream: state.conversationsStream,
                    builder: (context, convoSnap) {
                      final convos = convoSnap.data ?? const <Conversation>[];
                      return Column(
                        children: myServices.map((s) {
                          final msgCount = _serviceMessageCount(s, convos);
                          return _ServiceCard(
                            service: s,
                            isDark: isDark,
                            messageCount: msgCount,
                            onEdit: () => Navigator.of(context).push(
                              appRoute(
                                builder: (_) =>
                                    PostServiceScreen(initialService: s),
                                requiresAuth: true,
                              ),
                            ),
                            onDelete: () => _confirmDelete(
                              context,
                              isDark: isDark,
                              title: 'Delete Service',
                              message:
                                  'Remove your "${s.skills.join(", ")}" service listing?',
                              onConfirm: () async => await state.deleteService(s.id),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                // Conversations
                StreamBuilder<List<Conversation>>(
                  stream: state.conversationsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            title: 'Your Conversations',
                            count: 0,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _EmptyCard(
                            message:
                                'Could not load conversations: ${snapshot.error}',
                            isDark: isDark,
                          ),
                        ],
                      );
                    }
                    final convos = snapshot.data ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: 'Your Conversations',
                          count: convos.length,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        if (convos.isEmpty)
                          _EmptyCard(
                            message:
                                'No conversations yet. Message someone from a service or job listing!',
                            isDark: isDark,
                          )
                        else
                          ...convos.map(
                            (conv) => _ConvoCard(
                              name: conv.otherUserName,
                              contextLabel: conv.contextLabel,
                              preview: conv.lastMessagePreview,
                              time: conv.lastMessageTime,
                              isDark: isDark,
                              onDelete: () => _confirmDeleteConversation(
                                context,
                                state: state,
                                conversationId: conv.id,
                                isDark: isDark,
                              ),
                              onTap: () => Navigator.of(context).push(
                                appRoute(
                                  builder: (_) => ChatScreen(
                                    conversationId: conv.id,
                                    otherUserName: conv.otherUserName,
                                    contextLabel: conv.contextLabel,
                                  ),
                                  requiresAuth: true,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 48),
              ],
            ),
            ),
          );
        },
      ),
    );
  }
}

void _confirmDelete(
  BuildContext context, {
  required bool isDark,
  required String title,
  required String message,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : AppColors.slate900,
        ),
      ),
      content: Text(
        message,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF94A3B8),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Keep it',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(ctx);
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            title.contains('Withdraw') ? 'Withdraw' : 'Delete',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

void _confirmJobDelete(
  BuildContext context, {
  required AppState state,
  required Job job,
  required bool isDark,
}) {
  final hasApplicants = state.jobHasApplicants(job.id);
  final strikes = state.deleteStrikeCount;
  final remaining = state.strikesRemaining;

  String message;
  if (hasApplicants) {
    if (remaining <= 1) {
      message =
          'This job has applicants who are counting on it!\n\n'
          '⚠️ WARNING: This is your last chance. Deleting this job '
          'will suspend you from posting jobs for 3 days.';
    } else {
      message =
          'This job already has people who applied. Deleting jobs '
          'with applicants counts as a strike.\n\n'
          'You have $remaining strike${remaining == 1 ? '' : 's'} left '
          'this week before you get suspended from posting for 3 days.';
    }
  } else {
    message = 'Are you sure you want to delete "${job.title}"? '
        'This can\'t be undone.';
  }

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      title: Row(
        children: [
          if (hasApplicants)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFEA580C), size: 24),
            ),
          Text(
            hasApplicants ? 'Delete Job (Strike ${strikes + 1}/3)' : 'Delete Job',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.5,
          color: const Color(0xFF94A3B8),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Keep it',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final result = await state.deleteJobWithStrike(job.id);
            if (!context.mounted) return;

            if (result == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Job deleted.'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            } else if (result == 'suspended') {
              _showSuspensionDialog(context, isDark: isDark);
            } else if (result.startsWith('strike:')) {
              final left = int.tryParse(result.split(':')[1]) ?? 0;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    left == 1
                        ? '⚠️ Strike recorded! 1 more and you\'ll be suspended from posting for 3 days.'
                        : '⚠️ Strike recorded! $left strikes left before suspension.',
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFFEA580C),
                  duration: const Duration(seconds: 5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Delete anyway',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

void _showSuspensionDialog(BuildContext context, {required bool isDark}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      title: Row(
        children: [
          const Icon(Icons.block_rounded, color: Color(0xFFDC2626), size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Posting Suspended',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
      content: Text(
        'You\'ve deleted 3 jobs that had applicants this week. '
        'Other teens were counting on those opportunities.\n\n'
        'You are now suspended from posting new jobs for 3 days. '
        'Your strikes reset every week.',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.5,
          color: const Color(0xFF94A3B8),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'I understand',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

class _VaultGoalCard extends StatelessWidget {
  final bool isDark;
  final String goal;
  final double saved;
  final double target;
  final double progress;
  final String nudge;

  const _VaultGoalCard({
    required this.isDark,
    required this.goal,
    required this.saved,
    required this.target,
    required this.progress,
    required this.nudge,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (target - saved) <= 0 ? 0 : (target - saved);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.indigo600.withValues(alpha: 0.12),
            const Color(0xFF7C3AED).withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.indigo600.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vault Goal',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.indigo600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            goal,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Saved \$${saved.toStringAsFixed(0)} / \$${target.toStringAsFixed(0)} · \$${remaining.toStringAsFixed(0)} left',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor:
                  isDark ? const Color(0xFF334155) : AppColors.slate200,
              color: AppColors.indigo600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : AppColors.slate200,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notifications_active_rounded,
                    size: 16, color: AppColors.indigo600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nudge,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.slate900,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.indigo600.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.indigo600,
            ),
          ),
        ),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  final Job job;
  final String badge;
  final Color badgeColor;
  final bool isDark;
  final String? actionLabel;
  final Color? actionColor;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const _JobCard({
    required this.job,
    required this.badge,
    required this.badgeColor,
    required this.isDark,
    this.actionLabel,
    this.actionColor,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            appRoute(
              builder: (_) => JobDetailScreen(job: job),
              requiresAuth: true,
            ),
          ),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        job.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: const Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 230),
                          child: Text(
                            job.displayLocation,
                            softWrap: true,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.work_outline_rounded,
                            size: 14, color: const Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          job.type,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    if (onAction != null)
                      GestureDetector(
                        onTap: onAction,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: (actionColor ?? const Color(0xFFDC2626))
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                actionIcon ?? Icons.close_rounded,
                                size: 13,
                                color:
                                    actionColor ?? const Color(0xFFDC2626),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                actionLabel ?? 'Remove',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: actionColor ??
                                      const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;
  final bool isDark;
  final int messageCount;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ServiceCard({
    required this.service,
    required this.isDark,
    this.messageCount = 0,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.handyman_rounded,
                  color: Color(0xFF7C3AED), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.skills.join(', '),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${service.displayLocation} · ${service.workRadiusKm.toStringAsFixed(0)} km',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_rounded,
                      size: 13, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 4),
                  Text(
                    '$messageCount',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (onEdit != null)
              Tooltip(
                message: 'Edit your service',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onEdit,
                    mouseCursor: SystemMouseCursors.click,
                    borderRadius: BorderRadius.circular(8),
                    hoverColor: AppColors.indigo600.withValues(alpha: 0.14),
                    highlightColor: AppColors.indigo600.withValues(alpha: 0.18),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.indigo600.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_outlined,
                              size: 13, color: AppColors.indigo600),
                          const SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.indigo600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (onEdit != null && onDelete != null) const SizedBox(width: 6),
            if (onDelete != null)
              Tooltip(
                message: 'Delete this service',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onDelete,
                    mouseCursor: SystemMouseCursors.click,
                    borderRadius: BorderRadius.circular(8),
                    hoverColor: const Color(0xFFDC2626).withValues(alpha: 0.14),
                    highlightColor:
                        const Color(0xFFDC2626).withValues(alpha: 0.18),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.delete_outline_rounded,
                              size: 13, color: Color(0xFFDC2626)),
                          const SizedBox(width: 4),
                          Text(
                            'Delete',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
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

enum _TrendPeriod { week, month, year, allTime }

enum _TrendMetric { finished, finishedPosted, moneyMade }

class _TrendSeries {
  final _TrendMetric metric;
  final List<double> values;
  final Color color;
  final String label;

  const _TrendSeries({
    required this.metric,
    required this.values,
    required this.color,
    required this.label,
  });
}

class DashboardProgressScreen extends StatefulWidget {
  const DashboardProgressScreen({super.key});

  @override
  State<DashboardProgressScreen> createState() => _DashboardProgressScreenState();
}

class _DashboardProgressScreenState extends State<DashboardProgressScreen> {
  _TrendPeriod _period = _TrendPeriod.week;
  bool _showLastWeek = false;
  final Set<_TrendMetric> _selected = {
    _TrendMetric.finished,
    _TrendMetric.finishedPosted,
  };

  static const _monthShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  DateTime _startOfWeek(DateTime dt) {
    final d = DateTime(dt.year, dt.month, dt.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  String _formatMetricValue(_TrendMetric metric, double value) {
    if (metric == _TrendMetric.moneyMade) {
      return '\$${value.toStringAsFixed(0)}';
    }
    return value.toStringAsFixed(0);
  }

  DateTime _bucketStart(DateTime dt, _TrendPeriod period) {
    switch (period) {
      case _TrendPeriod.week:
      case _TrendPeriod.month:
        return DateTime(dt.year, dt.month, dt.day);
      case _TrendPeriod.year:
        return DateTime(dt.year, dt.month);
      case _TrendPeriod.allTime:
        return DateTime(dt.year);
    }
  }

  List<DateTime> _buildBuckets(DateTime now, DateTime? earliest) {
    switch (_period) {
      case _TrendPeriod.week:
        final currentWeekStart = _startOfWeek(now);
        final selectedWeekStart = _showLastWeek
            ? currentWeekStart.subtract(const Duration(days: 7))
            : currentWeekStart;
        return List.generate(
          7,
          (i) => selectedWeekStart.add(Duration(days: i)),
        );
      case _TrendPeriod.month:
        final today = DateTime(now.year, now.month, now.day);
        return List.generate(
          30,
          (i) => today.subtract(Duration(days: 29 - i)),
        );
      case _TrendPeriod.year:
        return List.generate(
          now.month,
          (i) => DateTime(now.year, i + 1),
        );
      case _TrendPeriod.allTime:
        final first = earliest ?? DateTime(now.year);
        final startYear = first.year;
        final endYear = now.year;
        return List.generate(
          (endYear - startYear) + 1,
          (i) => DateTime(startYear + i),
        );
    }
  }

  String _labelForBucket(DateTime dt) {
    switch (_period) {
      case _TrendPeriod.week:
        const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final idx = (dt.weekday - 1).clamp(0, 6);
        return weekDays[idx];
      case _TrendPeriod.month:
        return '${dt.month}/${dt.day}';
      case _TrendPeriod.year:
        return _monthShort[dt.month - 1];
      case _TrendPeriod.allTime:
        return '${dt.year}';
    }
  }

  String _periodTitle() {
    switch (_period) {
      case _TrendPeriod.week:
        return _showLastWeek ? 'last week' : 'this week';
      case _TrendPeriod.month:
        return 'last 30 days';
      case _TrendPeriod.year:
        return 'this year';
      case _TrendPeriod.allTime:
        return 'all time';
    }
  }

  void _toggleMetric(_TrendMetric metric) {
    setState(() {
      // Keep at least one metric selected.
      if (_selected.contains(metric) && _selected.length == 1) return;

      if (metric == _TrendMetric.moneyMade) {
        // Money made must be shown alone.
        if (_selected.contains(metric)) {
          _selected.remove(metric);
          _selected.add(_TrendMetric.finished);
        } else {
          _selected
            ..clear()
            ..add(_TrendMetric.moneyMade);
        }
        return;
      }

      // Jobs-based metrics cannot be combined with money-made metric.
      _selected.remove(_TrendMetric.moneyMade);
      if (_selected.contains(metric)) {
        _selected.remove(metric);
      } else {
        _selected.add(metric);
      }
      if (_selected.isEmpty) {
        _selected.add(metric);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<AppState>();
    final currentUserId = state.currentUserId;
    final completedJobs = state.jobs.where((j) {
      return j.status == JobStatus.completed &&
          (j.posterId == currentUserId || j.hiredId == currentUserId);
    }).toList();

    DateTime? earliest;
    if (completedJobs.isNotEmpty) {
      completedJobs.sort((a, b) {
        final da = a.completedAt ?? a.createdAt;
        final db = b.completedAt ?? b.createdAt;
        return da.compareTo(db);
      });
      earliest = completedJobs.first.completedAt ?? completedJobs.first.createdAt;
    }
    final buckets = _buildBuckets(DateTime.now(), earliest);
    final periodLabel = _periodTitle();
    final bucketKeys = buckets.toSet();

    final finished = <DateTime, double>{for (final b in buckets) b: 0};
    final finishedPosted = <DateTime, double>{for (final b in buckets) b: 0};
    final moneyMade = <DateTime, double>{for (final b in buckets) b: 0};

    for (final j in completedJobs) {
      final when = j.completedAt ?? j.createdAt;
      final bucket = _bucketStart(when, _period);
      if (!bucketKeys.contains(bucket)) continue;
      if (j.hiredId == currentUserId) {
        finished[bucket] = (finished[bucket] ?? 0) + 1;
        moneyMade[bucket] = (moneyMade[bucket] ?? 0) + j.payment;
      }
      if (j.posterId == currentUserId) {
        finishedPosted[bucket] = (finishedPosted[bucket] ?? 0) + 1;
      }
    }

    final series = <_TrendSeries>[
      if (_selected.contains(_TrendMetric.finished))
        _TrendSeries(
          metric: _TrendMetric.finished,
          values: buckets.map((b) => finished[b] ?? 0).toList(),
          color: AppColors.indigo600,
          label: 'Jobs finished',
        ),
      if (_selected.contains(_TrendMetric.finishedPosted))
        _TrendSeries(
          metric: _TrendMetric.finishedPosted,
          values: buckets.map((b) => finishedPosted[b] ?? 0).toList(),
          color: const Color(0xFF7C3AED),
          label: 'Jobs finished (posted)',
        ),
      if (_selected.contains(_TrendMetric.moneyMade))
        _TrendSeries(
          metric: _TrendMetric.moneyMade,
          values: buckets.map((b) => moneyMade[b] ?? 0).toList(),
          color: const Color(0xFF059669),
          label: 'Money made',
        ),
    ];

    double latestValue(_TrendMetric metric) {
      if (buckets.isEmpty) return 0;
      final last = buckets.last;
      switch (metric) {
        case _TrendMetric.finished:
          return finished[last] ?? 0;
        case _TrendMetric.finishedPosted:
          return finishedPosted[last] ?? 0;
        case _TrendMetric.moneyMade:
          return moneyMade[last] ?? 0;
      }
    }

    final totalFinished = finished.values.fold<double>(0, (sum, v) => sum + v);
    final totalPostedFinished =
        finishedPosted.values.fold<double>(0, (sum, v) => sum + v);
    final totalMoney = moneyMade.values.fold<double>(0, (sum, v) => sum + v);
    final vibe = totalFinished >= 5
        ? 'You are building strong momentum. Keep going!'
        : totalFinished >= 1
            ? 'Nice progress - every completed job adds trust.'
            : 'Your first completion will kick off your trend. You got this.';

    return Scaffold(
      appBar: AppBar(title: const Text('Progress Insights')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your growth story',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vibe,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FriendlyKpiCard(
                  label: 'Finished',
                  value: totalFinished.toStringAsFixed(0),
                  icon: Icons.check_circle_rounded,
                  color: AppColors.indigo600,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FriendlyKpiCard(
                  label: 'Posted done',
                  value: totalPostedFinished.toStringAsFixed(0),
                  icon: Icons.task_alt_rounded,
                  color: const Color(0xFF7C3AED),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FriendlyKpiCard(
                  label: 'Made',
                  value: '\$${totalMoney.toStringAsFixed(0)}',
                  icon: Icons.savings_rounded,
                  color: const Color(0xFF059669),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Trend Lines ($periodLabel)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pick what you want to track and watch how it changes over time.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : AppColors.slate200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<_TrendPeriod>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: _TrendPeriod.week, label: Text('Week')),
                    ButtonSegment(value: _TrendPeriod.month, label: Text('Month')),
                    ButtonSegment(value: _TrendPeriod.year, label: Text('Year')),
                    ButtonSegment(value: _TrendPeriod.allTime, label: Text('All time')),
                  ],
                  selected: {_period},
                  onSelectionChanged: (selection) {
                    setState(() => _period = selection.first);
                  },
                ),
                if (_period == _TrendPeriod.week) ...[
                  const SizedBox(height: 10),
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: false, label: Text('This week')),
                      ButtonSegment(value: true, label: Text('Last week')),
                    ],
                    selected: {_showLastWeek},
                    onSelectionChanged: (selection) {
                      setState(() => _showLastWeek = selection.first);
                    },
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricToggleChip(
                      label: 'Jobs finished',
                      color: AppColors.indigo600,
                      selected: _selected.contains(_TrendMetric.finished),
                      onTap: () => _toggleMetric(_TrendMetric.finished),
                    ),
                    _MetricToggleChip(
                      label: 'Jobs finished (posted)',
                      color: const Color(0xFF7C3AED),
                      selected: _selected.contains(_TrendMetric.finishedPosted),
                      onTap: () => _toggleMetric(_TrendMetric.finishedPosted),
                    ),
                    _MetricToggleChip(
                      label: 'Money made',
                      color: const Color(0xFF059669),
                      selected: _selected.contains(_TrendMetric.moneyMade),
                      onTap: () => _toggleMetric(_TrendMetric.moneyMade),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _LineTrendChart(
            series: series,
            labels: buckets.map(_labelForBucket).toList(),
            isDark: isDark,
            moneyScale:
                _selected.length == 1 && _selected.contains(_TrendMetric.moneyMade),
          ),
          const SizedBox(height: 14),
          ...series.map((s) {
            final latest = latestValue(s.metric);
            final total = s.values.fold<double>(0, (sum, v) => sum + v);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: s.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                  ),
                  Text(
                    'Now ${_formatMetricValue(s.metric, latest)} · Total ${_formatMetricValue(s.metric, total)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: s.color,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            'Exact numbers',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Scroll sideways in the table to compare periods quickly.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          _TrendDataTable(
            labels: buckets.map(_labelForBucket).toList(),
            series: series,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _MetricToggleChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _MetricToggleChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : const Color(0xFF94A3B8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              size: 14,
              color: selected ? color : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? color : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendlyKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _FriendlyKpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineTrendChart extends StatelessWidget {
  final List<_TrendSeries> series;
  final List<String> labels;
  final bool isDark;
  final bool moneyScale;

  const _LineTrendChart({
    required this.series,
    required this.labels,
    required this.isDark,
    required this.moneyScale,
  });

  @override
  Widget build(BuildContext context) {
    var maxY = 1.0;
    for (final s in series) {
      for (final v in s.values) {
        if (v > maxY) maxY = v;
      }
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.slate200,
        ),
      ),
      child: SizedBox(
        height: 240,
        child: CustomPaint(
          painter: _LineTrendPainter(
            series: series,
            labels: labels,
            maxY: maxY,
            isDark: isDark,
            moneyScale: moneyScale,
          ),
        ),
      ),
    );
  }
}

class _LineTrendPainter extends CustomPainter {
  final List<_TrendSeries> series;
  final List<String> labels;
  final double maxY;
  final bool isDark;
  final bool moneyScale;

  _LineTrendPainter({
    required this.series,
    required this.labels,
    required this.maxY,
    required this.isDark,
    required this.moneyScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final left = 34.0;
    final right = size.width - 6;
    final top = 8.0;
    final bottom = size.height - 28;
    final width = right - left;
    final height = bottom - top;

    final grid = Paint()
      ..color = (isDark ? const Color(0xFF334155) : AppColors.slate200)
          .withValues(alpha: 0.7)
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    const gridLines = 4;
    for (var i = 0; i <= gridLines; i++) {
      final y = top + (height * i / gridLines);
      canvas.drawLine(Offset(left, y), Offset(right, y), grid);

      final tickValue = maxY * (1 - (i / gridLines));
      final tickText = moneyScale
          ? '\$${tickValue.toStringAsFixed(0)}'
          : tickValue.toStringAsFixed(0);
      final tickSpan = TextSpan(
        text: tickText,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      );
      textPainter.text = tickSpan;
      textPainter.layout(maxWidth: left - 6);
      textPainter.paint(
        canvas,
        Offset(2, y - (textPainter.height / 2)),
      );
    }

    final axisColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final n = labels.length;
    final stepX = n <= 1 ? 0.0 : width / (n - 1);

    for (var i = 0; i < n; i++) {
      final x = left + (stepX * i);
      if (i % math.max(1, (n / 6).floor()) != 0 && i != n - 1) continue;
      final tp = TextSpan(
        text: labels[i],
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: axisColor,
        ),
      );
      textPainter.text = tp;
      textPainter.layout(maxWidth: 72);
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2), bottom + 6),
      );
    }

    if (series.isEmpty || n == 0) return;

    for (final s in series) {
      final line = Paint()
        ..color = s.color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;
      final dots = Paint()
        ..color = s.color
        ..style = PaintingStyle.fill;

      final path = Path();
      for (var i = 0; i < n; i++) {
        final value = i < s.values.length ? s.values[i] : 0.0;
        final x = left + (stepX * i);
        final y = bottom - ((value / math.max(1, maxY)) * height);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, line);

      for (var i = 0; i < n; i++) {
        final value = i < s.values.length ? s.values[i] : 0.0;
        final x = left + (stepX * i);
        final y = bottom - ((value / math.max(1, maxY)) * height);
        canvas.drawCircle(Offset(x, y), 2.4, dots);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineTrendPainter oldDelegate) {
    return oldDelegate.maxY != maxY ||
        oldDelegate.isDark != isDark ||
        oldDelegate.moneyScale != moneyScale ||
        oldDelegate.labels != labels ||
        oldDelegate.series != series;
  }
}

class _TrendDataTable extends StatelessWidget {
  final List<String> labels;
  final List<_TrendSeries> series;
  final bool isDark;

  const _TrendDataTable({
    required this.labels,
    required this.series,
    required this.isDark,
  });

  String _fmt(_TrendMetric metric, double value) {
    if (metric == _TrendMetric.moneyMade) {
      return '\$${value.toStringAsFixed(0)}';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.slate200,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(10),
        child: DataTable(
          headingTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.slate900,
          ),
          dataTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.slate900,
          ),
          columns: [
            const DataColumn(label: Text('Period')),
            ...series.map((s) => DataColumn(label: Text(s.label))),
          ],
          rows: List.generate(labels.length, (i) {
            return DataRow(
              cells: [
                DataCell(Text(labels[i])),
                ...series.map((s) => DataCell(Text(_fmt(s.metric, s.values[i])))),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  final bool isDark;

  const _EmptyCard({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.slate200,
        ),
      ),
      child: Text(
        message,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF94A3B8),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ConvoCard extends StatelessWidget {
  final String name;
  final String? contextLabel;
  final String preview;
  final DateTime? time;
  final bool isDark;
  final VoidCallback? onDelete;
  final VoidCallback onTap;

  const _ConvoCard({
    required this.name,
    this.contextLabel,
    required this.preview,
    this.time,
    required this.isDark,
    this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .map((w) => w.isEmpty ? '' : w[0])
        .take(2)
        .join()
        .toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.indigo600, Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      initials,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.slate900,
                              ),
                            ),
                          ),
                          if (time != null)
                            Text(
                              _formatTime(time!),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                        ],
                      ),
                      if (contextLabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          contextLabel!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.indigo600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 3),
                      Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Color(0xFFDC2626),
                    ),
                    tooltip: 'Delete conversation',
                  ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? const Color(0xFF334155)
                      : AppColors.slate200,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dt.month - 1];
    final day = dt.day.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month $day, $hour:$minute';
  }
}

void _confirmDeleteConversation(
  BuildContext context, {
  required AppState state,
  required String conversationId,
  required bool isDark,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      title: Text(
        'Delete conversation?',
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : AppColors.slate900,
        ),
      ),
      content: Text(
        'This removes the conversation and messages for both people.',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF94A3B8),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await state.deleteConversation(conversationId);
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

class _LimitIndicator extends StatelessWidget {
  final String label;
  final int current;
  final int max;
  final Color color;
  final bool isDark;

  const _LimitIndicator({
    required this.label,
    required this.current,
    required this.max,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    final atLimit = current >= max;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: atLimit
              ? const Color(0xFFEA580C).withValues(alpha: 0.4)
              : isDark
                  ? const Color(0xFF334155)
                  : AppColors.slate200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
              Text(
                '$current / $max',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: atLimit
                      ? const Color(0xFFEA580C)
                      : isDark
                          ? Colors.white
                          : AppColors.slate900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: isDark
                  ? const Color(0xFF334155)
                  : AppColors.slate200,
              color: atLimit ? const Color(0xFFEA580C) : color,
            ),
          ),
        ],
      ),
    );
  }
}
