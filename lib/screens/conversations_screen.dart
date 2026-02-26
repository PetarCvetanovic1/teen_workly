import 'package:flutter/material.dart';
import '../utils/smooth_route.dart';
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

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

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
          SmoothPageRoute(builder: (_) => const HomeScreen()),
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
                            name: conv.otherUserName,
                            context: conv.contextLabel,
                            preview: conv.lastMessagePreview,
                            time: conv.lastMessageTime,
                            isDark: isDark,
                            onTap: () => Navigator.of(context).push(
                              SmoothPageRoute(
                                builder: (_) =>
                                    ChatScreen(
                                      conversationId: conv.id,
                                      otherUserName: conv.otherUserName,
                                      contextLabel: conv.contextLabel,
                                    ),
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

class _ConversationTile extends StatelessWidget {
  final String name;
  final String? context;
  final String preview;
  final DateTime? time;
  final bool isDark;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.name,
    this.context,
    required this.preview,
    this.time,
    required this.isDark,
    required this.onTap,
  });

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context_) {
    final initials = name.split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join().toUpperCase();

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
