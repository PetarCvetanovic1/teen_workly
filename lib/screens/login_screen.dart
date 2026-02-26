import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../state/app_state.dart';
import '../widgets/content_wrap.dart';
import '../services/moderation.dart';
import '../services/email_verification.dart';
import 'jobs_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ContentWrap(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.indigo600, Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.lock_open_rounded,
                    color: Colors.white, size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome Back',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Log in to your TeenWorkly account',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 36),
            Container(
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
                    _label('EMAIL'),
                    const SizedBox(height: 8),
                    _field(
                      controller: _emailCtrl,
                      hint: 'you@example.com',
                      isDark: isDark,
                      keyboardType: TextInputType.emailAddress,
                      icon: Icons.email_outlined,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 20),
                    _label('PASSWORD'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Your password',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            size: 20, color: Color(0xFF94A3B8)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20,
                            color: const Color(0xFF94A3B8),
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : AppColors.slate100,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : AppColors.slate100,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.indigo600.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _sendPasswordResetEmail,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.indigo600,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                        ),
                        child: Text(
                          'Forgot password?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Material(
                      color: isDark ? Colors.white : AppColors.slate900,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.15),
                      child: InkWell(
                        onTap: _submit,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Text(
                            'Log In',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.slate900
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: isDark
                          ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: _signInWithGoogle,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.g_mobiledata_rounded,
                                  size: 24, color: Color(0xFFEA4335)),
                              const SizedBox(width: 8),
                              Text(
                                'Continue with Google',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.slate900,
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
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Don\'t have an account? ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      SmoothPageRoute(builder: (_) => const SignUpScreen()),
                    );
                  },
                  child: Text(
                    'Join now',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.indigo600,
                    ),
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

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          color: const Color(0xFF94A3B8),
        ),
      );

  static String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final regex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    TextInputType? keyboardType,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
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
      validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailCtrl.text.trim().toLowerCase();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passCtrl.text,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-login-credentials':
          msg = 'Email or password is incorrect.';
          break;
        case 'network-request-failed':
          msg = 'Network error. Check internet and try again.';
          break;
        case 'too-many-requests':
          msg = 'Too many attempts. Please wait and try again.';
          break;
        default:
          msg = 'Login failed (${e.code}).';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      SmoothPageRoute(builder: (_) => const JobsScreen()),
      (_) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Welcome back!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    final emailError = _validateEmail(email);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email above first to reset password.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Send Firebase email-link sign-in (no paid backend needed).
      try {
        await FirebaseAuth.instance.sendSignInLinkToEmail(
          email: email,
          actionCodeSettings: ActionCodeSettings(
            url: 'https://teenworkly.firebaseapp.com',
            handleCodeInApp: true,
            androidPackageName: 'com.teenworkly.app',
            androidInstallApp: true,
            iOSBundleId: 'com.example.teenWorkly',
          ),
        );
      } on FirebaseAuthException catch (e) {
        // Fallback without action settings if configured domains reject it.
        if (e.code == 'invalid-continue-uri' ||
            e.code == 'unauthorized-continue-uri' ||
            e.code == 'missing-continue-uri') {
          await FirebaseAuth.instance.sendSignInLinkToEmail(
            email: email,
            actionCodeSettings: ActionCodeSettings(
              url: 'https://teenworkly.firebaseapp.com',
              handleCodeInApp: true,
              androidPackageName: 'com.teenworkly.app',
              androidInstallApp: true,
              iOSBundleId: 'com.example.teenWorkly',
            ),
          );
        } else {
          rethrow;
        }
      }

      // Always send backup EmailJS mail too (this path is known working).
      final backupCode = EmailVerificationService.generateCode();
      await EmailVerificationService.sendVerificationEmail(
        toEmail: email,
        toName: 'TeenWorkly User',
        code: backupCode,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email sent. Check inbox and spam.'),
        ),
      );
      Navigator.of(context).push(
        SmoothPageRoute(
          builder: (_) => ResetPasswordScreen(
            initialEmail: email,
            codeJustSent: true,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg;
      switch (e.code) {
        case 'invalid-email':
          msg = 'That email format is invalid.';
          break;
        case 'missing-email':
          msg = 'Enter your email first.';
          break;
        case 'user-not-found':
          msg = 'No account found with that email.';
          break;
        case 'operation-not-allowed':
          msg =
              'Password reset is not enabled. Enable Email/Password in Firebase Auth.';
          break;
        case 'too-many-requests':
          msg = 'Too many attempts. Please wait and try again.';
          break;
        case 'network-request-failed':
          msg = 'Network error. Check internet and try again.';
          break;
        default:
          msg = 'Reset failed (${e.code}): ${e.message ?? 'Unknown auth error'}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send reset email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    final error = await context.read<AppState>().loginWithGoogle();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (error != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('Signed in with Google!')),
    );
    Navigator.of(context).pushAndRemoveUntil(
      SmoothPageRoute(builder: (_) => const JobsScreen()),
      (_) => false,
    );
  }
}

// ---- Sign Up Screen ----

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ContentWrap(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.person_add_rounded,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              'Join TeenWorkly',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create your account and start earning',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 36),
            Container(
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
                    _label('FULL NAME'),
                    const SizedBox(height: 8),
                    _field(
                      controller: _nameCtrl,
                      hint: 'e.g. Alex Johnson',
                      isDark: isDark,
                      icon: Icons.person_outline_rounded,
                      validator: _validateName,
                    ),
                    const SizedBox(height: 20),
                    _label('EMAIL'),
                    const SizedBox(height: 8),
                    _field(
                      controller: _emailCtrl,
                      hint: 'you@example.com',
                      isDark: isDark,
                      keyboardType: TextInputType.emailAddress,
                      icon: Icons.email_outlined,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 20),
                    _label('PASSWORD'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Min 8 chars, letter + number',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            size: 20, color: Color(0xFF94A3B8)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20,
                            color: const Color(0xFF94A3B8),
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : AppColors.slate100,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : AppColors.slate100,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.indigo600.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 20),
                    _label('YOUR AGE'),
                    const SizedBox(height: 8),
                    _field(
                      controller: _ageCtrl,
                      hint: 'e.g. 15',
                      isDark: isDark,
                      keyboardType: TextInputType.number,
                      icon: Icons.cake_outlined,
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final age = int.tryParse(v.trim());
                        if (age == null) return 'Enter a number';
                        if (age < 10) return 'You must be at least 10';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    Material(
                      color: isDark ? Colors.white : AppColors.slate900,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.15),
                      child: InkWell(
                        onTap: _sendingCode ? null : _submit,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: _sendingCode
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: isDark
                                            ? AppColors.slate900
                                            : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Sending verification code...',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? AppColors.slate900
                                            : Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Create Account',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.slate900
                                        : Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: isDark
                          ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: _signUpWithGoogle,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.g_mobiledata_rounded,
                                  size: 24, color: Color(0xFFEA4335)),
                              const SizedBox(width: 8),
                              Text(
                                'Continue with Google',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.slate900,
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
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      SmoothPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Text(
                    'Log in',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.indigo600,
                    ),
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

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          color: const Color(0xFF94A3B8),
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    TextInputType? keyboardType,
    IconData? icon,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
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
      validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Required' : null,
      onChanged: onChanged,
    );
  }

  static String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final parts = v.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return 'Enter your first and last name';
    if (parts.any((p) => p.length < 2)) return 'Each name must be at least 2 letters';
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(v.trim())) {
      return 'Name can only contain letters';
    }
    if (ModerationService.containsProfanity(v.trim())) {
      return 'That name contains inappropriate language';
    }
    for (final part in parts) {
      if (!ModerationService.isPlausibleName(part)) {
        return '"$part" doesn\'t look like a real name';
      }
    }
    return null;
  }

  static String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final email = v.trim();
    final regex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(email)) return 'Enter a valid email address';
    if (ModerationService.containsProfanity(email.split('@').first)) {
      return 'Your email contains inappropriate language';
    }
    if (!ModerationService.isPlausibleEmailLocal(email)) {
      return 'That doesn\'t look like a real email — use your actual one';
    }
    return null;
  }

  static const _weakPasswords = {
    '123456', '1234567', '12345678', '123456789', 'password', 'password1',
    'qwerty', 'qwerty123', 'abc123', 'letmein', 'welcome', 'monkey',
    'dragon', 'master', 'login', 'princess', 'football', 'shadow',
    'sunshine', 'trustno1', 'iloveyou', 'batman', 'access', 'hello',
    'charlie', 'donald', '111111', '11111111', '000000', 'aaaaaa',
    'abcdef', 'abcdefg', 'abcdefgh', 'asdfgh', 'zxcvbn', 'qazwsx',
  };

  static String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (v.length < 8) return 'Must be at least 8 characters';
    if (_weakPasswords.contains(v.toLowerCase())) {
      return 'That password is too common — pick something stronger';
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(v)) return 'Must include at least one letter';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Must include at least one number';
    if (RegExp(r'^(.)\1+$').hasMatch(v)) return 'Password can\'t be all the same character';
    return null;
  }

  bool _sendingCode = false;

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailCtrl.text.trim().toLowerCase();

    setState(() => _sendingCode = true);

    final code = EmailVerificationService.generateCode();
    final emailResult = await EmailVerificationService.sendVerificationEmail(
      toEmail: email,
      toName: _nameCtrl.text.trim(),
      code: code,
    );

    if (!mounted) return;
    setState(() => _sendingCode = false);

    if (!emailResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            emailResult.error ??
                'Could not send verification email. Check your email and try again.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFDC2626),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (!mounted) return;
    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _VerificationDialog(
        email: email,
        expectedCode: code,
        isDark: Theme.of(ctx).brightness == Brightness.dark,
      ),
    );

    if (verified != true || !mounted) return;

    final error = await context.read<AppState>().signUp(
          name: _nameCtrl.text.trim(),
          email: email,
          password: _passCtrl.text,
          age: int.tryParse(_ageCtrl.text.trim()),
        );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    // Safety: ensure the auth session is actually active before routing away.
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account was created but sign-in session is missing. Please log in.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      SmoothPageRoute(builder: (_) => const JobsScreen()),
      (_) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Email verified! Welcome to TeenWorkly!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _signUpWithGoogle() async {
    final error = await context.read<AppState>().loginWithGoogle();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (error != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('Signed in with Google!')),
    );
    Navigator.of(context).pushAndRemoveUntil(
      SmoothPageRoute(builder: (_) => const JobsScreen()),
      (_) => false,
    );
  }

}

