import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'db/local_db.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'providers/theme_provider.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
      url: 'https://tviowejujhpugfdmeqwu.supabase.co',
      anonKey:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR2aW93ZWp1amhwdWdmZG1lcXd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg1MTIzMTMsImV4cCI6MjA1NDA4ODMxM30.ub5X9hJgLXgMY68xvoDHms22xUIyJkOKrHTz-flxaqo");

  await LocalDB.initDB();

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
    supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        // Load user preferences when signed in
        Provider.of<ThemeProvider>(context, listen: false).loadPreferences();
      } else if (event == AuthChangeEvent.signedOut) {
        // Reset to defaults when signed out
        Provider.of<ThemeProvider>(context, listen: false).resetToDefaults();
      }
    });
  }

  Future<void> checkAuthStatus() async {
    final session = supabase.auth.currentSession;
    setState(() {
      isLoggedIn = session != null;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => MaterialApp(
        title: 'Secure Notes',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(useMaterial3: true).copyWith(
          textTheme: TextTheme(
            bodyMedium: TextStyle(fontSize: themeProvider.fontSize),
          ),
        ),
        darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
          textTheme: TextTheme(
            bodyMedium: TextStyle(fontSize: themeProvider.fontSize),
          ),
        ),
        themeMode: themeProvider.themeMode,
        home: isLoading
            ? const SplashScreen()
            : isLoggedIn
                ? const HomeScreen()
                : const LoginScreen(),
      ),
    );
  }
}

// 🎨 Simple Splash Screen (Prevents UI flickering)
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
