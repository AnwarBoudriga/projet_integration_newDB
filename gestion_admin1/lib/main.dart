import 'package:flutter/material.dart';
import 'core/api.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/shell.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PsyTech Pro - Super Administrateur',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    home: const AuthGate(),
  );
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool? _logged;

  @override
  void initState() {
    super.initState();
    Api.onUnauthorized = () {
      if (mounted) setState(() => _logged = false);
    };
    Api.hasToken().then((v) {
      if (mounted) setState(() => _logged = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_logged == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _logged!
        ? Shell(onLogout: () async {
      await Api.logout();
      if (mounted) setState(() => _logged = false);
    })
        : LoginScreen(onLoggedIn: () => setState(() => _logged = true));
  }
}