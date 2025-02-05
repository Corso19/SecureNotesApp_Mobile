import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:convert' show HtmlEscape;

class SecurityService {
  static const int MAX_TITLE_LENGTH = 100;
  static const int MAX_CONTENT_LENGTH = 10000;
  static const int MIN_PASSWORD_LENGTH = 8;

  static String sanitizeInput(String input) {
    // Trim whitespace
    String sanitized = input.trim();
    
    // HTML escape to prevent XSS
    sanitized = HtmlEscape().convert(sanitized);
    
    // Remove SQL injection patterns
    sanitized = sanitized.replaceAll(RegExp(r'(\b(union|select|from|where|insert|delete|drop)\b)', caseSensitive: false), '');
    
    // Remove special characters but keep basic punctuation
    sanitized = sanitized.replaceAll(RegExp(r'[^\w\s@.,!?-]'), '');
    
    // Normalize whitespace
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    
    return sanitized;
  }

  static String? validateNoteTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a title';
    }
    if (value.length > MAX_TITLE_LENGTH) {
      return 'Title must be less than $MAX_TITLE_LENGTH characters';
    }
    final sanitized = sanitizeInput(value);
    if (sanitized.isEmpty) {
      return 'Title contains invalid characters';
    }
    return null;
  }

  static String? validateNoteContent(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter content';
    }
    if (value.length > MAX_CONTENT_LENGTH) {
      return 'Content must be less than $MAX_CONTENT_LENGTH characters';
    }
    final sanitized = sanitizeInput(value);
    if (sanitized.isEmpty) {
      return 'Content contains invalid characters';
    }
    return null;
  }

  static bool isEmailValid(String email) {
    return RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(email);
  }

  static bool isPasswordValid(String password) {
    return password.length >= MIN_PASSWORD_LENGTH &&
           RegExp(r'[A-Z]').hasMatch(password) &&
           RegExp(r'[a-z]').hasMatch(password) &&
           RegExp(r'[0-9]').hasMatch(password) &&
           RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  static Future<String> generateEncryptionKey(String email, String password) async {
    final bytes = utf8.encode('$email:$password');
    return sha256.convert(bytes).toString();
  }
}