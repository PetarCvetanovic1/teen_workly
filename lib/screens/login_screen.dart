import 'package:flutter/material.dart';
import '../utils/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../state/app_state.dart';
import '../widgets/content_wrap.dart';
import '../services/moderation.dart';

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

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AppState>().login(_emailCtrl.text.trim(), _passCtrl.text);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Welcome back!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
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
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
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

  static bool _nameEmailMatch(String name, String email) {
    final local = email.split('@').first.toLowerCase().replaceAll(
        RegExp(r'[^a-z]'), '');
    final nameParts = name
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((p) => p.length >= 2)
        .toList();

    if (local.isEmpty || nameParts.isEmpty) return false;

    for (final part in nameParts) {
      if (local.contains(part)) return true;
      if (part.length >= 3 && local.contains(part.substring(0, 3))) return true;
    }

    final initials = nameParts.map((p) => p[0]).join();
    if (initials.length >= 2 && local.contains(initials)) return true;

    final firstInitialLastName =
        '${nameParts.first[0]}${nameParts.last}';
    if (local.contains(firstInitialLastName)) return true;

    final lastInitialFirstName =
        '${nameParts.first}${nameParts.last[0]}';
    if (local.contains(lastInitialFirstName)) return true;

    return false;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (!_nameEmailMatch(name, email)) {
      showDialog(
        context: context,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            backgroundColor:
                isDark ? const Color(0xFF1E293B) : Colors.white,
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFEA580C), size: 24),
                const SizedBox(width: 8),
                Text(
                  'Email Doesn\'t Match',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
              ],
            ),
            content: Text(
              'Your email doesn\'t seem to match your name. '
              'Please use an email that\'s connected to you '
              '(e.g. your name or initials in the email).\n\n'
              'This helps keep TeenWorkly safe for everyone.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
                color: const Color(0xFF94A3B8),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Fix it',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: AppColors.indigo600,
                  ),
                ),
              ),
            ],
          );
        },
      );
      return;
    }

    context.read<AppState>().signUp(
          name: name,
          email: email,
          password: _passCtrl.text,
        );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Welcome to TeenWorkly! Set up your profile.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
