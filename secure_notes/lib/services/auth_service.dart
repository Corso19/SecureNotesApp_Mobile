import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../db/local_db.dart';
import '../services/security_service.dart';

class AuthService {
  static final supabase = Supabase.instance.client;
  static final _secureStorage = const FlutterSecureStorage();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static Future<void> storeCredentials(String email, String password) async {
    await _secureStorage.write(key: 'user_email', value: email);
    await _secureStorage.write(key: 'user_password', value: password);
  }

  static Future<Map<String, String>?> getStoredCredentials() async {
    final email = await _secureStorage.read(key: 'user_email');
    final password = await _secureStorage.read(key: 'user_password');
    
    if (email != null && password != null) {
      return {
        'email': email,
        'password': password
      };
    }
    return null;
  }

  static Future<void> clearCredentials() async {
    await _secureStorage.delete(key: 'user_email');
    await _secureStorage.delete(key: 'user_password');
    _isInitialized = false;
  }

  static Future<AuthResponse> signInWithPassword(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password
      );
      
      if (response.user != null) {
        await storeCredentials(email, password);
        await initializeDB(email, password);
      }
      
      return response;
    } catch (e) {
      // Try offline login
      return await tryOfflineLogin(email, password);
    }
  }

  static Future<AuthResponse> tryOfflineLogin(String email, String password) async {
  final storedCreds = await getStoredCredentials();
    
  if (storedCreds != null && 
      storedCreds['email'] == email && 
      storedCreds['password'] == password) {
    await initializeDB(email, password);
    return AuthResponse(
      session: null, 
      user: User(
        id: 'offline',
        email: email,
        role: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated'
      )
    );
  }
  throw 'Invalid credentials or no stored login found';
}

  static Future<void> initializeDB(String email, String password) async {
    final key = await SecurityService.generateEncryptionKey(email, password);
    await LocalDB.initializeWithKey(key);
    _isInitialized = true;
  }

  static Future<void> signOut() async {
    await clearCredentials();
    _isInitialized = false;
    await LocalDB.closeDatabase();
    await supabase.auth.signOut();
  }
}