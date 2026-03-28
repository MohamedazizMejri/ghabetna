import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AssignAgentScreen extends StatefulWidget {
  const AssignAgentScreen({super.key});

  @override
  State<AssignAgentScreen> createState() => _AssignAgentScreenState();
}

class _AssignAgentScreenState extends State<AssignAgentScreen> {

  List<Map<String, dynamic>> partitions = [];
  List<Map<String, dynamic>> agents = [];

  Map<String, dynamic>? selectedPartition;
  Map<String, dynamic>? selectedAgent;

  @override
  void initState() {
    super.initState();
    loadPartitions();
    loadAgents();
  }

  Future<void> loadPartitions() async {
    final data = await ApiService.getPartitions();
    setState(() {
      partitions = data.cast<Map<String, dynamic>>();
    });
  }

  Future<void> loadAgents() async {
    final data = await ApiService.getAgents();
    setState(() {
      agents = data.cast<Map<String, dynamic>>();
    });
  }

  Future<void> assignAgent() async {
    if (selectedPartition == null || selectedAgent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select partition and agent")),
      );
      return;
    }

    try {
      await ApiService.assignAgent(
        selectedPartition!["id"],
        selectedAgent!["id"],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Agent assigned successfully")),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Assign Agent to Partition",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          //  Partition dropdown
          DropdownButton<Map<String, dynamic>>(
            isExpanded: true,
            hint: const Text("Select Partition"),
            value: selectedPartition,
            items: partitions.map((p) {
              return DropdownMenuItem(
                value: p,
                child: Text(p["nom"]),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedPartition = value;
              });
            },
          ),

          const SizedBox(height: 20),

          //  Agent dropdown
          DropdownButton<Map<String, dynamic>>(
            isExpanded: true,
            hint: const Text("Select Agent"),
            value: selectedAgent,
            items: agents.map((a) {
              return DropdownMenuItem(
                value: a,
                child: Text(a["nom"]),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedAgent = value;
              });
            },
          ),

          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: assignAgent,
            child: const Text("Assign"),
          )
        ],
      ),
    );
  }
}