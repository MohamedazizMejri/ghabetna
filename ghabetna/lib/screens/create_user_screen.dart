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
}*/
class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  final emailController = TextEditingController();
  final telController = TextEditingController();
  final cinController = TextEditingController();

  List roles = [];
  String? selectedRole;
  String? roleError;

  @override
  void initState() {
    super.initState();
    loadRoles();
  }

  Future<void> loadRoles() async {
    final data = await ApiService.getRoles();
    setState(() {
      roles = data;
      if (roles.isNotEmpty) selectedRole = roles[0]["id"];
    });
  }

  Future<void> createUser() async {
    setState(() {
      roleError = selectedRole == null ? "Please select a role" : null;
    });

    if (!_formKey.currentState!.validate() || selectedRole == null) return;

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

  // ── Validators ──────────────────────────────────────────────

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Email is required";

    // must contain @
    final atIndex = value.indexOf('@');
    if (atIndex < 1) return "Email must contain '@'";

    final afterAt = value.substring(atIndex + 1);

    // must have a dot after @
    final dotIndex = afterAt.lastIndexOf('.');
    if (dotIndex < 1) return "Email must contain a '.' after '@'";

    // must have something after the last dot
    final extension = afterAt.substring(dotIndex + 1);
    if (extension.isEmpty) return "Email must end with '.something'";

    return null;
  }

  String? _validateCin(String? value) {
    if (value == null || value.isEmpty) return "CIN is required";
    if (!RegExp(r'^\d+$').hasMatch(value)) return "CIN must contain numbers only";
    if (value.length != 8) return "CIN must be exactly 8 digits";
    return null;
  }

  String? _validateTel(String? value) {
    if (value == null || value.isEmpty) return "Phone number is required";
    if (!RegExp(r'^\d+$').hasMatch(value)) return "Phone must contain numbers only";
    if (value.length != 8) return "Phone must be exactly 8 digits";
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) return "$fieldName is required";
    return null;
  }

  // ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create User")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: prenomController,
                decoration: const InputDecoration(labelText: "First Name"),
                validator: (v) => _validateRequired(v, "First Name"),
              ),
              TextFormField(
                controller: nomController,
                decoration: const InputDecoration(labelText: "Last Name"),
                validator: (v) => _validateRequired(v, "Last Name"),
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              TextFormField(
                controller: telController,
                decoration: const InputDecoration(labelText: "Phone"),
                keyboardType: TextInputType.number,
                maxLength: 8,
                validator: _validateTel,
              ),
              TextFormField(
                controller: cinController,
                decoration: const InputDecoration(labelText: "CIN"),
                keyboardType: TextInputType.number,
                maxLength: 8,
                validator: _validateCin,
              ),

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
                    roleError = null;
                  });
                },
              ),

              if (roleError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text(
                    roleError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                  ),
                ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: createUser,
                child: const Text("Create User"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}