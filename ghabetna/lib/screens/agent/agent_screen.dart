import 'package:flutter/material.dart';

class AgentScreen extends StatelessWidget {
  final Map user;

  const AgentScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agent Interface"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Text("Welcome Agent: ${user["email"]}"),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                // TODO: go to create incident screen
              },
              child: const Text("Create Incident"),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                // TODO: view my incidents
              },
              child: const Text("My Incidents"),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                // TODO: profile screen
              },
              child: const Text("Profile"),
            ),
          ],
        ),
      ),
    );
  }
}