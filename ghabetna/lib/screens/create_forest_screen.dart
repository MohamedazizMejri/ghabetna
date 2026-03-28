
/*import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class CreateForestScreen extends StatefulWidget {
  final Map user;
  const CreateForestScreen({
    super.key,
    required this.user,
  });

  @override
  State<CreateForestScreen> createState() => _CreateForestScreenState();
}

class _CreateForestScreenState extends State<CreateForestScreen> {

  final TextEditingController nameController = TextEditingController();

  List<LatLng> polygonPoints = [];
  List<List<LatLng>> savedForests = [];

  @override
  void initState() {
    super.initState();
    loadForests();
  }

  void addPoint(LatLng point) {
    setState(() {
      polygonPoints.add(point);
    });
  }

  void clearPolygon() {
    setState(() {
      polygonPoints.clear();
    });
  }

  void undoLastPoint() {
    if (polygonPoints.isNotEmpty) {
      setState(() {
        polygonPoints.removeLast();
      });
    }
  }

  Map polygonToGeoJSON(List<LatLng> points) {

    List coordinates =
        points.map((p) => [p.longitude, p.latitude]).toList();

    coordinates.add(
        [points.first.longitude, points.first.latitude]);

    return {
      "type": "Polygon",
      "coordinates": [coordinates]
    };
  }

  Future<void> saveForest() async {

    if (polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Draw at least 3 points"))
      );
      return;
    }

    Map geojson = polygonToGeoJSON(polygonPoints);

    final forest = {
      "nom": nameController.text,
      "geom": geojson,
      "created_by": widget.user["id"],
      "supervised_by": "SUPERVISOR_UUID_HERE"
    };

    try {

      await ApiService.createForest(forest);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Forest saved"))
      );

      Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error saving forest"))
      );

    }
  }

  Future<void> loadForests() async {

    final forests = await ApiService.getForests();

    List<List<LatLng>> loadedPolygons = [];

    for (var forest in forests) {

      final coords = forest["geom"]["coordinates"][0];

      List<LatLng> polygon = coords.map<LatLng>((c) {
        return LatLng(c[1], c[0]);
      }).toList();

      loadedPolygons.add(polygon);
    }

    setState(() {
      savedForests = loadedPolygons;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Forest"),
      ),

      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Forest name",
                border: OutlineInputBorder(),
              ),
            ),
          ),

          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(36.8, 10.1),
                initialZoom: 8,

                onTap: (tapPosition, point) {
                  addPoint(point);
                },
              ),

              children: [

                TileLayer(
                  urlTemplate:
                      "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: "com.example.app",
                ),

                /*PolygonLayer(
                  polygons: polygonPoints.isNotEmpty
                      ? [
                          Polygon(
                            points: polygonPoints,
                            color: Colors.green.withValues(alpha: 0.4),
                            borderColor: Colors.green,
                            borderStrokeWidth: 3,
                          )
                        ]
                      : <Polygon>[],
                ),*/
                PolygonLayer(
                  polygons: [

                    // Saved forests from database
                    ...savedForests.map((points) {
                      return Polygon(
                        points: points,
                        color: Colors.blue.withValues(alpha: 0.3),
                        borderColor: Colors.blue,
                        borderStrokeWidth: 2,
                      );
                    }),

                    // Forest currently being drawn
                    if (polygonPoints.isNotEmpty)
                      Polygon(
                        points: polygonPoints,
                        color: Colors.green.withValues(alpha: 0.4),
                        borderColor: Colors.green,
                        borderStrokeWidth: 3,
                      ),
                  ],
                ),
                MarkerLayer(
                  markers: polygonPoints.map((p) {
                    return Marker(
                      point: p,
                      width: 20,
                      height: 20,
                      child: const Icon(
                        Icons.circle,
                        size: 12,
                        color: Colors.red,
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                ElevatedButton.icon(
                  icon: const Icon(Icons.undo),
                  label: const Text("Undo"),
                  onPressed: undoLastPoint,
                ),

                ElevatedButton.icon(
                  icon: const Icon(Icons.clear),
                  label: const Text("Clear"),
                  onPressed: clearPolygon,
                ),

                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Save"),
                  onPressed: saveForest,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}*/

/*import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class CreateForestScreen extends StatefulWidget {
  final Map user; // logged-in admin
  const CreateForestScreen({super.key, required this.user});

  @override
  State<CreateForestScreen> createState() => _CreateForestScreenState();
}

class _CreateForestScreenState extends State<CreateForestScreen> {
  final TextEditingController nameController = TextEditingController();

  List<LatLng> polygonPoints = [];
  List<List<LatLng>> savedForests = [];

  List<Map<String, dynamic>> supervisors = [];
  Map<String, dynamic>? selectedSupervisor;

  @override
  void initState() {
    super.initState();
    loadForests();
    loadSupervisors();
  }

  Future<void> loadSupervisors() async {
    try {
      final data = await ApiService.getSupervisors();
      setState(() {
        supervisors = data.cast<Map<String, dynamic>>();
        if (supervisors.isNotEmpty) {
        selectedSupervisor = supervisors[0]; 
      }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load supervisors: $e")),
      );
    }
  }

  void addPoint(LatLng point) {
    setState(() {
      polygonPoints.add(point);
    });
  }

  void clearPolygon() {
    setState(() {
      polygonPoints.clear();
    });
  }

  void undoLastPoint() {
    if (polygonPoints.isNotEmpty) {
      setState(() {
        polygonPoints.removeLast();
      });
    }
  }

  Map polygonToGeoJSON(List<LatLng> points) {
    List coordinates = points.map((p) => [p.longitude, p.latitude]).toList();
    coordinates.add([points.first.longitude, points.first.latitude]);
    return {
      "type": "Polygon",
      "coordinates": [coordinates]
    };
  }

  Future<void> saveForest() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a forest name")),
      );
      return;
    }
    if (polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Draw at least 3 points")),
      );
      return;
    }
    if (selectedSupervisor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a supervisor")),
      );
      return;
    }

    Map geojson = polygonToGeoJSON(polygonPoints);

    final forest = {
      "nom": nameController.text,
      "geom": geojson,
      "created_by": widget.user["id"],           // Admin UUID
      "supervised_by": selectedSupervisor!["id"] // Supervisor UUID
    };

    try {
      await ApiService.createForest(forest);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Forest saved")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving forest: $e")),
      );
    }
  }

  Future<void> loadForests() async {
    final forests = await ApiService.getForests();
    List<List<LatLng>> loadedPolygons = [];

    for (var forest in forests) {
      final coords = forest["geom"]["coordinates"][0];
      List<LatLng> polygon = coords.map<LatLng>((c) {
        return LatLng(c[1], c[0]);
      }).toList();
      loadedPolygons.add(polygon);
    }

    setState(() {
      savedForests = loadedPolygons;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Forest")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Forest name",
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // Supervisor Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<Map<String, dynamic>>(
              hint: const Text("Select Supervisor"),
              value: selectedSupervisor,
              isExpanded: true,
              items: supervisors.map((sup) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: sup,
                  child: Text("${sup['prenom']} ${sup['nom']}"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSupervisor = value as Map<String, dynamic>?;
                });
              },
            ),
          ),

          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(36.8, 10.1),
                initialZoom: 8,
                onTap: (tapPosition, point) => addPoint(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: "com.example.app",
                ),

                PolygonLayer(
                  polygons: [
                    // Saved forests
                    ...savedForests.map((points) {
                      return Polygon(
                        points: points,
                        color: Colors.blue.withValues(alpha: 0.3),
                        borderColor: Colors.blue,
                        borderStrokeWidth: 2,
                      );
                    }),
                    // Currently drawn forest
                    if (polygonPoints.isNotEmpty)
                      Polygon(
                        points: polygonPoints,
                        color: Colors.green.withValues(alpha: 0.4),
                        borderColor: Colors.green,
                        borderStrokeWidth: 3,
                      ),
                  ],
                ),
                MarkerLayer(
                  markers: polygonPoints.map((p) {
                    return Marker(
                      point: p,
                      width: 20,
                      height: 20,
                      child: const Icon(Icons.circle, size: 12, color: Colors.red),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.undo),
                  label: const Text("Undo"),
                  onPressed: undoLastPoint,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.clear),
                  label: const Text("Clear"),
                  onPressed: clearPolygon,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Save"),
                  onPressed: saveForest,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class CreateForestScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const CreateForestScreen({super.key, required this.user});

  @override
  State<CreateForestScreen> createState() => _CreateForestScreenState();
}

class _CreateForestScreenState extends State<CreateForestScreen> {
  final TextEditingController nameController = TextEditingController();

  List<LatLng> polygonPoints = [];
  List<List<LatLng>> savedForests = [];

  /*List<Map<String, dynamic>> supervisors = [];
  Map<String, dynamic>? selectedSupervisor;*/

  @override
  void initState() {
    super.initState();
    loadForests();
    /*loadSupervisors();*/
  }

  /*// Load supervisors from API
  Future<void> loadSupervisors() async {
    try {
      final data = await ApiService.getSupervisors();
      setState(() {
        supervisors = data.cast<Map<String, dynamic>>();
        if (supervisors.isNotEmpty) {
          selectedSupervisor = supervisors[0];
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load supervisors: $e")),
      );
    }
  }*/


  // Load saved forests
  Future<void> loadForests() async {
    try {
      final forests = await ApiService.getForests();
      List<List<LatLng>> loadedPolygons = [];

      for (var forest in forests) {
        final coords = forest["geom"]["coordinates"][0];
        List<LatLng> polygon = coords.map<LatLng>((c) {
          return LatLng(c[1], c[0]);
        }).toList();
        loadedPolygons.add(polygon);
      }

      setState(() {
        savedForests = loadedPolygons;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load forests: $e")),
      );
    }
  }

  // Add a point to the current polygon
  void addPoint(LatLng point) {
    setState(() {
      polygonPoints.add(point);
    });
  }

  void clearPolygon() {
    setState(() {
      polygonPoints.clear();
    });
  }

  void undoLastPoint() {
    if (polygonPoints.isNotEmpty) {
      setState(() {
        polygonPoints.removeLast();
      });
    }
  }

  // Convert LatLng polygon to GeoJSON
  Map<String, dynamic> polygonToGeoJSON(List<LatLng> points) {
    List<List<double>> coordinates =
        points.map((p) => [p.longitude, p.latitude]).toList();
    // Close polygon
    coordinates.add([points.first.longitude, points.first.latitude]);
    return {"type": "Polygon", "coordinates": [coordinates]};
  }

  // Save forest to backend
  Future<void> saveForest() async {
    if (polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Draw at least 3 points")),
      );
      return;
    }
    /*if (selectedSupervisor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select a supervisor")),
      );
      return;
    }*/

    final forestData = {
      "nom": nameController.text.isEmpty ? "Forest" : nameController.text,
      "geom": polygonToGeoJSON(polygonPoints),
      "created_by": widget.user["id"],
      "supervised_by":null, /*selectedSupervisor!["id"],*/
    };

    try {
      await ApiService.createForest(forestData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Forest saved successfully")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error saving forest")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Forest")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Forest name",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // Supervisor dropdown
          /*Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: supervisors.isEmpty
                ? const CircularProgressIndicator()
                : DropdownButton<Map<String, dynamic>>(
                    isExpanded: true,
                    value: selectedSupervisor,
                    items: supervisors.map((supervisor) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: supervisor,
                        child: Text(supervisor["nom"]),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSupervisor = value as Map<String, dynamic>?;
                      });
                    },
                  ),
          ),*/
          const SizedBox(height: 10),
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
                    ...savedForests.map((points) => Polygon(
                          points: points,
                          color: Colors.blue.withValues(alpha: 0.3),
                          borderColor: Colors.blue,
                          borderStrokeWidth: 2,
                        )),
                    if (polygonPoints.isNotEmpty)
                      Polygon(
                        points: polygonPoints,
                        color: Colors.green.withValues(alpha: 0.4),
                        borderColor: Colors.green,
                        borderStrokeWidth: 3,
                      ),
                  ],
                ),
                MarkerLayer(
                  markers: polygonPoints.map((p) {
                    return Marker(
                      point: p,
                      width: 20,
                      height: 20,
                      child: const Icon(
                        Icons.circle,
                        size: 12,
                        color: Colors.red,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.undo),
                  label: const Text("Undo"),
                  onPressed: undoLastPoint,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.clear),
                  label: const Text("Clear"),
                  onPressed: clearPolygon,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Save"),
                  onPressed: saveForest,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}