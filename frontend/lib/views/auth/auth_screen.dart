import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLogin ? const LoginScreen() : const RegisterScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleAuthMode,
        child: Icon(_isLogin ? Icons.person_add : Icons.login),
      ),
    );
  }
}
