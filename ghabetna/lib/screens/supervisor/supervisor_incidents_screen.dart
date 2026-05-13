import 'package:flutter/material.dart';
import '../../services/incident_service.dart';

class SupervisorIncidentsScreen extends StatefulWidget {
  const SupervisorIncidentsScreen({super.key});

  @override
  State<SupervisorIncidentsScreen> createState() =>
      _SupervisorIncidentsScreenState();
}

class _SupervisorIncidentsScreenState
    extends State<SupervisorIncidentsScreen> {

  List incidents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadIncidents();
  }

  Future<void> loadIncidents() async {
    try {
      final data = await IncidentService.getAllIncidents();
      setState(() {
        incidents = data;
        isLoading = false;
      });
    } catch (e) {
      print(e);
    }
  }

  Color getSeverityColor(int severity) {
    if (severity >= 5) return Colors.red;
    if (severity >= 3) return Colors.orange;
    return Colors.green;
  }

  Future<void> updateStatus(String id, String status, [String? comment]) async {
    try {
      await IncidentService.updateIncidentStatus(id, status, comment);
      await loadIncidents();
    } catch (e) {
      print(e);
    }
  }

  void showRejectDialog(String id) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reject Incident"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Comment"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await updateStatus(id, "rejected", controller.text);
              Navigator.pop(context);
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Incidents Table"),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Ref")),
                  DataColumn(label: Text("Description")),
                  DataColumn(label: Text("Type")),
                  DataColumn(label: Text("Severity")),
                  DataColumn(label: Text("Status")),
                  DataColumn(label: Text("Image")),
                  DataColumn(label: Text("Actions")),
                ],
                rows: incidents.map((incident) {

                  return DataRow(cells: [

                    /// Reference
                    DataCell(Text(incident["reference_code"])),

                    /// Description
                    DataCell(Text(incident["description"])),

                    /// Type
                    DataCell(Text(incident["type_code"])),

                    /// Severity
                    DataCell(
                      Text(
                        "${incident["severity"]}",
                        style: TextStyle(
                          color: getSeverityColor(incident["severity"]),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    /// Status
                    DataCell(
                      Text(
                        incident["status"] ?? "pending",
                        style: TextStyle(
                          color: incident["status"] == "accepted"
                              ? Colors.green
                              : incident["status"] == "rejected"
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                      ),
                    ),

                    /// Image
                    DataCell(
                      incident["image_url"] != null
                          ? Image.network(
                              "${IncidentService.baseUrl}${incident["image_url"]}",
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : const Text("No image"),
                    ),

                    /// Actions
                    DataCell(Row(
                      children: [

                        /// Accept
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () {
                            updateStatus(incident["id"], "accepted");
                          },
                        ),

                        /// Reject
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            showRejectDialog(incident["id"]);
                          },
                        ),

                      ],
                    )),

                  ]);

                }).toList(),
              ),
            ),
    );
  }
}