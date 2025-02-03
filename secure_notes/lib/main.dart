import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'db/local_db.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'package:path_provider/path_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Supabase
  await Supabase.initialize(
    url: 'https://tviowejujhpugfdmeqwu.supabase.co',
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR2aW93ZWp1amhwdWdmZG1lcXd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg1MTIzMTMsImV4cCI6MjA1NDA4ODMxM30.ub5X9hJgLXgMY68xvoDHms22xUIyJkOKrHTz-flxaqo"
  );

  // ✅ Initialize the encrypted SQLite database
  await LocalDB.initDB();

   final dbPath = await getApplicationDocumentsDirectory();
  print("📂 Database Path: ${dbPath.path}/secure_notes.db");

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    setState(() {
      isLoggedIn = supabase.auth.currentSession != null;
      isLoading = false;
    });

    supabase.auth.onAuthStateChange.listen((data) {
      if (data.session == null) {
        print("🔴 Session expired, logging out.");
        setState(() => isLoggedIn = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Notes',
      debugShowCheckedModeBanner: false,
      home: isLoading ? SplashScreen() : (isLoggedIn ? HomeScreen() : LoginScreen()),
    );
  }
}

// 🎨 Simple Splash Screen (Prevents UI flickering)
class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
