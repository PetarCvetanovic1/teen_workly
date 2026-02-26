import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class EmailSendResult {
  final bool success;
  final String? error;

  const EmailSendResult({required this.success, this.error});
}

class EmailVerificationService {
  // ── EmailJS credentials ──
  // Sign up free at https://www.emailjs.com
  // 1. Create a service (connect your Gmail)
  // 2. Create a template with variables: {{to_name}}, {{to_email}}, {{code}}
  // 3. Paste your IDs below
  static const _serviceId = 'service_0j4msbg';
  static const _templateId = 'template_gqmm0yf';
  static const _publicKey = 'EhaaEdfCURZPpJHTR';

  static bool get isConfigured =>
      _serviceId != 'YOUR_SERVICE_ID' &&
      _templateId != 'YOUR_TEMPLATE_ID' &&
      _publicKey != 'YOUR_PUBLIC_KEY';

  static String generateCode() {
    final rng = Random.secure();
    return List.generate(6, (_) => rng.nextInt(10)).join();
  }

  static Future<EmailSendResult> sendVerificationEmail({
    required String toEmail,
    required String toName,
    required String code,
  }) async {
    if (!isConfigured) {
      // Fallback: skip sending, just show the code in debug
      assert(() {
        // ignore: avoid_print
        print('[EmailVerification] Code for $toEmail: $code');
        return true;
      }());
      return const EmailSendResult(success: true);
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'to_name': toName,
            'to_email': toEmail,
            'code': code,
          },
        }),
      );
      if (response.statusCode == 200) {
        return const EmailSendResult(success: true);
      }
      return EmailSendResult(
        success: false,
        error:
            'Email service error ${response.statusCode}. Check EmailJS service/template/public key.',
      );
    } catch (e) {
      return EmailSendResult(
        success: false,
        error: 'Network/email error: $e',
      );
    }
  }
}
