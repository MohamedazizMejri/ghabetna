/*import 'package:flutter/material.dart';
import 'create_forest_screen.dart';

class ForestsScreen extends StatelessWidget {
  final Map user;
  const ForestsScreen({super.key, required this.user});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Forests",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Create Forest"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateForestScreen(user: user),
                ),
              );
            },
          ),

          const SizedBox(height: 30),

          const Text(
            "List of forests will appear here",
            style: TextStyle(fontSize: 18),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  "No forests loaded yet",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}*/
import 'package:flutter/material.dart';
import 'create_forest_screen.dart';

class ForestsScreen extends StatelessWidget {

  final Map user;

  const ForestsScreen({super.key, required this.user}); 

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Forests",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Create Forest"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateForestScreen(
                      user: Map<String, dynamic>.from(user),
                    ),
                ),
              );
            },
          ),

          const SizedBox(height: 30),

          const Text(
            "List of forests will appear here",
            style: TextStyle(fontSize: 18),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  "No forests loaded yet",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}