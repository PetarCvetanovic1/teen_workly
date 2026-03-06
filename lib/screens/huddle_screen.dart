import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../services/firestore_service.dart';
import '../services/moderation.dart';
import '../widgets/content_wrap.dart';
import '../widgets/report_sheet.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tw_app_bar.dart';
import '../utils/smooth_route.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class HuddleScreen extends StatefulWidget {
  const HuddleScreen({super.key});

  @override
  State<HuddleScreen> createState() => _HuddleScreenState();
}

class _HuddleScreenState extends State<HuddleScreen> {
  HuddleTag? _filterTag;
  bool _newPostSheetOpen = false;
  bool _loginRedirectQueued = false;

  void _queueLoginRedirectIfNeeded(AppState state) {
    if (_loginRedirectQueued || state.isLoggedIn) return;
    _loginRedirectQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        SmoothPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final state = context.watch<AppState>();
    _queueLoginRedirectIfNeeded(state);
    if (!state.isLoggedIn) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
      floatingActionButton: Consumer<AppState>(
        builder: (context, state, _) {
          if (!state.isLoggedIn || keyboardOpen || _newPostSheetOpen) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () =>
                _showNewPostSheet(context, isDark, state.myAgeGroup),
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.edit_rounded, size: 20),
            label: Text(
              'New Post',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          );
        },
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          final myGroup = state.myAgeGroup;
          return Column(
            children: [
              _buildHeader(theme, isDark, myGroup),
              _buildTagFilters(isDark),
              const SizedBox(height: 4),
              Expanded(
                child: StreamBuilder<List<HuddlePost>>(
                  stream: FirestoreService.huddleStream(myGroup),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Could not load The Huddle posts: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      );
                    }
                    final posts = snapshot.data ?? [];
                    return _HuddleFeed(
                      posts: posts,
                      filterTag: _filterTag,
                      isDark: isDark,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, HuddleAgeGroup group) {
    final isUnder = group == HuddleAgeGroup.under16;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: ContentWrap(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.groups_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'The Huddle',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.slate900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isUnder
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                  : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isUnder ? 'Under 16' : '16+',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isUnder
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        isUnder
                            ? 'Chat, collaborate & help each other out'
                            : 'Discuss experiences, share tips & connect',
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
          ],
        ),
      ),
    );
  }

