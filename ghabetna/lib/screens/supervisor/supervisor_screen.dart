import 'package:flutter/material.dart';
import 'supervisor_map_screen.dart';

class SupervisorScreen extends StatelessWidget {
  final Map user;

  const SupervisorScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      ///  SIDEBAR
      drawer: Drawer(
        child: ListView(
          children: [

            /// HEADER
            UserAccountsDrawerHeader(
              accountName: const Text("Supervisor"),
              accountEmail: Text(user["email"] ?? ""),
            ),

            /// MAP
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text("Map"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SupervisorMapScreen(),
                  ),
                );
              },
            ),

            /// INCIDENTS LIST (later)
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text("Incidents"),
              onTap: () {},
            ),

            /// LOGOUT 
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () {

                //  clear token
                // ApiService.token = null;

                Navigator.pushReplacementNamed(context, "/login");
              },
            ),
          ],
        ),
      ),

      appBar: AppBar(
        title: const Text("Supervisor Dashboard"),
      ),

      body: const Center(
        child: Text("Welcome Supervisor"),
      ),
    );
  }
}