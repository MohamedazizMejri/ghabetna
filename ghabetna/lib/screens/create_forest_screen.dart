import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

const List<String> kGouvernorats = [
  'Ariana', 'Béja', 'Ben Arous', 'Bizerte', 'Gabès', 'Gafsa',
  'Jendouba', 'Kairouan', 'Kasserine', 'Kébili', 'Le Kef', 'Mahdia',
  'La Manouba', 'Médenine', 'Monastir', 'Nabeul', 'Sfax', 'Sidi Bouzid',
  'Siliana', 'Sousse', 'Tataouine', 'Tozeur', 'Tunis', 'Zaghouan',
];

class CreateForestScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const CreateForestScreen({super.key, required this.user});

  @override
  State<CreateForestScreen> createState() => _CreateForestScreenState();
}

class _CreateForestScreenState extends State<CreateForestScreen> {
  final TextEditingController nameController = TextEditingController();

  // Current drawing
  List<LatLng> polygonPoints = [];

  // Redo stack — points that were undone
  List<LatLng> redoStack = [];

  // Existing forests from DB (shown in blue so user avoids them)
  List<Map<String, dynamic>> savedForests = [];

  String? selectedRegion;
  bool isSaving = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadForests();
  }

  Future<void> loadForests() async {
    try {
      final forests = await ApiService.getForests();
      setState(() {
        savedForests = forests.cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _snack('Failed to load existing forests');
    }
  }

  // ── Drawing controls ──────────────────────────────────────────────

  void addPoint(LatLng point) {
    setState(() {
      polygonPoints.add(point);
      redoStack.clear(); // a new point invalidates the redo stack
    });
  }

  void undoLastPoint() {
    if (polygonPoints.isEmpty) return;
    setState(() {
      redoStack.add(polygonPoints.removeLast());
    });
  }

  void redoLastPoint() {
    if (redoStack.isEmpty) return;
    setState(() {
      polygonPoints.add(redoStack.removeLast());
    });
  }

  void clearPolygon() {
    setState(() {
      redoStack.addAll(polygonPoints.reversed);
      polygonPoints.clear();
    });
  }

  // ── GeoJSON helper ────────────────────────────────────────────────

  Map<String, dynamic> polygonToGeoJSON(List<LatLng> points) {
    final coords = points.map((p) => [p.longitude, p.latitude]).toList();
    coords.add([points.first.longitude, points.first.latitude]); // close ring
    return {'type': 'Polygon', 'coordinates': [coords]};
  }

  // ── Save ──────────────────────────────────────────────────────────

  Future<void> saveForest() async {
    if (nameController.text.trim().isEmpty) {
      _snack('Please enter a forest name');
      return;
    }
    if (selectedRegion == null) {
      _snack('Please select a region');
      return;
    }
    if (polygonPoints.length < 3) {
      _snack('Draw at least 3 points on the map');
      return;
    }

    setState(() => isSaving = true);

    final forestData = {
      'nom': nameController.text.trim(),
      'geom': polygonToGeoJSON(polygonPoints),
      'region': selectedRegion,
      'created_by': widget.user['id'],
      'supervised_by': null,
    };

    try {
      await ApiService.createForest(forestData);
      if (!mounted) return;
      _snack('Forest saved successfully', success: true);
      Navigator.pop(context, true); // true = reload forests list
    } catch (e) {
      _snack('Error saving forest');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green : null,
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Forest')),
      body: Column(
        children: [
          // ── Name + Region row ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                // Forest name
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Forest name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Region dropdown
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: selectedRegion,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Region',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: kGouvernorats
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedRegion = v),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Map ───────────────────────────────────────────────
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                    options: MapOptions(
                      initialCenter: const LatLng(33.8, 9.5), // center of Tunisia
                      initialZoom: 7,
                      onTap: (_, point) => addPoint(point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),

                      PolygonLayer(
                        polygons: [
                          // Existing forests — blue, non-interactive visual barrier
                          ...savedForests.map((f) {
                            final coords = f['geom']['coordinates'][0] as List;
                            final points = coords
                                .map<LatLng>((c) => LatLng(c[1], c[0]))
                                .toList();
                            return Polygon(
                              points: points,
                              color: Colors.blue.withValues(alpha: 0.25),
                              borderColor: Colors.blue,
                              borderStrokeWidth: 2,
                            );
                          }),

                          // Currently being drawn — green
                          if (polygonPoints.length >= 2)
                            Polygon(
                              points: polygonPoints,
                              color: Colors.green.withValues(alpha: 0.35),
                              borderColor: Colors.green,
                              borderStrokeWidth: 3,
                            ),
                        ],
                      ),

                      // Red dots for each tapped point
                      MarkerLayer(
                        markers: polygonPoints
                            .map((p) => Marker(
                                  point: p,
                                  width: 16,
                                  height: 16,
                                  child: const Icon(Icons.circle,
                                      size: 10, color: Colors.red),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
          ),

          // ── Legend ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _legendDot(Colors.blue),
                const SizedBox(width: 4),
                const Text('Existing forest', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                _legendDot(Colors.green),
                const SizedBox(width: 4),
                const Text('New forest', style: TextStyle(fontSize: 12)),
                const Spacer(),
                Text(
                  '${polygonPoints.length} point${polygonPoints.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          // ── Controls ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _controlButton(
                  icon: Icons.undo,
                  label: 'Undo',
                  onPressed: polygonPoints.isNotEmpty ? undoLastPoint : null,
                ),
                _controlButton(
                  icon: Icons.redo,
                  label: 'Redo',
                  onPressed: redoStack.isNotEmpty ? redoLastPoint : null,
                ),
                _controlButton(
                  icon: Icons.delete_outline,
                  label: 'Clear',
                  onPressed: polygonPoints.isNotEmpty ? clearPolygon : null,
                  color: Colors.red,
                ),
                _controlButton(
                  icon: Icons.save,
                  label: isSaving ? 'Saving…' : 'Save',
                  onPressed: isSaving ? null : saveForest,
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.4),
          border: Border.all(color: color, width: 1.5),
          shape: BoxShape.circle,
        ),
      );

  Widget _controlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onPressed: onPressed,
    );
  }
}