  Widget _buildTagFilters(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _TagChip(
            label: 'All',
            emoji: '🔥',
            selected: _filterTag == null,
            isDark: isDark,
            onTap: () => setState(() => _filterTag = null),
          ),
          const SizedBox(width: 6),
          ...HuddleTag.values.map((tag) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _TagChip(
                  label: tag.label,
                  emoji: tag.emoji,
                  selected: _filterTag == tag,
                  isDark: isDark,
                  onTap: () => setState(() => _filterTag = tag),
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _showNewPostSheet(
      BuildContext context, bool isDark, HuddleAgeGroup ageGroup) async {
    setState(() => _newPostSheetOpen = true);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NewPostSheet(isDark: isDark, ageGroup: ageGroup),
    );
    if (mounted) {
      setState(() => _newPostSheetOpen = false);
    }
  }
}

// -- Tag filter chip --------------------------------------------------------

class _HuddleFeed extends StatelessWidget {
  final List<HuddlePost> posts;
  final HuddleTag? filterTag;
  final bool isDark;

  const _HuddleFeed({
    required this.posts,
    required this.filterTag,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final visible = posts
        .where((p) =>
            !state.isBlocked(p.authorId) && !state.isHuddlePostHidden(p.id))
        .toList();
    final filtered = filterTag == null
        ? visible
        : visible.where((p) => p.tag == filterTag).toList();

    if (filtered.isEmpty) return _EmptyHuddle(isDark: isDark);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: filtered.length,
      itemBuilder: (context, i) => _HuddlePostCard(
        post: filtered[i],
        isDark: isDark,
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? const Color(0xFFF59E0B)
        : isDark
            ? const Color(0xFF1E293B)
            : Colors.white;
    final fg = selected
        ? Colors.white
        : isDark
            ? const Color(0xFF94A3B8)
            : const Color(0xFF64748B);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      elevation: selected ? 2 : 0,
      shadowColor: const Color(0xFFF59E0B).withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: selected
                ? null
                : Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -- Post Card --------------------------------------------------------------

class _HuddlePostCard extends StatefulWidget {
  final HuddlePost post;
  final bool isDark;

  const _HuddlePostCard({required this.post, required this.isDark});

  @override
  State<_HuddlePostCard> createState() => _HuddlePostCardState();
}

class _HuddlePostCardState extends State<_HuddlePostCard> {
  bool _showReplies = false;
  final _replyCtrl = TextEditingController();

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Color get _tagColor {
    switch (widget.post.tag) {
      case HuddleTag.needHelp:
        return const Color(0xFFEF4444);
      case HuddleTag.advice:
        return const Color(0xFFF59E0B);
      case HuddleTag.collab:
        return const Color(0xFF3B82F6);
      case HuddleTag.justChatting:
        return const Color(0xFF8B5CF6);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  Future<void> _submitReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;

    final modResult = await ModerationService.moderateMessage(text);
    if (!modResult.approved) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(modResult.reason ?? 'Content not allowed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    final cleaned = ModerationService.cleanTone(text);
    final wasCleaned = cleaned != text;

    await context.read<AppState>().addHuddleReply(
          postId: widget.post.id,
          text: cleaned,
        );
    if (!mounted) return;
    _replyCtrl.clear();
    FocusScope.of(context).unfocus();

    if (wasCleaned && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your reply was adjusted to keep things respectful.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFF59E0B),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final post = widget.post;
    final isDark = widget.isDark;
    final isOwner = post.authorId == state.currentUserId;
    final initials = post.authorName
        .split(' ')
        .map((w) => w.isEmpty ? '' : w[0])
        .take(2)
        .join()
        .toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ContentWrap(
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onLongPress: isOwner
                            ? null
                            : () => showSafetyActionsSheet(
                                  context,
                                  targetType: 'Huddle',
                                  targetId: post.id,
                                  userId: post.authorId,
                                  userName: post.authorName,
                                  onHide: () =>
                                      context.read<AppState>().hideHuddlePost(post.id),
                                ),
                        onSecondaryTapUp: isOwner
                            ? null
                            : (_) => showSafetyActionsSheet(
                                  context,
                                  targetType: 'Huddle',
                                  targetId: post.id,
                                  userId: post.authorId,
                                  userName: post.authorName,
                                  onHide: () =>
                                      context.read<AppState>().hideHuddlePost(post.id),
                                ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: _tagColor.withValues(alpha: 0.15),
                              child: Text(
                                initials,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _tagColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.authorName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.slate900,
                                    ),
                                  ),
                                  Text(
                                    _timeAgo(post.createdAt),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _tagColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(post.tag.emoji,
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            post.tag.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _tagColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isOwner)
                      IconButton(
                        tooltip: 'Safety actions',
                        icon: const Icon(Icons.shield_outlined,
                            size: 18, color: Color(0xFFDC2626)),
                        onPressed: () => showSafetyActionsSheet(
                          context,
                          targetType: 'Huddle',
                          targetId: post.id,
                          userId: post.authorId,
                          userName: post.authorName,
                          onHide: () =>
                              context.read<AppState>().hideHuddlePost(post.id),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (isOwner)
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            size: 18,
                            color: Colors.red.withValues(alpha: 0.6)),
                        onPressed: () async {
                          await state.deleteHuddlePost(post.id);
                          if (!mounted) return;
                        },
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Delete post',
                      ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Text(
                  post.text,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ),
              ),
              // Reply toggle + count and replies section (from stream)
              StreamBuilder<List<HuddleReply>>(
                stream: FirestoreService.huddleRepliesStream(post.id),
                builder: (context, replySnap) {
                  final replies = replySnap.data ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () =>
                                  setState(() => _showReplies = !_showReplies),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _showReplies
                                          ? Icons.chat_bubble_rounded
                                          : Icons.chat_bubble_outline_rounded,
                                      size: 16,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      replies.isEmpty
                                          ? 'Reply'
                                          : '${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_showReplies)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                                : const Color(0xFFF8FAFC),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(18),
                              bottomRight: Radius.circular(18),
                            ),
                          ),
                          child: Column(
                            children: [
                              if (replies.isNotEmpty)
                                ...replies.map((r) => _ReplyTile(
                                      reply: r,
                                      isDark: isDark,
                                      timeAgo: _timeAgo(r.createdAt),
                                    )),
                              if (state.isLoggedIn)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _replyCtrl,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            color: isDark
                                                ? Colors.white
                                                : AppColors.slate900,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Write a reply...',
                                            hintStyle: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              color: const Color(0xFF94A3B8),
                                            ),
                                            filled: true,
                                            fillColor: isDark
                                                ? const Color(0xFF1E293B)
                                                : Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: isDark
                                                    ? const Color(0xFF334155)
                                                    : const Color(0xFFE2E8F0),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: isDark
                                                    ? const Color(0xFF334155)
                                                    : const Color(0xFFE2E8F0),
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 14, vertical: 10),
                                            isDense: true,
                                          ),
                                          maxLines: 2,
                                          minLines: 1,
                                          textInputAction: TextInputAction.send,
                                          onSubmitted: (_) => _submitReply(),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Material(
                                        color: const Color(0xFFF59E0B),
                                        borderRadius: BorderRadius.circular(10),
                                        child: InkWell(
                                          onTap: _submitReply,
                                          borderRadius: BorderRadius.circular(10),
                                          child: const Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(Icons.send_rounded,
                                                size: 18, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -- Reply tile -------------------------------------------------------------

class _ReplyTile extends StatelessWidget {
  final HuddleReply reply;
  final bool isDark;
  final String timeAgo;

  const _ReplyTile({
    required this.reply,
    required this.isDark,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    final initials = reply.authorName
        .split(' ')
        .map((w) => w.isEmpty ? '' : w[0])
        .take(2)
        .join()
        .toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF64748B).withValues(alpha: 0.15),
            child: Text(
              initials,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reply.authorName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  reply.text,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF475569),
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

// -- Empty state ------------------------------------------------------------

class _EmptyHuddle extends StatelessWidget {
  final bool isDark;
  const _EmptyHuddle({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups_rounded,
                  size: 48, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(height: 20),
            Text(
              'No posts yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to start a conversation!\nAsk for help, share advice, or find a collab partner.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF94A3B8),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- New Post Sheet ---------------------------------------------------------

class _NewPostSheet extends StatefulWidget {
  final bool isDark;
  final HuddleAgeGroup ageGroup;
  const _NewPostSheet({required this.isDark, required this.ageGroup});

  @override
  State<_NewPostSheet> createState() => _NewPostSheetState();
}

class _NewPostSheetState extends State<_NewPostSheet> {
  final _textCtrl = TextEditingController();
  HuddleTag _selectedTag = HuddleTag.justChatting;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    if (text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post must be at least 10 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final modResult = await ModerationService.moderateMessage(text);
    if (!modResult.approved) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(modResult.reason ?? 'Content not allowed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    final cleaned = ModerationService.cleanTone(text);
    final wasCleaned = cleaned != text;

    await context.read<AppState>().addHuddlePost(
          text: cleaned,
          tag: _selectedTag,
          ageGroup: widget.ageGroup,
        );
    if (!mounted) return;
    Navigator.pop(context);

    if (wasCleaned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your post was adjusted to keep things respectful. '
            'You can still share your experience — just keep it factual!',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFF59E0B),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF94A3B8).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'New Post',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.ageGroup == HuddleAgeGroup.under16
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                        : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.ageGroup == HuddleAgeGroup.under16
                        ? 'Under 16'
                        : '16+',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.ageGroup == HuddleAgeGroup.under16
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Tag picker
            Text(
              'WHAT\'S THIS ABOUT?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: HuddleTag.values.map((tag) {
                final selected = _selectedTag == tag;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTag = tag),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFF59E0B)
                          : isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? null
                          : Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(tag.emoji,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          tag.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'YOUR MESSAGE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 8),
            ContentWrap(
              child: TextField(
                controller: _textCtrl,
                maxLines: 5,
                minLines: 3,
                autofocus: true,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.slate900,
                ),
                decoration: InputDecoration(
                  hintText: _selectedTag == HuddleTag.needHelp
                      ? 'What do you need help with?'
                      : _selectedTag == HuddleTag.advice
                          ? 'What advice are you looking for?'
                          : _selectedTag == HuddleTag.collab
                              ? 'What are you looking to collaborate on?'
                              : 'What\'s on your mind?',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                      : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFF59E0B),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(14),
                elevation: 2,
                shadowColor: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                child: InkWell(
                  onTap: _submit,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        'Post to The Huddle',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
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
