import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tviowejujhpugfdmeqwu.supabase.co', // Replace with your Supabase project URL
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR2aW93ZWp1amhwdWdmZG1lcXd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg1MTIzMTMsImV4cCI6MjA1NDA4ODMxM30.ub5X9hJgLXgMY68xvoDHms22xUIyJkOKrHTz-flxaqo"
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Notes',
      home: supabase.auth.currentSession == null ? LoginScreen() : HomeScreen(),
    );
  }
}
