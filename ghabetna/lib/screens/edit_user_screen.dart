import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditUserScreen extends StatefulWidget {
  final Map user;

  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {

  late TextEditingController nomController;
  late TextEditingController prenomController;
  late TextEditingController emailController;
  late TextEditingController telController;
  late TextEditingController cinController;

  List roles = [];
  String? selectedRole;

  @override
  void initState() {
    super.initState();

    nomController = TextEditingController(text: widget.user["nom"]);
    prenomController = TextEditingController(text: widget.user["prenom"]);
    emailController = TextEditingController(text: widget.user["email"]);
    telController = TextEditingController(text: widget.user["numtel"]);
    cinController = TextEditingController(text: widget.user["cin"]);

    selectedRole = widget.user["role_id"];

    loadRoles();
  }

  Future<void> loadRoles() async {
    final data = await ApiService.getRoles();
    setState(() {
      roles = data;
    });
  }

  Future<void> updateUser() async {
    final data = {
      "nom": nomController.text,
      "prenom": prenomController.text,
      "email": emailController.text,
      "numtel": telController.text,
      "cin": cinController.text,
      "role_id": selectedRole,
    };

    await ApiService.updateUser(widget.user["id"], data);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit User")),
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
              isExpanded: true,
              value: selectedRole,
              items: roles.map<DropdownMenuItem<String>>((role) {
                return DropdownMenuItem<String>(
                  value: role["id"].toString(),
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
              onPressed: updateUser,
              child: const Text("Update User"),
            ),
          ],
        ),
      ),
    );
  }
}