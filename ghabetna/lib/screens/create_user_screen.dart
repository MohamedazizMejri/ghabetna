import 'package:flutter/material.dart';
import '../services/api_service.dart';

/*class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {

  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  final emailController = TextEditingController();
  final telController = TextEditingController();
  final cinController = TextEditingController();

  List roles = [];
  String? selectedRole;

  @override
  void initState() {
    super.initState();
    loadRoles();
  }

  void loadRoles() async {
    final data = await ApiService.getRoles();
    setState(() {
      roles = data;
    });
  }

  void createUser() async {

    final user = {
      "nom": nomController.text,
      "prenom": prenomController.text,
      "email": emailController.text,
      "numtel": telController.text,
      "cin": cinController.text,
      "role_id": selectedRole
    };

    await ApiService.createUser(user);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User created"))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create User")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: nomController,
              decoration: const InputDecoration(labelText: "Nom"),
            ),

            TextField(
              controller: prenomController,
              decoration: const InputDecoration(labelText: "Prenom"),
            ),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            TextField(
              controller: telController,
              decoration: const InputDecoration(labelText: "Telephone"),
            ),

            TextField(
              controller: cinController,
              decoration: const InputDecoration(labelText: "CIN"),
            ),

            const SizedBox(height: 20),

            DropdownButton<String>(
              hint: const Text("Select Role"),
              value: selectedRole,
              items: roles.map((role) {
                return DropdownMenuItem<String>(
                  value: role["id"],
                  child: Text(role["type_role"]),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedRole = value;
                });
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: createUser,
              child: const Text("Create User"),
            )
          ],
        ),
      ),
    );
  }
}*/

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  final emailController = TextEditingController();
  final telController = TextEditingController();
  final cinController = TextEditingController();

  List roles = [];
  String? selectedRole;

  @override
  void initState() {
    super.initState();
    loadRoles();
  }

  Future<void> loadRoles() async {
    final data = await ApiService.getRoles(); // you must have this
    setState(() {
      roles = data;
      if (roles.isNotEmpty) selectedRole = roles[0]["id"];
    });
  }

  Future<void> createUser() async {
    final data = {
      "nom": nomController.text,
      "prenom": prenomController.text,
      "email": emailController.text,
      "numtel": telController.text,
      "cin": cinController.text,
      "role_id": selectedRole,
    };

    await ApiService.createUser(data);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create User")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [

            TextField(controller: prenomController, decoration: const InputDecoration(labelText: "First Name")),
            TextField(controller: nomController, decoration: const InputDecoration(labelText: "Last Name")),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: telController, decoration: const InputDecoration(labelText: "Phone")),
            TextField(controller: cinController, decoration: const InputDecoration(labelText: "CIN")),

            const SizedBox(height: 10),

            DropdownButton<String>(
              hint: const Text("Select Role"),
              value: selectedRole,
              items: roles.map((role) {
                return DropdownMenuItem<String>(
                  value: role["id"],
                  child: Text(role["type_role"]),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedRole = value;
                });
              },
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: createUser,
              child: const Text("Create User"),
            ),
          ],
        ),
      ),
    );
  }
}