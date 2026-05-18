import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../services/incident_service.dart';
import '../../services/api_service.dart';

class SupervisorMapScreen extends StatefulWidget {
  const SupervisorMapScreen({super.key});

  @override
  State<SupervisorMapScreen> createState() => _SupervisorMapScreenState();
}

class _SupervisorMapScreenState extends State<SupervisorMapScreen> {

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

  ///  severity → color
  Color getSeverityColor(int severity) {
    if (severity >= 5) return Colors.red;
    if (severity >= 3) return Colors.orange;
    return Colors.green;
  }

  ///  markers
  List<Marker> buildMarkers() {
    return incidents.map<Marker>((incident) {
      return Marker(
        width: 40,
        height: 40,
        point: LatLng(
          incident["latitude"],
          incident["longitude"],
        ),
        child: GestureDetector(
          onTap: () => showIncidentDialog(incident),
          child: Icon(
            Icons.location_on,
            color: getSeverityColor(incident["severity"] ?? 1),
            size: 35,
          ),
        ),
      );
    }).toList();
  }

  ///  popup
void showIncidentDialog(Map incident) {
  final commentController = TextEditingController();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Incident Details"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          ///  IMAGE
          if (incident["image_url"] != null)
            Image.network(
              "${ApiService.baseUrl}${incident["image_url"]}",
              height: 150,
            ),

          const SizedBox(height: 10),

          Text(incident["description"] ?? ""),

          const SizedBox(height: 5),

          Text("Status: ${incident["status"]}"),

          const SizedBox(height: 10),

          /// COMMENT FIELD
          TextField(
            controller: commentController,
            decoration: const InputDecoration(
              labelText: "Comment (for rejection)",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await updateStatus(
               incident["id"],
              "accepted",
              null
            );
            Navigator.pop(context);
          },
          child: const Text("Approve"),
        ),
        TextButton(
          onPressed: () async {
            if (commentController.text.isEmpty) return;

            await updateStatus(
              incident["id"],
              "rejected",
              commentController.text,
            );

            Navigator.pop(context);
          },
          child: const Text("Reject"),
        ),
      ],
    ),
  );
}

  Future<void> updateStatus(String id, String status ,String? comment,) async {
    await IncidentService.updateIncidentStatus(id, status, comment);
    loadIncidents();
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Supervisor Map")),

      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(36.8, 10.1),
          initialZoom: 10,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          ),
          MarkerLayer(
            markers: buildMarkers(),
          ),
        ],
      ),
    );
  }
}