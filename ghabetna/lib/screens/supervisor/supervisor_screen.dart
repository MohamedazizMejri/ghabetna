import 'package:flutter/material.dart';

class SupervisorScreen extends StatelessWidget {
  final Map user;

  const SupervisorScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Supervisor Interface"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Text("Welcome Supervisor: ${user["email"]}"),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                // TODO: show incidents list
              },
              child: const Text("View Incidents"),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                // TODO: show map
              },
              child: const Text("View Map"),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                // TODO: show agents
              },
              child: const Text("Agents List"),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                // TODO: profile
              },
              child: const Text("Profile"),
            ),
          ],
        ),
      ),
    );
  }
}