import 'dart:convert';
import 'package:http/http.dart' as http;

class ContactEmailResult {
  final bool success;
  final String? error;

  const ContactEmailResult({required this.success, this.error});
}

class ContactEmailService {
  // Reuse existing EmailJS project credentials.
  // Make sure this template exists in EmailJS and sends to {{to_email}}.
  static const _serviceId = 'service_0j4msbg';
  static const _templateId = 'template_gqmm0yf';
  static const _publicKey = 'EhaaEdfCURZPpJHTR';
  static const supportEmail = 'info@teenworkly.com';

  static Future<ContactEmailResult> sendContactMessage({
    required String fromName,
    required String fromEmail,
    required String subject,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            // Expected by existing template
            'to_name': 'TeenWorkly Support',
            'to_email': supportEmail,
            'code': 'Contact form message\n'
                'From: $fromName <$fromEmail>\n'
                'Subject: $subject\n\n'
                '$message',
            // Extra fields for future/dedicated template
            'from_name': fromName,
            'from_email': fromEmail,
            'subject': subject,
            'message': message,
          },
        }),
      );

      if (response.statusCode == 200) {
        return const ContactEmailResult(success: true);
      }
      return ContactEmailResult(
        success: false,
        error: 'Email service error ${response.statusCode}.',
      );
    } catch (e) {
      return ContactEmailResult(
        success: false,
        error: 'Network/email error: $e',
      );
    }
  }
}
