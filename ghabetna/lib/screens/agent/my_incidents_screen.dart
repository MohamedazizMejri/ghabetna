import 'package:flutter/material.dart';
import '../../services/incident_service.dart';

class MyIncidentsScreen extends StatefulWidget {
  const MyIncidentsScreen({super.key});

  @override
  State<MyIncidentsScreen> createState() => _MyIncidentsScreenState();
}

class _MyIncidentsScreenState extends State<MyIncidentsScreen> {

  List incidents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchIncidents();
  }

  void fetchIncidents() async {
    try {
      final data = await IncidentService.getMyIncidents();
      setState(() {
        incidents = data;
        isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Incidents")),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: incidents.length,
              itemBuilder: (context, index) {
                final incident = incidents[index];

                return ListTile(
                  title: Text(incident["description"]),
                  subtitle: Text("Type: ${incident["type_code"]}"),
                );
              },
            ),
    );
  }
}