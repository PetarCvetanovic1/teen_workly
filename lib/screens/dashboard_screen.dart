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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _hideCompletedItems = false;
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
          final completed = _hideCompletedItems ? <Job>[] : state.myCompletedJobs;
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
                if (state.amVerified) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.indigo600.withValues(alpha: 0.1),
                          const Color(0xFF059669).withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF059669).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.verified_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verified Worker',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                              Text(
                                '${state.myReviewCount} reviews · ${state.myRating.toStringAsFixed(1)} avg rating',
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
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : AppColors.slate200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified_outlined,
                            size: 20,
                            color: const Color(0xFF94A3B8)
                                .withValues(alpha: 0.6)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Complete 5+ jobs with a 3.5+ rating to get verified',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
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
                        value: '${completed.length}',
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
                  ...myServices.map(
                    (s) => _ServiceCard(
                      service: s,
                      isDark: isDark,
                      onDelete: () => _confirmDelete(
                        context,
                        isDark: isDark,
                        title: 'Delete Service',
                        message:
                            'Remove your "${s.skills.join(", ")}" service listing?',
                        onConfirm: () async => await state.deleteService(s.id),
                      ),
                    ),
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
                            job.location,
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
  final VoidCallback? onDelete;

  const _ServiceCard({
    required this.service,
    required this.isDark,
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
                    service.location,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              GestureDetector(
                onTap: onDelete,
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
          ],
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
