import 'package:cloud_functions/cloud_functions.dart';

class PasswordResetService {
  static final _functions = FirebaseFunctions.instance;

  static Future<void> issueResetCode({
    required String email,
    required String code,
  }) async {
    final callable = _functions.httpsCallable('issuePasswordResetCode');
    await callable.call(<String, dynamic>{
      'email': email.trim().toLowerCase(),
      'code': code.trim(),
    });
  }

  static Future<void> resetWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final callable = _functions.httpsCallable('resetPasswordWithCode');
    await callable.call(<String, dynamic>{
      'email': email.trim().toLowerCase(),
      'code': code.trim(),
      'newPassword': newPassword,
    });
  }

  static Future<void> verifyCode({
    required String email,
    required String code,
  }) async {
    final callable = _functions.httpsCallable('verifyPasswordResetCodeOnly');
    await callable.call(<String, dynamic>{
      'email': email.trim().toLowerCase(),
      'code': code.trim(),
    });
  }

  static Future<String> signInWithCode({
    required String email,
    required String code,
  }) async {
    final callable = _functions.httpsCallable('signInWithCode');
    final result = await callable.call(<String, dynamic>{
      'email': email.trim().toLowerCase(),
      'code': code.trim(),
    });
    final data = result.data;
    if (data is! Map || data['customToken'] == null) {
      throw FirebaseFunctionsException(
        code: 'internal',
        message: 'Missing custom token in backend response.',
      );
    }
    return data['customToken'].toString();
  }
}
