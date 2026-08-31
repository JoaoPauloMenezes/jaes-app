import 'dart:ui';

import 'package:flutter/material.dart';
import 'home_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class logoJaes extends StatelessWidget {
  const logoJaes({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: 100,
      margin: const EdgeInsets.only(top: 50, bottom: 20),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("lib/assets/images/SchoolLogoTransparente.png"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';

  void _login() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const logoJaes(),
            Form(
              key: _formKey,
              child: Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.black.withOpacity(0.1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaY: 5, sigmaX: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: 'Username'),
                              onChanged: (value) => _username = value,
                              // validator: (value) => value!.isEmpty ? 'Enter your username' : null,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 16, right: 16),
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: 'Password'),
                              obscureText: true,
                              onChanged: (value) => _password = value,
                              // validator: (value) => value!.isEmpty ? 'Enter your password' : null,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _login,
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}