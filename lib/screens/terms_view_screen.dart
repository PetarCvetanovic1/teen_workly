import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';

const _termsText = '''TEENWORKLY TERMS OF SERVICE & LIABILITY WAIVER
Last Updated: March 1, 2026

1. NATURE OF SERVICE
TeenWorkly is a NETWORKING PLATFORM ONLY. We provide a digital space to connect "Providers" (Teens) with "Seekers" (Adults/Homeowners).
- WE ARE NOT AN EMPLOYER.
- WE DO NOT SUPERVISE, DIRECT, OR CONTROL THE WORK PERFORMED.
- WE DO NOT VET THE SAFETY OF PRIVATE RESIDENCES.

2. ASSUMPTION OF RISK (IMPORTANT - READ CAREFULLY)
By using TeenWorkly, you acknowledge that manual labor (mowing lawns, moving boxes, cleaning, etc.) carries INHERENT RISKS OF PHYSICAL INJURY.
- YOU VOLUNTARILY AGREE TO ASSUME ALL RISKS associated with any connection made through this app.
- TEENWORKLY IS NOT RESPONSIBLE for any accidents, injuries, medical emergencies, or health issues that occur during a job.

3. RELEASE OF LIABILITY
To the maximum extent permitted by Ontario law, you hereby RELEASE, WAIVE, AND FOREVER DISCHARGE TeenWorkly (and its founders/operators) from any and all claims, demands, or causes of action related to:
1) PHYSICAL INJURY OR DEATH occurring at a job site.
2) THEFT OR PROPERTY DAMAGE caused by any user.
3) DISPUTES OVER PAYMENT (All payments are between the Adult and the Teen).
4) EMOTIONAL DISTRESS or negative interactions in "The Huddle."

4. SAFETY GUIDELINES
- TEENS: Always tell a parent/guardian where you are going. Never enter a home alone if you feel unsafe.
- ADULTS: You are responsible for providing a safe environment. You must comply with all local safety laws.

5. "THE HUDDLE" & AI MODERATION
We use AI MODERATION to monitor "The Huddle." While we strive to remove harmful content, TeenWorkly is not liable for any content posted by third parties that bypasses our filters.

6. NO WARRANTIES
TeenWorkly is provided "AS IS" and "AS AVAILABLE." We make no warranties about uptime, outcomes, user conduct, payment completion, or suitability of any job/service.

7. INDEMNITY
You agree to indemnify and hold harmless TeenWorkly and its operators from claims, damages, losses, and legal fees arising from your use of the platform, your postings, or your conduct.

8. GOVERNING LAW
These terms are governed by the laws of Ontario, Canada. You agree to resolve disputes in Ontario, unless applicable law requires otherwise.

9. USER-SHARED INFORMATION & JOB HISTORY
Users may choose to share personal details, work history, ratings, completed-job history, and other profile/job information through posts, chats, and profiles. You are responsible for what you share.
- DO NOT post sensitive private information (exact home addresses, health data, government IDs, passwords, etc.).
- TeenWorkly is not responsible for losses, harm, or disputes caused by information a user voluntarily discloses to others.

BY USING TEENWORKLY, YOU ACKNOWLEDGE THAT YOU HAVE READ THIS AGREEMENT, UNDERSTAND THAT YOU ARE GIVING UP LEGAL RIGHTS, AND AGREE TO BE BOUND BY THESE TERMS.''';

class TermsViewScreen extends StatelessWidget {
  const TermsViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : AppColors.slate200,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Text(
              _termsText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.5,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
