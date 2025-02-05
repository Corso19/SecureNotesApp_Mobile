import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, provider, _) => ListView(
          children: [
            ListTile(
              title: const Text('Theme'),
              subtitle: Text(provider.themeMode.toString().split('.').last),
              onTap: () => _showThemeDialog(context, provider),
            ),
            ListTile(
              title: const Text('Font Size'),
              subtitle: Text('${provider.fontSize.round()}'),
              trailing: SizedBox(
                width: 200,
                child: Slider(
                  value: provider.fontSize,
                  min: 12,
                  max: 24,
                  divisions: 12,
                  label: provider.fontSize.round().toString(),
                  onChanged: provider.updateFontSize,
                ),
              ),
            ),
            SwitchListTile(
              title: const Text('Notifications'),
              value: provider.notificationsEnabled,
              onChanged: provider.updateNotifications,
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('System'),
              onTap: () {
                provider.updateThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Light'),
              onTap: () {
                provider.updateThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Dark'),
              onTap: () {
                provider.updateThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}