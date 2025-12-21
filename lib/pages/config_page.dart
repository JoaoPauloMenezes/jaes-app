import 'package:flutter/material.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.settings, size: 64, color: Colors.blue),
          SizedBox(height: 16),
          Text('Configuration Page', style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }
}