import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecurityService {
  static String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[^\w\s@.-]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool isEmailValid(String email) {
    return RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(email);
  }

  static bool isPasswordValid(String password) {
    return password.length >= 8;
  }

  static Future<String> generateEncryptionKey(String email, String password) async {
    final bytes = utf8.encode('$email:$password');
    return sha256.convert(bytes).toString();
  }
}