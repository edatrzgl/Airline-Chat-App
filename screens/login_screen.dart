import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Airline Chat App',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              onPressed: () async {
                try {
                  await AuthService().signInWithGoogle();
                  print("Google sign-in successful");
                } catch (e) {
                  print("Google sign-in error: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Login error: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}