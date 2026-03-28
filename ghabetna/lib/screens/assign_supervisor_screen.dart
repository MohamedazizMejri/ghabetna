import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AssignSupervisorScreen extends StatefulWidget {
  const AssignSupervisorScreen({super.key});

  @override
  State<AssignSupervisorScreen> createState() => _AssignSupervisorScreenState();
}

class _AssignSupervisorScreenState extends State<AssignSupervisorScreen> {

  List<Map<String, dynamic>> forests = [];
  List<Map<String, dynamic>> supervisors = [];

  Map<String, dynamic>? selectedForest;
  Map<String, dynamic>? selectedSupervisor;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final f = await ApiService.getForests();
      final s = await ApiService.getSupervisors();

      setState(() {
        forests = f.cast<Map<String, dynamic>>();
        supervisors = s.cast<Map<String, dynamic>>();

        if (forests.isNotEmpty) selectedForest = forests[0];
        if (supervisors.isNotEmpty) selectedSupervisor = supervisors[0];

        isLoading = false;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading data: $e")),
      );
    }
  }

  Future<void> assignSupervisor() async {

    if (selectedForest == null || selectedSupervisor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select forest and supervisor")),
      );
      return;
    }

    try {
      await ApiService.assignSupervisor(
        selectedForest!["id"],
        selectedSupervisor!["id"],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Supervisor assigned successfully")),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Assign Supervisor",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 30),

          // Forest dropdown
          DropdownButton<Map<String, dynamic>>(
            isExpanded: true,
            value: selectedForest,
            items: forests.map((forest) {
              return DropdownMenuItem(
                value: forest,
                child: Text(forest["nom"]),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedForest = value;
              });
            },
          ),

          const SizedBox(height: 20),

          // Supervisor dropdown
          DropdownButton<Map<String, dynamic>>(
            isExpanded: true,
            value: selectedSupervisor,
            items: supervisors.map((sup) {
              return DropdownMenuItem(
                value: sup,
                child: Text(sup["nom"]),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedSupervisor = value;
              });
            },
          ),

          const SizedBox(height: 30),

          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.link),
              label: const Text("Assign"),
              onPressed: assignSupervisor,
            ),
          )
        ],
      ),
    );
  }
}