class _VerificationDialog extends StatefulWidget {
  final String email;
  final String expectedCode;
  final bool isDark;

  const _VerificationDialog({
    required this.email,
    required this.expectedCode,
    required this.isDark,
  });

  @override
  State<_VerificationDialog> createState() => _VerificationDialogState();
}

class _VerificationDialogState extends State<_VerificationDialog> {
  final _codeCtrl = TextEditingController();
  String? _error;
  int _attempts = 0;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _verify() {
    final entered = _codeCtrl.text.trim();
    if (entered.isEmpty) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    if (entered == widget.expectedCode) {
      Navigator.of(context).pop(true);
    } else {
      _attempts++;
      if (_attempts >= 5) {
        Navigator.of(context).pop(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Too many attempts. Please try again.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFDC2626),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        setState(() => _error = 'Wrong code. ${5 - _attempts} attempts left.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor:
          widget.isDark ? const Color(0xFF1E293B) : Colors.white,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.indigo600, Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child:
                const Icon(Icons.email_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 18),
          Text(
            'Verify Your Email',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: widget.isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a 6-digit code to',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.email,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.indigo600,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 8,
              color: widget.isDark ? Colors.white : AppColors.slate900,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '------',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 8,
                color: const Color(0xFF94A3B8).withValues(alpha: 0.3),
              ),
              filled: true,
              fillColor: widget.isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                  : AppColors.slate100.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              errorText: _error,
              errorStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFDC2626),
              ),
            ),
            onSubmitted: (_) => _verify(),
            onEditingComplete: _verify,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: widget.isDark ? Colors.white : AppColors.slate900,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _verify,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Verify',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: widget.isDark ? AppColors.slate900 : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
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
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  final bool codeJustSent;

  const ResetPasswordScreen({
    super.key,
    this.initialEmail,
    this.codeJustSent = false,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _sending = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = (widget.initialEmail ?? '').trim().toLowerCase();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final regex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  Future<void> _sendVerification() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    final emailErr = _validateEmail(email);
    if (emailErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(emailErr), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://teenworkly.firebaseapp.com',
          handleCodeInApp: true,
          androidPackageName: 'com.teenworkly.app',
          androidInstallApp: true,
          iOSBundleId: 'com.example.teenWorkly',
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sign-in link sent. Check inbox/spam and paste the full link below.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send sign-in link (${e.code}).'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send verification code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailCtrl.text.trim().toLowerCase();
    final link = _codeCtrl.text.trim();
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste the sign-in link first.'), backgroundColor: Colors.red),
      );
      return;
    }
    if (!link.contains('http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paste the full link from your email.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final error = await context.read<AppState>().loginWithEmailLink(
            email: email,
            emailLink: link,
          );
      if (error != null) {
        throw Exception(error);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code accepted. You are logged in.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        SmoothPageRoute(builder: (_) => const JobsScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Reset Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ContentWrap(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A).withValues(alpha: 0.7)
                        : AppColors.slate100.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : AppColors.slate200,
                    ),
                  ),
                  child: Text(
                    'After you receive the email link:\n'
                    '1) tap Send Verification Email,\n'
                    '2) copy the full link from the email,\n'
                    '3) paste it below to log in.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  validator: _validateEmail,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@example.com',
                  ),
                ),
                const SizedBox(height: 12),
                if (!widget.codeJustSent) ...[
                  ElevatedButton(
                    onPressed: _sending ? null : _sendVerification,
                    child: _sending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send Verification Email'),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Link sent. Paste the full sign-in link from your email below.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _codeCtrl,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                  decoration: const InputDecoration(
                    labelText: 'Verification Link',
                    hintText: 'Paste full sign-in link',
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _submitting ? null : _resetPassword,
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : AppColors.slate900,
                    foregroundColor: isDark ? AppColors.slate900 : Colors.white,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign In With Link'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
