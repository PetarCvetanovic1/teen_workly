import 'package:flutter/material.dart';
import '../utils/auth_navigation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../services/firestore_service.dart';
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
    final state = context.watch<AppState>();
    final myId = state.currentUserId;
    final lastJobsSeenAt = state.jobsFeedSeenAt;
    final unseenBrowseJobCount = state.jobs.where((j) {
      final notCompleted = j.status != JobStatus.completed;
      final notMine = j.posterId != myId;
      final notBlocked = !state.isBlocked(j.posterId);
      final notHidden = !state.isJobHidden(j.id);
      final notApplied = !j.applicantIds.contains(myId);
      final notHiredByMe = j.hiredId != myId;
      final unseen = lastJobsSeenAt == null || j.createdAt.isAfter(lastJobsSeenAt);
      return notCompleted &&
          notMine &&
          notBlocked &&
          notHidden &&
          notApplied &&
          notHiredByMe &&
          unseen;
    }).length;

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
            StreamBuilder<List<HuddlePost>>(
              stream: state.isLoggedIn
                  ? FirestoreService.huddleStream(state.myAgeGroup)
                  : const Stream<List<HuddlePost>>.empty(),
              builder: (context, snap) {
                final posts = snap.data ?? const <HuddlePost>[];
                final lastHuddleSeenAt = state.huddleFeedSeenAt;
                final unseenCount = posts
                    .where((p) =>
                        !state.isBlocked(p.authorId) &&
                        !state.isHuddlePostHidden(p.id) &&
                        (lastHuddleSeenAt == null ||
                            p.createdAt.isAfter(lastHuddleSeenAt)))
                    .length;
                return _NavChip(
                  label: 'The Huddle',
                  icon: Icons.groups_rounded,
                  color: const Color(0xFFF59E0B),
                  compact: compact,
                  badgeLabel: unseenCount > 0 ? 'New!' : null,
                  onTap: () => replaceTopLevel(
                    const HuddleScreen(),
                    requiresAuth: true,
                  ),
                  isDark: isDark,
                );
              },
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
              badgeLabel: unseenBrowseJobCount > 0 ? 'New!' : null,
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
            StreamBuilder<List<Conversation>>(
              stream: state.isLoggedIn
                  ? state.conversationsStream
                  : const Stream<List<Conversation>>.empty(),
              builder: (context, convoSnap) {
                final convos = convoSnap.data ?? const <Conversation>[];
                return FutureBuilder<int>(
                  future: _computeUnreadCount(state, convos),
                  builder: (context, unreadSnap) {
                    final unread = unreadSnap.data ?? 0;
                    return _NavChip(
                      label: 'Messages',
                      icon: Icons.chat_rounded,
                      color: const Color(0xFF0EA5E9),
                      compact: compact,
                      badgeCount: unread,
                      onTap: () => replaceTopLevel(
                        const ConversationsScreen(),
                        requiresAuth: true,
                      ),
                      isDark: isDark,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<int> _computeUnreadCount(
    AppState state,
    List<Conversation> convos,
  ) async {
    if (!state.isLoggedIn || convos.isEmpty) return 0;
    final counts = await Future.wait(
      convos.map((c) {
        if (c.isMutedFor(state.currentUserId)) {
          return Future<int>.value(0);
        }
        final seenAt = c.lastSeenBy[state.currentUserId] ?? c.lastMessageTime;
        return state.unreadCountStream(
          conversationId: c.id,
          lastSeenAt: seenAt,
          suppress: c.isMutedFor(state.currentUserId),
        ).first;
      }),
    );
    final total = counts.fold<int>(0, (sum, c) => sum + c);
    return total > 99 ? 99 : total;
  }
}

class _NavChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;
  final bool compact;
  final int badgeCount;
  final String? badgeLabel;

  const _NavChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
    this.compact = false,
    this.badgeCount = 0,
    this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final labelText = (badgeLabel ?? '').trim();
    final hasBadge = labelText.isNotEmpty || badgeCount > 0;
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
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
              if (hasBadge)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      ),
                    ),
                    child: Text(
                      labelText.isNotEmpty
                          ? labelText
                          : (badgeCount > 99 ? '99+' : '$badgeCount'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
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
