/*import 'package:flutter/material.dart';

class PartitionsScreen extends StatelessWidget {
  const PartitionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Partitions management",
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

import 'dart:convert';           
import 'package:http/http.dart' as http;



class PartitionsScreen extends StatefulWidget {
  const PartitionsScreen({super.key});

  @override
  State<PartitionsScreen> createState() => _PartitionsScreenState();
}

class _PartitionsScreenState extends State<PartitionsScreen> {

  List<Map<String, dynamic>> forests = [];

  Map<String, dynamic>? selectedForest;
  

  List<LatLng> partitionPoints = [];
  List<Map<String, dynamic>> partitions = [];
  Map<String, dynamic>? selectedPartition;

  final TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadForests();
    
    loadPartitions();
  }

  //  Load forests
  Future<void> loadForests() async {
    final data = await ApiService.getForests();
    setState(() {
      forests = data.cast<Map<String, dynamic>>();
    });
  }

  

  //  Load partitions
  /*Future<void> loadPartitions() async {
    final data = await ApiService.getPartitions();

    List<List<LatLng>> loaded = [];

    for (var p in data) {
      final coords = p["geom"]["coordinates"][0];

      List<LatLng> polygon = coords.map<LatLng>((c) {
        return LatLng(c[1], c[0]);
      }).toList();

      loaded.add(polygon);
    }

    setState(() {
      existingPartitions = loaded;
    });
  }*/
  Future<void> loadPartitions() async {
      final data = await ApiService.getPartitions();

      setState(() {
        partitions = data.cast<Map<String, dynamic>>();
      });
  }

  //  Drawing
  void addPoint(LatLng point) {
    setState(() {
      partitionPoints.add(point);
    });
  }

  void undoPoint() {
    if (partitionPoints.isNotEmpty) {
      setState(() {
        partitionPoints.removeLast();
      });
    }
  }

  void clearPoints() {
    setState(() {
      partitionPoints.clear();
    });
  }

  //  Convert to GeoJSON
  Map<String, dynamic> polygonToGeoJSON(List<LatLng> points) {
    List<List<double>> coords =
        points.map((p) => [p.longitude, p.latitude]).toList();

    coords.add([points.first.longitude, points.first.latitude]);

    return {
      "type": "Polygon",
      "coordinates": [coords]
    };
  }

  //  Save partition
  /*Future<void> savePartition() async {

    if (partitionPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Draw at least 3 points")),
      );
      return;
    }

    if (selectedForest == null || selectedAgent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select forest and agent")),
      );
      return;
    }

    final data = {
      "nom": nameController.text.isEmpty ? "Partition" : nameController.text,
      "superficie": 0,
      "geom": polygonToGeoJSON(partitionPoints),
      "foret_id": selectedForest!["id"],
      "agent_id": selectedAgent!["id"],
    };

    try {
      await ApiService.createPartition(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Partition saved")),
      );

      clearPoints();
      loadPartitions();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }*/

  Future<void> savePartition() async {
  // Check minimum points
  if (partitionPoints.length < 3) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Draw at least 3 points")),
    );
    return;
  }

  // Check if forest and agent are selected
  if (selectedForest == null ) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Select forest and agent")),
    );
    return;
  }

  // Prepare the payload
  final data = {
    "nom": nameController.text.isEmpty ? "Partition" : nameController.text,
    "superficie": 0, // You can calculate area if needed
    "geom": polygonToGeoJSON(partitionPoints),
    "foret_id": selectedForest!["id"], // must be a UUID string
    "agent_id": null, 
  };

  try {
    // Use raw HTTP request for debugging CORS and response
    final response = await http.post(
      Uri.parse("http://127.0.0.1:8000/partitions/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Partition saved successfully")),
      );

      // Clear drawn points and reload
      clearPoints();
      loadPartitions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${response.body}")),
      );
    }
  } catch (e) {
    print("ERROR: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to reach the server")),
    );
  }
}

  //  Convert forest polygon
  List<LatLng> getForestPolygon() {
    if (selectedForest == null) return [];

    final coords = selectedForest!["geom"]["coordinates"][0];

    return coords.map<LatLng>((c) {
      return LatLng(c[1], c[0]);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [

          //  Name
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "Partition name",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 10),

          // Forest dropdown
          DropdownButton<Map<String, dynamic>>(
            isExpanded: true,
            hint: const Text("Select Forest"),
            value: selectedForest,
            items: forests.map((f) {
              return DropdownMenuItem(
                value: f,
                child: Text(f["nom"]),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedForest = value;
              });
            },
          ),

          const SizedBox(height: 10),

          

          const SizedBox(height: 10),

          //  Map
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(36.8, 10.1),
                initialZoom: 8,
                onTap: (tapPos, point) {
                  addPoint(point);
                },
              ),
              children: [

                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: "com.example.app",
                ),

                PolygonLayer(
                  polygons: [

                    //  Selected forest
                    if (selectedForest != null)
                      Polygon(
                        points: getForestPolygon(),
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderColor: Colors.blue,
                        borderStrokeWidth: 3,
                      ),

                    //  Existing partitions
                        ...partitions.map((p) {
                        final coords = p["geom"]["coordinates"][0];

                        List<LatLng> polygon = coords.map<LatLng>((c) {
                          return LatLng(c[1], c[0]);
                        }).toList();

                        return Polygon(
                          points: polygon,
                          color: Colors.green.withValues(alpha: 0.3),
                          borderColor: Colors.green,
                          borderStrokeWidth: 2,
                        );
                      }),

                    //  Drawing partition
                    if (partitionPoints.isNotEmpty)
                      Polygon(
                        points: partitionPoints,
                        color: Colors.orange.withValues(alpha: 0.5),
                        borderColor: Colors.orange,
                        borderStrokeWidth: 3,
                      ),
                  ],
                ),

                MarkerLayer(
                  markers: partitionPoints.map((p) {
                    return Marker(
                      point: p,
                      width: 20,
                      height: 20,
                      child: const Icon(Icons.circle, size: 10, color: Colors.red),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          //  Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [

              ElevatedButton(
                onPressed: undoPoint,
                child: const Text("Undo"),
              ),

              ElevatedButton(
                onPressed: clearPoints,
                child: const Text("Clear"),
              ),

              ElevatedButton(
                onPressed: savePartition,
                child: const Text("Save"),
              ),
                
               
            ],
          )
        ],
      ),
    );
  }
}