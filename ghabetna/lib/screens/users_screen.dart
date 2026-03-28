import 'package:flutter/material.dart';
import 'create_user_screen.dart';
import '../services/api_service.dart';
import 'edit_user_screen.dart';
/*class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Users",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateUserScreen(),
                ),
              );
            },
            child: const Text("Create User"),
          ),
        ],
      ),
    );
  }
}*/
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List users = [];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    final data = await ApiService.getUsers();
    setState(() {
      users = data;
    });
  }

  Future<void> deleteUser(String id) async {
    await ApiService.deleteUser(id);
    loadUsers();
  }

  Color getRoleColor(String role) {
    switch (role) {
      case "admin":
        return Colors.red;
      case "superviseur":
        return Colors.blue;
      case "agent":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [

          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateUserScreen(),
                ),
              ).then((_) => loadUsers());
            },
            child: const Text("Create User"),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (_, i) {
                final u = users[i];

                return Card(
                  child: ListTile(
                    title: Text("${u["prenom"]} ${u["nom"]}"),
                    subtitle: Row(
                                    children: [
                                      Expanded(
                                        child: Text("${u["email"]} • ${u["numtel"]}"),
                                      ),

                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: getRoleColor(u["role"]["type_role"]),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          u["role"]["type_role"],
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        //  EDIT BUTTON
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditUserScreen(user: u),
                              ),
                            ).then((_) => loadUsers());
                          },
                        ),

                        //  DELETE BUTTON
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteUser(u["id"]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}