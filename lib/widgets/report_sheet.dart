import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../state/app_state.dart';

const _reasons = [
  'Creepy behavior',
  'Inappropriate or offensive content',
  'Spam or scam',
  'Misleading information',
  'Harassment or bullying',
  'Unsafe for teens',
  'Other',
];

void showReportSheet(
  BuildContext context, {
  required String targetType,
  required String targetId,
  String? userId,
  String? userName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ReportSheet(
      targetType: targetType,
      targetId: targetId,
      userId: userId,
      userName: userName,
    ),
  );
}

Future<void> showSafetyActionsSheet(
  BuildContext context, {
  required String targetType,
  required String targetId,
  required String userId,
  String? userName,
  Future<void> Function()? onHide,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              ListTile(
                leading: const Icon(Icons.flag_outlined,
                    color: Color(0xFFDC2626)),
                title: Text(
                  'Report',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
                subtitle: Text(
                  'Send a report to moderators',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  showReportSheet(
                    context,
                    targetType: targetType,
                    targetId: targetId,
                    userId: userId,
                    userName: userName,
                  );
                },
              ),
              if (onHide != null)
                ListTile(
                  leading: const Icon(Icons.visibility_off_outlined,
                      color: Color(0xFF64748B)),
                  title: Text(
                    'Hide',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                  subtitle: Text(
                    'Remove this from your feed',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  onTap: () async {
                    await onHide();
                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hidden from your feed.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.block_rounded,
                    color: Color(0xFFDC2626)),
                title: Text(
                  'Block user',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
                subtitle: Text(
                  'Hide all content from this user',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                onTap: () async {
                  final state = context.read<AppState>();
                  await state.blockUser(
                    userId: userId,
                    targetType: targetType,
                    targetId: targetId,
                    reason: 'Blocked from safety actions',
                  );
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User blocked. Their posts are hidden.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ReportSheet extends StatefulWidget {
  final String targetType;
  final String targetId;
  final String? userId;
  final String? userName;

  const _ReportSheet({
    required this.targetType,
    required this.targetId,
    this.userId,
    this.userName,
  });

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final Set<String> _selectedReasons = <String>{};
  bool _alsoBlock = false;
  final _otherCtrl = TextEditingController();

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF334155) : AppColors.slate200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.flag_rounded,
                color: Color(0xFFDC2626),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Report ${widget.targetType}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Help us keep TeenWorkly safe. Select a reason below.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ...List.generate(_reasons.length, (i) {
              final reason = _reasons[i];
              final selected = _selectedReasons.contains(reason);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedReasons.remove(reason);
                      } else {
                        _selectedReasons.add(reason);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFDC2626).withValues(alpha: 0.08)
                          : isDark
                              ? const Color(0xFF0F172A)
                                  .withValues(alpha: 0.5)
                              : AppColors.slate100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFDC2626)
                                .withValues(alpha: 0.4)
                            : isDark
                                ? const Color(0xFF334155)
                                : AppColors.slate200,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          size: 20,
                          color: selected
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            reason,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected
                                  ? (isDark
                                      ? Colors.white
                                      : AppColors.slate900)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tell us what happened (optional)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _otherCtrl,
              maxLines: 3,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
              decoration: InputDecoration(
                hintText: 'Describe what happened...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                    : AppColors.slate100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 8),
            if (widget.userId != null) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _alsoBlock = !_alsoBlock),
                child: Row(
                  children: [
                    Icon(
                      _alsoBlock
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 22,
                      color: _alsoBlock
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Also block ${widget.userName ?? "this user"}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: _selectedReasons.isNotEmpty
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF94A3B8),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: _selectedReasons.isNotEmpty ? _submit : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flag_rounded,
                            size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          _alsoBlock ? 'Report & Block' : 'Submit Report',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final state = context.read<AppState>();

    if (state.hasAlreadyReported(widget.targetId)) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You\'ve already reported this.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFEA580C),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final selectedList = _selectedReasons.toList()..sort();
    final details = _otherCtrl.text.trim();
    final reason = details.isNotEmpty
        ? 'Reasons: ${selectedList.join(', ')}\nDetails: $details'
        : 'Reasons: ${selectedList.join(', ')}';

    await state.reportContent(
      targetType: widget.targetType,
      targetId: widget.targetId,
      reason: reason,
      block: _alsoBlock,
      userId: widget.userId,
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _alsoBlock
              ? 'Reported & blocked. Thanks for keeping TeenWorkly safe.'
              : 'Report submitted. Thanks for keeping TeenWorkly safe.',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
