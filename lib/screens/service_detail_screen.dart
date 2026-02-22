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

class ServiceDetailScreen extends StatelessWidget {
  final Service service;
  const ServiceDetailScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.read<AppState>();
    final isOwn = service.providerId == state.currentUserId;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Service Details',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (!isOwn)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (value) {
                if (value == 'report') {
                  showReportSheet(
                    context,
                    targetType: 'Service',
                    targetId: service.id,
                    userId: service.providerId,
                    userName: service.providerName,
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
            // Provider header
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), AppColors.indigo600],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      service.providerName
                          .split(' ')
                          .map((w) => w.isEmpty ? '' : w[0])
                          .take(2)
                          .join()
                          .toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.providerName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 15, color: const Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text(
                            service.location,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            // Skills
            _SectionLabel('SKILLS'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: service.skills.map((s) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    s,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (service.otherSkill != null &&
                service.otherSkill!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                service.otherSkill!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Availability
            _SectionLabel('AVAILABILITY'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: service.availableDays.map((d) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.indigo600.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    d,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.indigo600,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 16, color: AppColors.indigo600),
                const SizedBox(width: 6),
                Text(
                  '${service.startTime.format(context)} – ${service.endTime.format(context)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Bio
            _SectionLabel('ABOUT'),
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
                service.bio,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                  color: isDark ? Colors.white : AppColors.slate900,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Message button
            if (!isOwn)
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: isDark ? Colors.white : AppColors.slate900,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.15),
                  child: InkWell(
                    onTap: () {
                      final conv = state.getOrCreateConversation(
                        otherUserId: service.providerId,
                        otherUserName: service.providerName,
                        contextLabel:
                            'Service: ${service.skills.join(", ")}',
                      );
                      Navigator.of(context).push(
                        SmoothPageRoute(
                          builder: (_) =>
                              ChatScreen(conversationId: conv.id),
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
                            Icons.chat_rounded,
                            size: 20,
                            color:
                                isDark ? AppColors.slate900 : Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Message ${service.providerName.split(" ").first}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark
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
            const SizedBox(height: 48),
          ],
        ),
        ),
      ),
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
