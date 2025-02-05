import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tviowejujhpugfdmeqwu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR2aW93ZWp1amhwdWdmZG1lcXd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg1MTIzMTMsImV4cCI6MjA1NDA4ODMxM30.ub5X9hJgLXgMY68xvoDHms22xUIyJkOKrHTz-flxaqo'
  );

  final dbPath = await getApplicationDocumentsDirectory();
  print("📂 Database Path: ${dbPath.path}/secure_notes.db");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkAuthStatus();
    setupAuthListener();
  }

  void setupAuthListener() {
    supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        // First sync preferences from remote
        await SyncService.syncPreferences();
        // Then load them to provider
        if (mounted) {
          await Provider.of<ThemeProvider>(context, listen: false).loadPreferences();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        if (mounted) {
          Provider.of<ThemeProvider>(context, listen: false).resetToDefaults();
        }
      }
    });
  }

  Future<void> checkAuthStatus() async {
    final session = supabase.auth.currentSession;
    setState(() {
      isLoggedIn = session != null;
      isLoading = false;
    });

    // If logged in, sync preferences
    if (isLoggedIn) {
      await SyncService.syncPreferences();
      if (mounted) {
        await Provider.of<ThemeProvider>(context, listen: false).loadPreferences();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => MaterialApp(
        navigatorKey: AuthService.navigatorKey,
        title: 'Secure Notes',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(useMaterial3: true).copyWith(
          textTheme: TextTheme(
            bodyLarge: TextStyle(fontSize: themeProvider.fontSize),
            bodyMedium: TextStyle(fontSize: themeProvider.fontSize),
            bodySmall: TextStyle(fontSize: themeProvider.fontSize - 2),
          ),
        ),
        darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
          textTheme: TextTheme(
            bodyLarge: TextStyle(fontSize: themeProvider.fontSize),
            bodyMedium: TextStyle(fontSize: themeProvider.fontSize),
            bodySmall: TextStyle(fontSize: themeProvider.fontSize - 2),
          ),
        ),
        themeMode: themeProvider.themeMode,
        home: isLoading
            ? const Center(child: CircularProgressIndicator())
            : isLoggedIn
                ? const HomeScreen()
                : const LoginScreen(),
      ),
    );
  }
}