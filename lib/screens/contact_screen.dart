import 'package:flutter/material.dart';
import '../utils/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tw_app_bar.dart';
import '../widgets/content_wrap.dart';
import 'home_screen.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ContentWrap(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.indigo600, Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.mail_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(height: 24),
              Text(
                'We\'d Love to Hear\nFrom You',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.2,
                  color: isDark ? Colors.white : AppColors.slate900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Got a question, suggestion, or just want to say hi?\nDrop us a message and we\'ll get back to you.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 36),
              if (_sent)
                _buildSuccessCard(isDark)
              else
                _buildForm(isDark),
              const SizedBox(height: 36),
              // Contact info cards
              Row(
                children: [
                  Expanded(
                    child: _ContactInfoCard(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      value: 'hello@teenworkly.com',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ContactInfoCard(
                      icon: Icons.schedule_rounded,
                      title: 'Response Time',
                      value: 'Within 24 hours',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF059669).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            'Message Sent!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thanks for reaching out. We\'ll get back to you as soon as possible.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => setState(() {
              _sent = false;
              _nameCtrl.clear();
              _emailCtrl.clear();
              _subjectCtrl.clear();
              _messageCtrl.clear();
            }),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF059669)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Send Another Message',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF059669),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B)
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155)
              : Colors.white.withValues(alpha: 0.5),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label('YOUR NAME'),
            const SizedBox(height: 8),
            _field(_nameCtrl, 'e.g. Alex Johnson', isDark,
                icon: Icons.person_outline_rounded),
            const SizedBox(height: 20),
            _label('EMAIL'),
            const SizedBox(height: 8),
            _field(_emailCtrl, 'you@example.com', isDark,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),
            _label('SUBJECT'),
            const SizedBox(height: 8),
            _field(_subjectCtrl, 'What\'s this about?', isDark,
                icon: Icons.subject_rounded),
            const SizedBox(height: 20),
            _label('YOUR MESSAGE'),
            const SizedBox(height: 8),
            _field(_messageCtrl, 'Tell us what\'s on your mind...', isDark,
                maxLines: 5),
            const SizedBox(height: 28),
            Material(
              color: isDark ? Colors.white : AppColors.slate900,
              borderRadius: BorderRadius.circular(16),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.15),
              child: InkWell(
                onTap: _submitForm,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded,
                          size: 18,
                          color:
                              isDark ? AppColors.slate900 : Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        'Send Message',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? AppColors.slate900 : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          color: const Color(0xFF94A3B8),
        ),
      );

  Widget _field(
    TextEditingController ctrl,
    String hint,
    bool isDark, {
    int maxLines = 1,
    TextInputType? keyboardType,
    IconData? icon,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : AppColors.slate900,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w500,
          color: const Color(0xFF94A3B8),
        ),
        prefixIcon: icon != null
            ? Icon(icon, size: 20, color: const Color(0xFF94A3B8))
            : null,
        filled: true,
        fillColor: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : AppColors.slate100,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : AppColors.slate100,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.indigo600.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _sent = true);
    }
  }
}

class _ContactInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isDark;

  const _ContactInfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.indigo600),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
        ],
      ),
    );
  }
}
