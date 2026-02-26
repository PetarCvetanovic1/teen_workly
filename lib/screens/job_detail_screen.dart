import 'package:flutter/material.dart';
import '../utils/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/report_sheet.dart';
import '../widgets/content_wrap.dart';
import 'chat_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;
  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _paymentCtrl = TextEditingController();

  @override
  void dispose() {
    _paymentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppState>(
      builder: (context, state, _) {
        final job = widget.job;
        final isOwner = job.posterId == state.currentUserId;
        final hasApplied = job.applicantIds.contains(state.currentUserId);
        final isHired = job.hiredId == state.currentUserId;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Job Details',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            actions: [
              if (!isOwner)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (value) {
                    if (value == 'report') {
                      showReportSheet(
                        context,
                        targetType: 'Job',
                        targetId: job.id,
                        userId: job.posterId,
                        userName: job.posterName,
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          const Icon(Icons.flag_outlined,
                              size: 18, color: Color(0xFFDC2626)),
                          const SizedBox(width: 10),
                          Text(
                            'Report / Block',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ContentWrap(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Status badge
                  _StatusBadge(job: job),
                const SizedBox(height: 16),
                // Title
                Text(
                  job.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 12),
                // Meta row
                Row(
                  children: [
                    _MetaChip(
                      icon: Icons.person_outline_rounded,
                      label: job.posterName,
                    ),
                    const SizedBox(width: 10),
                    _MetaChip(
                      icon: Icons.location_on_outlined,
                      label: job.location,
                    ),
                    const SizedBox(width: 10),
                    _MetaChip(
                      icon: Icons.schedule_rounded,
                      label: job.type,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Description
                _SectionLabel('DESCRIPTION'),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : AppColors.slate200,
                    ),
                  ),
                  child: Text(
                    job.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Services needed
                _SectionLabel('SERVICES NEEDED'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: job.services.map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.indigo600.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        s,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.indigo600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (job.otherService != null &&
                    job.otherService!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    job.otherService!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // --- Owner view: see applicants + hire ---
                if (isOwner && job.status == JobStatus.open) ...[
                  _SectionLabel(
                    'APPLICANTS (${job.applicantIds.length})',
                  ),
                  const SizedBox(height: 10),
                  if (job.applicantIds.isEmpty)
                    _InfoCard(
                      text: 'No one has applied yet. Hang tight!',
                      isDark: isDark,
                    )
                  else
                    ...List.generate(job.applicantIds.length, (i) {
                      return _ApplicantTile(
                        name: job.applicantNames[i],
                        isDark: isDark,
                        onHire: () async {
                          final applicantActiveJobs = state.jobs
                              .where((j) =>
                                  j.hiredId == job.applicantIds[i] &&
                                  (j.status == JobStatus.inProgress ||
                                      j.status ==
                                          JobStatus.pendingCompletion))
                              .length;
                          if (applicantActiveJobs >= 3) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${job.applicantNames[i]} already has 3 active jobs and can\'t take on more right now.'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: const Color(0xFFEA580C),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            return;
                          }
                          await state.hireApplicant(
                            job.id,
                            job.applicantIds[i],
                            job.applicantNames[i],
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${job.applicantNames[i]} hired! Check your messages.'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        onMessage: () async {
                          final conv = await state.getOrCreateConversation(
                            otherUserId: job.applicantIds[i],
                            otherUserName: job.applicantNames[i],
                            contextLabel: 'Job: ${job.title}',
                          );
                          if (!context.mounted) return;
                          Navigator.of(context).push(
                            SmoothPageRoute(
                              builder: (_) => ChatScreen(
                                conversationId: conv.id,
                                otherUserName: conv.otherUserName,
                                contextLabel: conv.contextLabel,
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  const SizedBox(height: 24),
                ],

                // Owner: in progress → waiting for worker
                if (isOwner && job.status == JobStatus.inProgress) ...[
                  _InfoCard(
                    text:
                        '${job.hiredName} is working on this job. They\'ll mark it finished when done.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: _ActionButton(
                      label: 'Message ${job.hiredName?.split(" ").first}',
                      icon: Icons.chat_rounded,
                      color: AppColors.indigo600,
                      isDark: isDark,
                      onTap: () async {
                        final conv = await state.getOrCreateConversation(
                          otherUserId: job.hiredId!,
                          otherUserName: job.hiredName!,
                          contextLabel: 'Job: ${job.title}',
                        );
                        if (!context.mounted) return;
                        Navigator.of(context).push(
                          SmoothPageRoute(
                            builder: (_) =>
                                ChatScreen(
                                  conversationId: conv.id,
                                  otherUserName: conv.otherUserName,
                                  contextLabel: conv.contextLabel,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Owner: worker says finished → confirm + pay + rate
                if (isOwner && job.status == JobStatus.pendingCompletion) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded,
                            color: Color(0xFFEA580C), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Job Marked as Finished',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFEA580C),
                                ),
                              ),
                              Text(
                                '${job.hiredName} says they\'re done. Confirm to complete the job.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFEA580C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'Message ${job.hiredName?.split(" ").first}',
                          icon: Icons.chat_rounded,
                          color: AppColors.indigo600,
                          isDark: isDark,
                          onTap: () async {
                            final conv = await state.getOrCreateConversation(
                              otherUserId: job.hiredId!,
                              otherUserName: job.hiredName!,
                              contextLabel: 'Job: ${job.title}',
                            );
                            if (!context.mounted) return;
                            Navigator.of(context).push(
                              SmoothPageRoute(
                                builder: (_) => ChatScreen(
                                  conversationId: conv.id,
                                  otherUserName: conv.otherUserName,
                                  contextLabel: conv.contextLabel,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          label: 'Confirm & Complete',
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF059669),
                          isDark: isDark,
                          onTap: () => _showCompleteDialog(context, state, job),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Non-owner: apply or already hired
                if (!isOwner && job.status == JobStatus.open) ...[
                  SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: hasApplied
                          ? const Color(0xFF94A3B8)
                          : isDark
                              ? Colors.white
                              : AppColors.slate900,
                      borderRadius: BorderRadius.circular(16),
                      elevation: hasApplied ? 0 : 4,
                      shadowColor: Colors.black.withValues(alpha: 0.15),
                      child: InkWell(
                        onTap: hasApplied
                            ? null
                            : () async {
                                await state.applyToJob(job.id);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        'Applied! The poster will review your application.'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                hasApplied
                                    ? Icons.check_rounded
                                    : Icons.send_rounded,
                                size: 20,
                                color: hasApplied
                                    ? Colors.white
                                    : isDark
                                        ? AppColors.slate900
                                        : Colors.white,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                hasApplied ? 'Applied' : 'Apply for This Job',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: hasApplied
                                      ? Colors.white
                                      : isDark
                                          ? AppColors.slate900
                                          : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Hired worker: in progress → mark finished
                if (isHired && job.status == JobStatus.inProgress) ...[
                  _InfoCard(
                    text: 'You\'re hired! When you\'re done, tap "Job Finished" below.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'Message ${job.posterName.split(" ").first}',
                          icon: Icons.chat_rounded,
                          color: AppColors.indigo600,
                          isDark: isDark,
                          onTap: () async {
                            final conv = await state.getOrCreateConversation(
                              otherUserId: job.posterId,
                              otherUserName: job.posterName,
                              contextLabel: 'Job: ${job.title}',
                            );
                            if (!context.mounted) return;
                            Navigator.of(context).push(
                              SmoothPageRoute(
                                builder: (_) => ChatScreen(
                                  conversationId: conv.id,
                                  otherUserName: conv.otherUserName,
                                  contextLabel: conv.contextLabel,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          label: 'Job Finished',
                          icon: Icons.task_alt_rounded,
                          color: const Color(0xFF059669),
                          isDark: isDark,
                          onTap: () async {
                            await state.requestCompletion(job.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Marked as finished! Waiting for the poster to confirm.'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Hired worker: pending confirmation
                if (isHired && job.status == JobStatus.pendingCompletion) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_top_rounded,
                            color: Color(0xFFEA580C), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Awaiting Confirmation',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFEA580C),
                                ),
                              ),
                              Text(
                                '${job.posterName} needs to confirm the job is complete.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFEA580C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Completed
                if (job.status == JobStatus.completed) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF059669).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF059669), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Job Completed',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                              if (job.payment > 0)
                                Text(
                                  'Payment: \$${job.payment.toStringAsFixed(0)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Show review if exists, or rate button for owner
                  if (isOwner &&
                      job.hiredId != null &&
                      !state.hasReviewedJob(job.id)) ...[
                    SizedBox(
                      width: double.infinity,
                      child: _ActionButton(
                        label: 'Rate ${job.hiredName?.split(" ").first}',
                        icon: Icons.star_rounded,
                        color: const Color(0xFFEAB308),
                        isDark: isDark,
                        onTap: () => _showRatingDialog(
                          context,
                          state,
                          job,
                          isDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Display existing review for this job
                  ...state.reviews
                      .where((r) => r.jobId == job.id)
                      .map((r) => _ReviewCard(review: r, isDark: isDark)),
                  const SizedBox(height: 24),
                ],

                const SizedBox(height: 24),
              ],
            ),
            ),
          ),
        );
      },
    );
  }

  void _showCompleteDialog(BuildContext context, AppState state, Job job) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Text(
            'Confirm Completion',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How much did you pay for this job?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _paymentCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.slate900,
                ),
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  hintText: '0',
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                      : AppColors.slate100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
            FilledButton(
              onPressed: () async {
                final amount =
                    double.tryParse(_paymentCtrl.text.trim()) ?? 0;
                await state.confirmCompletion(job.id, amount);
                if (!context.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Job confirmed as complete!'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
                _showRatingDialog(context, state, job, isDark);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Confirm',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRatingDialog(
      BuildContext context, AppState state, Job job, bool isDark) {
    int selectedStars = 0;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            backgroundColor:
                isDark ? const Color(0xFF1E293B) : Colors.white,
            title: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFEAB308).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.star_rounded,
                      color: Color(0xFFEAB308), size: 30),
                ),
                const SizedBox(height: 14),
                Text(
                  'Rate ${job.hiredName}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'How was your experience?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final starNum = i + 1;
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedStars = starNum),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          starNum <= selectedStars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 40,
                          color: starNum <= selectedStars
                              ? const Color(0xFFEAB308)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    );
                  }),
                ),
                if (selectedStars > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    selectedStars == 5
                        ? 'Excellent!'
                        : selectedStars == 4
                            ? 'Great!'
                            : selectedStars == 3
                                ? 'Good'
                                : selectedStars == 2
                                    ? 'Fair'
                                    : 'Poor',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFEAB308),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: TextField(
                      controller: commentCtrl,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      minLines: 3,
                      maxLines: 6,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Tell others about your experience (optional)',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
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
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Skip for now',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
              FilledButton(
                onPressed: selectedStars == 0
                    ? null
                    : () async {
                        await state.addReview(
                          jobId: job.id,
                          workerId: job.hiredId!,
                          workerName: job.hiredName!,
                          stars: selectedStars,
                          comment: commentCtrl.text.trim().isEmpty
                              ? null
                              : commentCtrl.text.trim(),
                        );
                        if (!context.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Review submitted!'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEAB308),
                  disabledBackgroundColor:
                      const Color(0xFFEAB308).withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Submit Review',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        });
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Job job;
  const _StatusBadge({required this.job});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;
    switch (job.status) {
      case JobStatus.open:
        text = 'OPEN';
        color = AppColors.indigo600;
        break;
      case JobStatus.inProgress:
        text = 'IN PROGRESS';
        color = const Color(0xFF059669);
        break;
      case JobStatus.pendingCompletion:
        text = 'PENDING CONFIRMATION';
        color = const Color(0xFFEA580C);
        break;
      case JobStatus.completed:
        text = 'COMPLETED';
        color = const Color(0xFF7C3AED);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: color,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        color: const Color(0xFF94A3B8),
      ),
    );
  }
}

class _ApplicantTile extends StatelessWidget {
  final String name;
  final bool isDark;
  final VoidCallback onHire;
  final VoidCallback onMessage;

  const _ApplicantTile({
    required this.name,
    required this.isDark,
    required this.onHire,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join().toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : AppColors.slate200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
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
            IconButton(
              onPressed: onMessage,
              icon: const Icon(Icons.chat_bubble_outline_rounded,
                  color: AppColors.indigo600, size: 20),
              tooltip: 'Message',
            ),
            Material(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onHire,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text(
                    'Hire',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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

class _InfoCard extends StatelessWidget {
  final String text;
  final bool isDark;
  const _InfoCard({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.indigo600.withValues(alpha: 0.08)
            : AppColors.indigo600.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.indigo600.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.indigo600,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  final bool isDark;
  const _ReviewCard({required this.review, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : AppColors.slate200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...List.generate(5, (i) => Icon(
                      i < review.stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 18,
                      color: i < review.stars
                          ? const Color(0xFFEAB308)
                          : const Color(0xFF94A3B8),
                    )),
                const SizedBox(width: 8),
                Text(
                  'by ${review.reviewerName}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.comment!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  color: isDark ? Colors.white : AppColors.slate900,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
