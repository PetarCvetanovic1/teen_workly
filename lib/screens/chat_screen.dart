import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/content_wrap.dart';
import '../widgets/report_sheet.dart';
import '../widgets/walking_dog_loader.dart';
import '../utils/smooth_route.dart';
import 'login_screen.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String? contextLabel;
  const ChatScreen({
    super.key,
    required this.conversationId,
    this.otherUserName = '',
    this.contextLabel,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with WidgetsBindingObserver {
  final _msgCtrl = TextEditingController();
  final _msgFocusNode = FocusNode();
  final _scrollCtrl = ScrollController();
  bool _typingSent = false;
  DateTime? _lastSeenMarkedAt;
  String? _lastRenderedMessageId;
  bool _loginRedirectQueued = false;
  ChatMessage? _editingMessage;
  static final RegExp _phoneRe = RegExp(r'(?<!\d)(?:\+?\d[\d\s().-]{7,}\d)');
  static final RegExp _emailRe =
      RegExp(r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b', caseSensitive: false);
  static final RegExp _socialRe = RegExp(
    r'(?:^|\s)(@[\w._]{2,}|snap(?:chat)?|instagram|insta|ig|tiktok|discord|telegram|whatsapp)\b',
    caseSensitive: false,
  );
  static const Duration _typingFreshnessWindow = Duration(seconds: 10);

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _msgCtrl.addListener(_onInputChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _msgFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _msgCtrl.removeListener(_onInputChanged);
    unawaited(_setTyping(false));
    _msgCtrl.dispose();
    _msgFocusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(_setTyping(false));
    }
  }

  void _onInputChanged() {
    final hasText = _msgCtrl.text.trim().isNotEmpty;
    if (!hasText) {
      unawaited(_setTyping(false));
      return;
    }
    unawaited(_setTyping(true));
  }

  Future<void> _setTyping(bool isTyping) async {
    if (_typingSent == isTyping) return;
    _typingSent = isTyping;
    try {
      await context.read<AppState>().setConversationTyping(
            widget.conversationId,
            isTyping,
          );
    } catch (_) {}
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollCtrl.hasClients) return;
    final target = _scrollCtrl.position.maxScrollExtent;
    if (!animated) {
      _scrollCtrl.jumpTo(target);
      return;
    }
    _scrollCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    if (_containsContactInfo(text)) {
      _showContactBlockedDialog();
      return;
    }

    await _setTyping(false);
    if (!mounted) return;
    try {
      if (_editingMessage != null) {
        await context.read<AppState>().editOwnMessage(
              conversationId: widget.conversationId,
              message: _editingMessage!,
              newText: text,
            );
      } else {
        await context.read<AppState>().sendMessage(widget.conversationId, text);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFDC2626),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    if (mounted) {
      setState(() => _editingMessage = null);
    }
    _msgCtrl.clear();
    if (mounted) {
      _msgFocusNode.requestFocus();
    }
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startEditingMessage(ChatMessage msg) {
    setState(() => _editingMessage = msg);
    _msgCtrl.value = TextEditingValue(
      text: msg.text,
      selection: TextSelection.collapsed(offset: msg.text.length),
    );
    _msgFocusNode.requestFocus();
  }

  void _cancelEditingMessage() {
    setState(() => _editingMessage = null);
    _msgCtrl.clear();
    _msgFocusNode.requestFocus();
  }

  KeyEventResult _handleComposerKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final isEnter =
        key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter;
    if (!isEnter) return KeyEventResult.ignored;

    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final shiftPressed =
        pressed.contains(LogicalKeyboardKey.shift) ||
        pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight);

    if (shiftPressed) {
      _insertComposerNewline();
      return KeyEventResult.handled;
    }

    _send();
    return KeyEventResult.handled;
  }

  void _insertComposerNewline() {
    final value = _msgCtrl.value;
    final text = value.text;
    final selection = value.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : start;
    final newText = text.replaceRange(start, end, '\n');
    final caret = start + 1;
    _msgCtrl.value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: caret),
      composing: TextRange.empty,
    );
  }

  void _focusComposer() {
    if (!mounted) return;
    _msgFocusNode.requestFocus();
  }

  String? _jobIdFromScopeKey(String? scopeKey) {
    final raw = (scopeKey ?? '').trim();
    if (!raw.startsWith('job:')) return null;
    final id = raw.substring(4).trim();
    return id.isEmpty ? null : id;
  }

  bool _containsContactInfo(String text) {
    return _phoneRe.hasMatch(text) ||
        _emailRe.hasMatch(text) ||
        _socialRe.hasMatch(text);
  }

  Future<void> _showContactBlockedDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keep it in the app'),
        content: const Text(
          'For your safety, sharing personal contact info is disabled. '
          'Use the in-app call or chat instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showConversationActions(String? otherUserId) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Color(0xFFDC2626)),
                title: const Text('Report conversation'),
                subtitle: const Text('Send a detailed report to moderators'),
                onTap: () {
                  Navigator.pop(ctx);
                  showReportSheet(
                    context,
                    targetType: 'Conversation',
                    targetId: widget.conversationId,
                    userId: otherUserId,
                    userName: widget.otherUserName,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_rounded, color: Color(0xFFDC2626)),
                title: const Text('Block user'),
                subtitle: const Text('Hide all content from this user'),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (otherUserId == null || otherUserId.trim().isEmpty) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not block this user right now.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  await context.read<AppState>().blockUser(
                        userId: otherUserId,
                        targetType: 'Conversation',
                        targetId: widget.conversationId,
                        reason: 'Blocked from chat actions',
                      );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User blocked.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFDC2626)),
                title: const Text('Delete conversation'),
                subtitle: const Text(
                  'Make this chat view-only and mute notifications',
                ),
                onTap: () async {
                  final appState = context.read<AppState>();
                  Navigator.pop(ctx);
                  final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dctx) => AlertDialog(
                          title: const Text('Delete conversation?'),
                          content: const Text(
                            'This chat becomes view-only for you and mutes new message notifications.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(dctx, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                  if (!confirmed) return;
                  await appState.deleteConversation(widget.conversationId);
                  if (!mounted) return;
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMessageActions(
    ChatMessage msg, {
    required bool isMe,
    required String? otherUserId,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMe && !msg.isDeleted)
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.indigo600,
                ),
                title: const Text('Edit message'),
                onTap: () async {
                  Navigator.pop(ctx);
                  _startEditingMessage(msg);
                },
              ),
            if (isMe && !msg.isDeleted)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFDC2626)),
                title: const Text('Delete for everyone'),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await context.read<AppState>().deleteMessageForEveryone(
                          conversationId: widget.conversationId,
                          message: msg,
                        );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$e'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFFDC2626),
                      ),
                    );
                  }
                },
              ),
            if (!isMe)
              ListTile(
                leading:
                    const Icon(Icons.flag_outlined, color: Color(0xFFDC2626)),
                title: const Text('Flag message'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await context.read<AppState>().reportContent(
                        targetType: 'Message',
                        targetId: msg.id,
                        reason:
                            'Creepy Behavior: flagged from message in conversation ${widget.conversationId}',
                        userId: otherUserId,
                      );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message flagged for safety review.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = context.watch<AppState>();
    _queueLoginRedirectIfNeeded(authState);
    if (!authState.isLoggedIn) {
      return const Scaffold(body: WalkingDogLoader(label: 'Walking the dog...'));
    }

    final state = context.read<AppState>();
    final initials = widget.otherUserName
        .split(' ')
        .map((w) => w.isEmpty ? '' : w[0])
        .take(2)
        .join()
        .toUpperCase();

    return StreamBuilder<Conversation?>(
      stream: state.conversationStream(widget.conversationId),
      builder: (context, conversationSnap) {
        final conversation = conversationSnap.data;
        final now = DateTime.now();
        final otherTyping = conversation != null &&
            conversation.typingBy.entries.any((e) {
              if (e.key == state.currentUserId || e.value != true) return false;
              final updatedAt = conversation.typingUpdatedAtBy[e.key];
              if (updatedAt == null) return false;
              return now.difference(updatedAt) <= _typingFreshnessWindow;
            });
        final otherSeenAt = conversation == null
            ? null
            : conversation.lastSeenBy[conversation.otherUserId];
        final readOnlyForMe =
            conversation?.isReadOnlyFor(state.currentUserId) ?? false;
        final scopedJobId = _jobIdFromScopeKey(conversation?.scopeKey);
        final isHiredForScopedJob = scopedJobId != null &&
            authState.jobs.any(
              (j) => j.id == scopedJobId && j.hiredId == authState.currentUserId,
            );
        final showHireSafetyReminder = scopedJobId != null &&
            isHiredForScopedJob &&
            !authState.isHireSafetyNoticeDismissed(scopedJobId);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            elevation: 1,
            shadowColor: Colors.black.withValues(alpha: 0.06),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.indigo600, Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.otherUserName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                      ),
                      if (otherTyping)
                        Text(
                          'typing...',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF7C3AED),
                          ),
                        )
                      else if (widget.contextLabel != null)
                        Text(
                          widget.contextLabel ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.indigo600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Conversation actions',
                onPressed: () => _showConversationActions(conversation?.otherUserId),
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: readOnlyForMe ? null : _focusComposer,
            child: ContentWrap(
              child: Column(
              children: [
                if (showHireSafetyReminder)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    child: _HireSafetyNoticeCard(
                      onDismiss: () => unawaited(
                        authState.dismissHireSafetyNotice(scopedJobId),
                      ),
                    ),
                  ),
                if (readOnlyForMe)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        'This conversation is read-only for you.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF9A3412),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream: conversation == null
                        ? null
                        : state.messagesStream(widget.conversationId),
                    builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Could not load messages: ${snapshot.error}',
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
                  final messages = snapshot.data ?? const <ChatMessage>[];
                  final latestMessageId =
                      messages.isEmpty ? null : messages.last.id;
                  final hasNewMessage = latestMessageId != null &&
                      latestMessageId != _lastRenderedMessageId;
                  if (hasNewMessage) {
                    _lastRenderedMessageId = latestMessageId;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _scrollToBottom(
                        animated: messages.length > 1,
                      );
                    });
                  }
                  ChatMessage? latestIncoming;
                  for (final m in messages.reversed) {
                    if (m.senderId != state.currentUserId) {
                      latestIncoming = m;
                      break;
                    }
                  }
                  if (latestIncoming != null &&
                      (_lastSeenMarkedAt == null ||
                          latestIncoming.timestamp.isAfter(_lastSeenMarkedAt!))) {
                    _lastSeenMarkedAt = latestIncoming.timestamp;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      unawaited(state.markConversationSeen(widget.conversationId));
                    });
                  }
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: AppColors.indigo600.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Say hello!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final prev = index > 0 ? messages[index - 1] : null;
                      final showDayDivider = prev == null ||
                          prev.timestamp.year != msg.timestamp.year ||
                          prev.timestamp.month != msg.timestamp.month ||
                          prev.timestamp.day != msg.timestamp.day;
                      final isMe = msg.senderId == state.currentUserId;
                      final seenByOther = isMe &&
                          otherSeenAt != null &&
                          !msg.timestamp.isAfter(otherSeenAt);
                      return Column(
                        children: [
                          if (showDayDivider)
                            _DayDivider(timestamp: msg.timestamp, isDark: isDark),
                          _ChatBubble(
                            text: msg.text,
                            senderName: msg.senderName,
                            isMe: isMe,
                            isDark: isDark,
                            timestamp: msg.timestamp,
                            seenByOther: seenByOther,
                            isDeleted: msg.isDeleted,
                            isEdited: msg.isEdited,
                            editedAt: msg.editedAt,
                            deletedByName: msg.deletedByName,
                            onLongPress: () => _showMessageActions(
                              msg,
                              isMe: isMe,
                              otherUserId: conversation?.otherUserId,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
                if (otherTyping)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : AppColors.slate200,
                          ),
                        ),
                        child: Text(
                          '${widget.otherUserName} is typing...',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Input bar
                Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 8,
                    top: 12,
                    bottom: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        (isDark ? const Color(0xFF1E293B) : Colors.white),
                        (isDark
                            ? const Color(0xFF1E293B).withValues(alpha: 0.96)
                            : const Color(0xFFF8FAFC)),
                      ],
                    ),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : AppColors.slate200,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (readOnlyForMe)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    const Color(0xFF0EA5E9).withValues(alpha: 0.28),
                              ),
                            ),
                            child: Text(
                              'View-only chat. New messages here are muted for you.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.slate900,
                              ),
                            ),
                          ),
                        if (_editingMessage != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.indigo600.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.indigo600.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.edit_rounded,
                                  size: 16,
                                  color: AppColors.indigo600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Editing message',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : AppColors.slate900,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _cancelEditingMessage,
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: Focus(
                                onKeyEvent: _handleComposerKey,
                                child: TextField(
                                  controller: _msgCtrl,
                                  focusNode: _msgFocusNode,
                                  enabled: !readOnlyForMe,
                                  autofocus: true,
                                  minLines: 1,
                                  maxLines: 5,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.send,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white : AppColors.slate900,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: _editingMessage == null
                                        ? 'Type a message...'
                                        : 'Edit your message...',
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? const Color(0xFF0F172A)
                                            .withValues(alpha: 0.5)
                                        : AppColors.slate100,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  onChanged: (_) => _onInputChanged(),
                                  onSubmitted: (_) {
                                    if (!readOnlyForMe) _send();
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: readOnlyForMe
                                  ? const Color(0xFF94A3B8)
                                  : AppColors.indigo600,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: readOnlyForMe
                                    ? null
                                    : (_containsContactInfo(_msgCtrl.text.trim())
                                        ? _showContactBlockedDialog
                                        : _send),
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(
                                    _editingMessage == null
                                        ? Icons.send_rounded
                                        : Icons.check_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final String senderName;
  final bool isMe;
  final bool isDark;
  final DateTime timestamp;
  final bool seenByOther;
  final bool isDeleted;
  final bool isEdited;
  final DateTime? editedAt;
  final String? deletedByName;
  final VoidCallback? onLongPress;

  const _ChatBubble({
    required this.text,
    required this.senderName,
    required this.isMe,
    required this.isDark,
    required this.timestamp,
    this.seenByOther = false,
    this.isDeleted = false,
    this.isEdited = false,
    this.editedAt,
    this.deletedByName,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final double maxBubbleWidth =
        (MediaQuery.of(context).size.width * 0.60).clamp(0.0, 560.0).toDouble();
    final deletedLabel =
        '${(deletedByName ?? senderName).trim().isEmpty ? "Someone" : (deletedByName ?? senderName)} deleted this message';
    final visibleText = isDeleted
        ? deletedLabel
        : (text.trim().isEmpty ? '(empty message)' : text);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxBubbleWidth,
          ),
          child: GestureDetector(
            onLongPress: onLongPress,
            child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isMe
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.indigo600, Color(0xFF7C3AED)],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF1E293B),
                              const Color(0xFF0F172A),
                            ]
                          : [
                              Colors.white,
                              const Color(0xFFF8FAFC),
                            ],
                    ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              border: isMe
                  ? null
                  : Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : AppColors.slate200,
                    ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      senderName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                if (isMe && !isDeleted && onLongPress != null)
                  InkWell(
                    onTap: onLongPress,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                Text(
                  visibleText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: isDeleted ? FontWeight.w600 : FontWeight.w500,
                    fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                    color: isMe
                        ? Colors.white
                        : isDark
                            ? Colors.white
                            : AppColors.slate900,
                  ),
                ),
                if (!isDeleted && isEdited) ...[
                  const SizedBox(height: 4),
                  Text(
                    'edited on ${_formatTime(editedAt ?? timestamp)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.72)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(timestamp),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.6)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Icon(
                        seenByOther
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                        size: 14,
                        color: seenByOther
                            ? const Color(0xFF22C55E)
                            : Colors.white.withValues(alpha: 0.85),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          )),
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

class _DayDivider extends StatelessWidget {
  final DateTime timestamp;
  final bool isDark;

  const _DayDivider({
    required this.timestamp,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final label = '${months[timestamp.month - 1]} ${timestamp.day}, ${timestamp.year}';
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: isDark ? const Color(0xFF334155) : AppColors.slate200,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.7)
                  : AppColors.slate100,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: isDark ? const Color(0xFF334155) : AppColors.slate200,
            ),
          ),
        ],
      ),
    );
  }
}

class _HireSafetyNoticeCard extends StatelessWidget {
  final VoidCallback onDismiss;
  const _HireSafetyNoticeCard({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF59E0B).withValues(alpha: 0.18),
            (isDark ? const Color(0xFF1E293B) : Colors.white),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.shield_moon_rounded,
              size: 18,
              color: Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safety Reminder',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Please tell a parent or guardian where you are going before you leave.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onDismiss,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: Text(
              'Dismiss',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFEA580C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
