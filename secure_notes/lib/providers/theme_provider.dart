import 'package:flutter/material.dart';
import '../db/local_db.dart';
import '../services/sync_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  double _fontSize = 16;
  bool _notificationsEnabled = true;

  ThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> updateThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners(); // Notify immediately
    await _updatePreferences(); // Save after UI update
  }

  Future<void> updateFontSize(double size) async {
    _fontSize = size;
    notifyListeners();
    await _updatePreferences();
  }

  Future<void> updateNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners(); // Notify immediately
    await _updatePreferences();
  }

  Future<void> _updatePreferences() async {
    try {
      await LocalDB.updatePreferences({
        'theme_mode': _themeMode.toString().split('.').last,
        'font_size': _fontSize.round(),
        'notifications_enabled': _notificationsEnabled ? 1 : 0,
      });
      await SyncService.syncPreferences();
    } catch (e) {
      print('Error updating preferences: $e');
    }
  }

  Future<void> loadPreferences() async {
    try {
      final prefs = await LocalDB.getPreferences();
      _themeMode = _getThemeMode(prefs['theme_mode']);
      _fontSize = prefs['font_size'].toDouble();
      _notificationsEnabled = prefs['notifications_enabled'] == 1;
      notifyListeners();
    } catch (e) {
      print('Error loading preferences: $e');
    }
  }

  void resetToDefaults() {
    _themeMode = ThemeMode.system;
    _fontSize = 16;
    _notificationsEnabled = true;
    notifyListeners();
  }

  ThemeMode _getThemeMode(String? mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
