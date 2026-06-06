import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

// ── Distinct colors for existing partitions ───────────────────────────────────
const _partitionColors = [
  Colors.orange,
  Colors.purple,
  Colors.red,
  Colors.teal,
  Colors.indigo,
  Colors.pink,
  Colors.brown,
  Colors.cyan,
];

Color _colorForIndex(int i) => _partitionColors[i % _partitionColors.length];

// ─────────────────────────────────────────────────────────────────────────────

class PartitionsScreen extends StatefulWidget {
  /// When navigated from ForestsScreen, the forest is pre-selected.
  /// When opened from the sidebar it is null and the user picks from dropdown.
  final Map<String, dynamic>? forest;

  const PartitionsScreen({super.key, this.forest});

  @override
  State<PartitionsScreen> createState() => _PartitionsScreenState();
}

class _PartitionsScreenState extends State<PartitionsScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> forests = [];
  String? selectedForestId;  // store only the id string, not the full map object

  Map<String, dynamic>? get selectedForest =>
      selectedForestId == null
          ? null
          : forests.firstWhere(
              (f) => f['id']?.toString() == selectedForestId,
              orElse: () => forests.first,
            );


  List<Map<String, dynamic>> allPartitions = [];   // all from API
  List<Map<String, dynamic>> get forestPartitions  // filtered to selected forest
      => selectedForestId == null
          ? []
          : allPartitions
              .where((p) =>
                  p['foret_id']?.toString() == selectedForestId)
              .toList();

  // Drawing
  List<LatLng> polygonPoints = [];
  List<LatLng> redoStack = [];

  final TextEditingController nameController = TextEditingController();
  bool isSaving = false;

  // View toggle: 'list' or 'draw'
  String view = 'list';

  // ── Init ───────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    // Do NOT assign widget.forest directly here — dropdown items load async
    // and object references won't match. We match by id inside loadForests().
    loadForests();
    loadPartitions();
  }

  // ── Loaders ────────────────────────────────────────────────────────────────
  Future<void> loadForests() async {
    final data = await ApiService.getForests();
    setState(() {
      forests = data.cast<Map<String, dynamic>>();
      if (widget.forest != null) {
        selectedForestId = widget.forest!['id']?.toString();
      }
    });
  }

  Future<void> loadPartitions() async {
    final data = await ApiService.getPartitions();
    setState(() => allPartitions = data.cast<Map<String, dynamic>>());
  }

  // ── Drawing ────────────────────────────────────────────────────────────────
  void addPoint(LatLng point) {
    setState(() {
      polygonPoints.add(point);
      redoStack.clear();
    });
  }

  void undoPoint() {
    if (polygonPoints.isEmpty) return;
    setState(() => redoStack.add(polygonPoints.removeLast()));
  }

  void redoPoint() {
    if (redoStack.isEmpty) return;
    setState(() => polygonPoints.add(redoStack.removeLast()));
  }

  void clearPoints() {
    setState(() {
      redoStack.addAll(polygonPoints.reversed);
      polygonPoints.clear();
    });
  }

  Map<String, dynamic> polygonToGeoJSON(List<LatLng> points) {
    final coords = points.map((p) => [p.longitude, p.latitude]).toList();
    coords.add([points.first.longitude, points.first.latitude]);
    return {'type': 'Polygon', 'coordinates': [coords]};
  }

  // ── Forest helpers ─────────────────────────────────────────────────────────
  List<LatLng> get forestPolygon {
    if (selectedForest == null) return [];
    try {
      final coords = selectedForest!['geom']['coordinates'][0] as List;
      return coords
          .map<LatLng>((c) => LatLng(c[1] as double, c[0] as double))
          .toList();
    } catch (_) {
      return [];
    }
  }

  LatLng get mapCenter {
    final pts = forestPolygon;
    if (pts.isEmpty) return const LatLng(33.8, 9.5);
    final lat =
        pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
    final lng =
        pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;
    return LatLng(lat, lng);
  }

  // ── Save ───────────────────────────────────────────────────────────────────
  Future<void> savePartition() async {
    if (nameController.text.trim().isEmpty) {
      _snack('Please enter a partition name');
      return;
    }
    if (selectedForestId == null) {
      _snack('Please select a forest');
      return;
    }
    if (polygonPoints.length < 3) {
      _snack('Draw at least 3 points');
      return;
    }

    setState(() => isSaving = true);
    try {
      await ApiService.createPartition({
        'nom': nameController.text.trim(),
        'superficie': 0,
        'geom': polygonToGeoJSON(polygonPoints),
        'foret_id': selectedForest!['id'],
        //'agent_id': null,
      });
      _snack('Partition saved', success: true);
      nameController.clear();
      clearPoints();
      await loadPartitions();
      setState(() => view = 'list'); // go back to list after saving
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  // ── Delete / Edit ──────────────────────────────────────────────────────────
  Future<void> deletePartition(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Partition'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.deletePartition(id);
      _snack('Deleted', success: true);
      loadPartitions();
    } catch (_) {
      _snack('Failed to delete');
    }
  }

  Future<void> editPartition(Map<String, dynamic> partition) async {
    final ctrl =
        TextEditingController(text: partition['nom'] as String? ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Partition'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
              labelText: 'Name', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.updatePartition(
          partition['id'] as String, {'nom': ctrl.text.trim()});
      _snack('Updated', success: true);
      loadPartitions();
    } catch (_) {
      _snack('Failed to update');
    }
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green : null,
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // When opened from sidebar (no pre-selected forest), show full Scaffold
    // When opened from forests screen, it's already inside a Navigator push
    final isStandalone = widget.forest == null;

    final body = Column(
      children: [
        // ── Forest selector + view toggle ──────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedForestId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Forest',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: forests
                      .map((f) => DropdownMenuItem<String>(
                          value: f['id']?.toString(),
                          child: Text(f['nom'] as String)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    selectedForestId = v;
                    polygonPoints.clear();
                    redoStack.clear();
                  }),
                ),
              ),
              const SizedBox(width: 10),
              // Toggle between list and draw
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: 'list',
                      icon: Icon(Icons.list),
                      label: Text('List')),
                  ButtonSegment(
                      value: 'draw',
                      icon: Icon(Icons.draw),
                      label: Text('Draw')),
                ],
                selected: {view},
                onSelectionChanged: (s) =>
                    setState(() => view = s.first),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ── Main content ───────────────────────────────────────────
        Expanded(
          child: view == 'list' ? _buildList() : _buildDraw(),
        ),
      ],
    );

    if (!isStandalone) {
      // Came from forests screen — wrapped in Scaffold with AppBar
      return Scaffold(
        appBar: AppBar(
          title: Text(
              '${widget.forest!['nom'] as String? ?? 'Forest'} — Partitions'),
        ),
        body: body,
      );
    }

    // Opened from sidebar — no AppBar needed (dashboard provides it)
    return Padding(padding: EdgeInsets.zero, child: body);
  }

  // ── List view ──────────────────────────────────────────────────────────────
  Widget _buildList() {
    final parts = forestPartitions;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Text(
                selectedForest == null
                    ? 'Select a forest above'
                    : '${parts.length} partition${parts.length == 1 ? '' : 's'}',
                style:
                    const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const Spacer(),
              if (selectedForest != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create Partition'),
                  onPressed: () => setState(() {
                    view = 'draw';
                    polygonPoints.clear();
                    redoStack.clear();
                    nameController.clear();
                  }),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: selectedForest == null
                ? const Center(
                    child: Text('No forest selected',
                        style: TextStyle(color: Colors.grey)))
                : parts.isEmpty
                    ? const Center(
                        child: Text('No partitions yet.',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        itemCount: parts.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final p = parts[i];
                          final color = _colorForIndex(i);
                          final name =
                              p['nom'] as String? ?? 'Partition ${i + 1}';
                          final sup = p['superficie'];
                          final supText = sup != null
                              ? '${(sup as num).toStringAsFixed(2)} km²'
                              : '— km²';

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  // Colored index badge
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      border: Border.all(
                                          color: color, width: 2),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text('${i + 1}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                              fontSize: 16)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15)),
                                        const SizedBox(height: 3),
                                        Row(children: [
                                          const Icon(Icons.straighten,
                                              size: 13,
                                              color: Colors.grey),
                                          const SizedBox(width: 3),
                                          Text(supText,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey)),
                                        ]),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        color: Colors.blue),
                                    tooltip: 'Edit',
                                    onPressed: () => editPartition(p),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    tooltip: 'Delete',
                                    onPressed: () => deletePartition(
                                        p['id'] as String),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ── Draw view ──────────────────────────────────────────────────────────────
  Widget _buildDraw() {
    final parts = forestPartitions;

    return Column(
      children: [
        // Partition name field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Partition name',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Map
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: mapCenter,
              initialZoom: selectedForest != null ? 13 : 7,
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
                  // Forest boundary — blue
                  if (forestPolygon.isNotEmpty)
                    Polygon(
                      points: forestPolygon,
                      color: Colors.blue.withValues(alpha: 0.10),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 2.5,
                    ),

                  // Existing partitions — each a different color
                  ...parts.asMap().entries.map((e) {
                    final i = e.key;
                    final p = e.value;
                    final color = _colorForIndex(i);
                    final coords = p['geom']['coordinates'][0] as List;
                    final pts = coords
                        .map<LatLng>(
                            (c) => LatLng(c[1] as double, c[0] as double))
                        .toList();
                    return Polygon(
                      points: pts,
                      color: color.withValues(alpha: 0.30),
                      borderColor: color,
                      borderStrokeWidth: 2,
                    );
                  }),

                  // Currently drawing — green
                  if (polygonPoints.length >= 2)
                    Polygon(
                      points: polygonPoints,
                      color: Colors.green.withValues(alpha: 0.35),
                      borderColor: Colors.green,
                      borderStrokeWidth: 3,
                    ),
                ],
              ),
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

        // Legend
        if (parts.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _legendItem(Colors.blue, 'Forest boundary'),
                const SizedBox(width: 10),
                ...parts.asMap().entries.map((e) {
                  final name =
                      e.value['nom'] as String? ?? 'P${e.key + 1}';
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _legendItem(_colorForIndex(e.key), name),
                  );
                }),
                _legendItem(Colors.green, 'New'),
              ],
            ),
          ),

        // Controls
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _btn(Icons.undo, 'Undo',
                  polygonPoints.isNotEmpty ? undoPoint : null),
              _btn(Icons.redo, 'Redo',
                  redoStack.isNotEmpty ? redoPoint : null),
              _btn(Icons.delete_outline, 'Clear',
                  polygonPoints.isNotEmpty ? clearPoints : null,
                  color: Colors.red),
              _btn(Icons.save, isSaving ? 'Saving…' : 'Save',
                  isSaving ? null : savePartition,
                  color: Colors.green),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.4),
              border: Border.all(color: color, width: 1.5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      );

  Widget _btn(IconData icon, String label, VoidCallback? onPressed,
      {Color? color}) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: color,
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onPressed: onPressed,
    );
  }
}