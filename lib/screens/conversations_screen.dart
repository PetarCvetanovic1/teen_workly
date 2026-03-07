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
import 'chat_screen.dart';
import 'login_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
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
    final authState = context.watch<AppState>();
    _queueLoginRedirectIfNeeded(authState);
    if (!authState.isLoggedIn) {
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
          appRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        ),
      ),
      drawer: const AppDrawer(),
      body: StreamBuilder<List<Conversation>>(
        stream: context.read<AppState>().conversationsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load conversations: ${snapshot.error}',
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
          final convos = snapshot.data ?? [];

          return ContentWrap(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(
                  'Messages',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Text(
                  '${convos.length} conversation${convos.length == 1 ? '' : 's'}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
              Expanded(
                child: convos.isEmpty
                    ? _EmptyMessages(isDark: isDark)
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: convos.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final conv = convos[index];
                          return _ConversationTile(
                            conversationId: conv.id,
                            name: conv.otherUserName,
                            context: conv.contextLabel,
                            preview: conv.lastMessagePreview,
                            time: conv.lastMessageTime,
                            lastSeenAt: conv.lastSeenBy[authState.currentUserId] ??
                                conv.lastMessageTime,
                            isDark: isDark,
                            onDelete: () => _confirmDeleteConversation(
                              context,
                              conversationId: conv.id,
                              isDark: isDark,
                            ),
                            onTap: () => Navigator.of(context).push(
                              appRoute(
                                builder: (_) =>
                                    ChatScreen(
                                      conversationId: conv.id,
                                      otherUserName: conv.otherUserName,
                                      contextLabel: conv.contextLabel,
                                    ),
                                requiresAuth: true,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          );
        },
      ),
    );
  }
}

Future<void> _confirmDeleteConversation(
  BuildContext context, {
  required String conversationId,
  required bool isDark,
}) async {
  final approved = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (approved != true || !context.mounted) return;
  await context.read<AppState>().deleteConversation(conversationId);
}

class _ConversationTile extends StatelessWidget {
  final String conversationId;
  final String name;
  final String? context;
  final String preview;
  final DateTime? time;
  final DateTime? lastSeenAt;
  final bool isDark;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversationId,
    required this.name,
    this.context,
    required this.preview,
    this.time,
    this.lastSeenAt,
    required this.isDark,
    required this.onDelete,
    required this.onTap,
  });

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

  @override
  Widget build(BuildContext context_) {
    final initials = name.split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join().toUpperCase();
    final state = context_.read<AppState>();

    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.indigo600, Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
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
                              color: isDark ? Colors.white : AppColors.slate900,
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
                        const SizedBox(width: 8),
                        StreamBuilder<int>(
                          stream: state.unreadCountStream(
                            conversationId: conversationId,
                            lastSeenAt: lastSeenAt,
                          ),
                          builder: (context, snapshot) {
                            final unread = snapshot.data ?? 0;
                            if (unread <= 0) return const SizedBox.shrink();
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                unread > 99 ? '99+' : '$unread',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    if (context != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        context!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.indigo600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
                color: isDark ? const Color(0xFF334155) : AppColors.slate200,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMessages extends StatelessWidget {
  final bool isDark;
  const _EmptyMessages({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.indigo600.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 36,
                color: AppColors.indigo600.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No messages yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Message someone from a service listing or get hired for a job to start chatting.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
