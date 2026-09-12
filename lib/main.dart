import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/student_home.dart';
import 'screens/warden_dashboard.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initSupabase();

  runApp(const LeaveEaseApp());
}

class LeaveEaseApp extends StatelessWidget {
  const LeaveEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LeaveEase',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showSplash = true;
  bool _loading = true;

  Session? _session;
  String? _role;

  @override
  void initState() {
    super.initState();

    _session = supabase.auth.currentSession;

    // Start loading the user's role if already logged in.
    if (_session != null) {
      _loadRole();
    } else {
      _loading = false;
    }

    // Listen for login/logout changes.
    supabase.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;

      setState(() {
        _session = data.session;
      });

      if (_session != null) {
        _loadRole();
      } else {
        setState(() {
          _role = null;
          _loading = false;
        });
      }
    });

    // Show splash for 2.2 seconds.
    Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;

      setState(() {
        _showSplash = false;
      });
    });
  }

  Future<void> _loadRole() async {
    if (_session == null) return;

    setState(() {
      _loading = true;
    });

    try {
      final data = await supabase
          .from('profiles')
          .select('role')
          .eq('id', _session!.user.id)
          .single();

      if (!mounted) return;

      setState(() {
        _role = data['role'];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _role = null;
        _loading = false;
      });
    }
  }

  Widget _getMainScreen() {
    // Still loading Supabase/profile.
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // User isn't logged in.
    if (_session == null) {
      return const LoginScreen();
    }

    // Warden.
    if (_role == 'warden') {
      return const WardenDashboard();
    }

    // Student.
    return const StudentHome();
  }

  @override
  Widget build(BuildContext context) {
    // Splash is displayed FIRST.
    if (_showSplash) {
      return const SplashScreen();
    }

    // After splash, AuthGate decides where to go.
    return _getMainScreen();
  }
}