import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../state/app_state.dart';
import '../utils/smooth_route.dart';
import 'jobs_screen.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _agreed = false;
  bool _riskAck = false;
  bool _liabilityAck = false;
  bool _guardianAck = false;
  bool _submitting = false;
  static const int _cooldownSeconds = 5;
  int _remainingSeconds = _cooldownSeconds;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
      } else {
        setState(() => _remainingSeconds -= 1);
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  bool _canSubmit(AppState state) {
    final guardianRequired = (state.profile?.age ?? 17) < 18;
    return _remainingSeconds == 0 &&
        _agreed &&
        _riskAck &&
        _liabilityAck &&
        (!guardianRequired || _guardianAck);
  }

  Future<void> _acceptAndContinue() async {
    final state = context.read<AppState>();
    if (!_canSubmit(state) || _submitting) return;
    setState(() => _submitting = true);
    try {
      await state.acceptTerms(
        version: AppState.currentTermsVersion,
        guardianConsent: _guardianAck,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        SmoothPageRoute(builder: (_) => const JobsScreen()),
        (_) => false,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<AppState>();
    final guardianRequired = (state.profile?.age ?? 17) < 18;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : AppColors.slate200,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Text(
                        '''TEENWORKLY TERMS OF SERVICE & LIABILITY WAIVER
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

BY CHECKING THE BOXES BELOW, YOU ACKNOWLEDGE THAT YOU HAVE READ THIS ENTIRE AGREEMENT, UNDERSTAND THAT YOU ARE GIVING UP LEGAL RIGHTS, AND AGREE TO BE BOUND BY THESE TERMS.''',
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
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _agreed,
                  onChanged: (v) => setState(() => _agreed = v ?? false),
                  title: Text(
                    'I have read and agree to the Terms of Service.',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: _riskAck,
                  onChanged: (v) => setState(() => _riskAck = v ?? false),
                  title: Text(
                    'I understand jobs may involve physical risk and I voluntarily assume those risks.',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: _liabilityAck,
                  onChanged: (v) => setState(() => _liabilityAck = v ?? false),
                  title: Text(
                    'I agree to the liability waiver and release described above.',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                if (guardianRequired)
                  CheckboxListTile(
                    value: _guardianAck,
                    onChanged: (v) => setState(() => _guardianAck = v ?? false),
                    title: Text(
                      'I confirm my parent/guardian reviewed and approved my use of TeenWorkly.',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                const SizedBox(height: 8),
                if (_remainingSeconds > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Text(
                      'Please read the terms and conditions before continuing '
                      '($_remainingSeconds s)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                if (_remainingSeconds > 0) const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (_canSubmit(state) && !_submitting)
                        ? _acceptAndContinue
                        : null,
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Agree and Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
