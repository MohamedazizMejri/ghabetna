import 'package:flutter/material.dart';

import 'my_incidents_screen.dart';
import 'create_incident_screen.dart'; // create this next

class AgentScreen extends StatelessWidget {
  final Map user;

  const AgentScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agent Interface"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                "/login",
                (route) => false,
              );
            },
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            ///  User info
            Text(
              "Welcome, ${user["email"] ?? "Agent"}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            ///  Create Incident
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_alert),
                label: const Text("Create Incident"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateIncidentScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            ///  My Incidents
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.list),
                label: const Text("My Incidents"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyIncidentsScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            ///  Future: Map
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text("Map (Coming Soon)"),
                onPressed: () {},
              ),
            ),

            const SizedBox(height: 15),

            ///  Profile (optional)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.person),
                label: const Text("Profile"),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}