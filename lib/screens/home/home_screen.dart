import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String displayName;
  final String accessToken;
  final String refreshToken;

  const HomeScreen({
    super.key,
    required this.displayName,
    required this.accessToken,
    required this.refreshToken,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome $displayName"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Welcome, $displayName 👋",
                style: const TextStyle(fontSize: 20),
              ),

              const SizedBox(height: 20),

              Text(
                "Access Token:",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                accessToken,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Logout"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
