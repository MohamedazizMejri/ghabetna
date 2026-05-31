import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../services/incident_service.dart';
import '../../services/api_service.dart';
import 'supervisor_incident_detail_screen.dart';

const _kGreen      = Color(0xFF2D6A4F);
const _kGreenLight = Color(0xFF40916C);
const _kAccent     = Color(0xFF74C69D);
const _kSurface    = Color(0xFFF6F8F6);
const _kBorder     = Color(0xFFE2E8E4);
const _kTextHead   = Color(0xFF1A2E25);
const _kTextSub    = Color(0xFF6B7C74);

class SupervisorMapScreen extends StatefulWidget {
  /// When true the widget is embedded inside SupervisorScreen (no Scaffold/AppBar).
  final bool embedded;
  const SupervisorMapScreen({super.key, this.embedded = false});

  @override
  State<SupervisorMapScreen> createState() => _SupervisorMapScreenState();
}

class _SupervisorMapScreenState extends State<SupervisorMapScreen> {
  List incidents       = [];
  List<_ForestPolygon> myForests = [];
  bool isLoading       = true;
  bool _isSatellite    = false;
  final MapController _mapController = MapController();

  // ── Tile sources ────────────────────────────────────────────────────────
  static const _osmUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const _satelliteUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  /// Loads supervisor's forest polygons + filtered incidents in parallel.
  Future<void> _loadAll() async {
    setState(() => isLoading = true);
    try {
      // 1. My forest IDs (from cache — fast, no geom)
      final myForestRefs  = await ApiService.getMyForests();
      final myForestIds   = myForestRefs
          .map((f) => f['forest_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      // 2. All forests with geom — filter to mine
      final allForests    = await ApiService.getForests();
      final polygons      = <_ForestPolygon>[];

      for (final f in allForests) {
        final fid = f['id']?.toString() ?? '';
        if (!myForestIds.contains(fid)) continue;

        try {
          final coords = f['geom']['coordinates'][0] as List;
          final points = coords.map<LatLng>((c) => LatLng(c[1] as double, c[0] as double)).toList();
          polygons.add(_ForestPolygon(
            id:     fid,
            name:   f['nom']?.toString() ?? 'Forest',
            points: points,
          ));
        } catch (_) {
          // skip malformed geom
        }
      }

      // 3. Incidents filtered to my forests
      final allIncidents  = await IncidentService.getAllIncidents();
      final filtered      = myForestIds.isEmpty
          ? <dynamic>[]
          : allIncidents.where((i) {
              final fid = i['foret_id']?.toString() ?? '';
              return myForestIds.contains(fid);
            }).toList();

      setState(() {
        myForests = polygons;
        incidents = filtered;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('_loadAll error: $e');
      setState(() => isLoading = false);
    }
  }

  // ── Marker helpers ───────────────────────────────────────────────────────
  Color _statusColor(String? status) {
    switch (status) {
      case 'accepted': return const Color(0xFF40916C);
      case 'rejected': return const Color(0xFFE63946);
      default:         return const Color(0xFFF4A261);
    }
  }

  Widget _markerIcon(dynamic incident) {
    final bool isCritical = incident['severity'] == true;
    final Color pinColor  = _statusColor(incident['status']?.toString());

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.location_on, color: pinColor, size: 36),
        if (isCritical)
          Positioned(
            top: -2, right: -2,
            child: Container(
              width: 16, height: 16,
              decoration: const BoxDecoration(color: Color(0xFFE63946), shape: BoxShape.circle),
              child: const Center(
                child: Text('!',
                    style: TextStyle(color: Colors.white, fontSize: 10,
                        fontWeight: FontWeight.w900, height: 1)),
              ),
            ),
          ),
      ],
    );
  }

  List<Marker> _buildMarkers() {
    return incidents.map<Marker>((incident) {
      return Marker(
        width: 44, height: 44,
        point: LatLng(
          (incident['latitude']  as num).toDouble(),
          (incident['longitude'] as num).toDouble(),
        ),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => IncidentDetailScreen(incidentId: incident['id'].toString()),
              ),
            ).then((_) => _loadAll());
          },
          child: _markerIcon(incident),
        ),
      );
    }).toList();
  }

  // ── Forest polygons ──────────────────────────────────────────────────────
  List<Polygon> _buildPolygons() {
    return myForests.map((f) {
      return Polygon(
        points:            f.points,
        color:             const Color(0xFFE63946).withValues(alpha: 0.18),
        borderColor:       const Color(0xFFE63946),
        borderStrokeWidth: 2.2,
      );
    }).toList();
  }

  // ── Map body ─────────────────────────────────────────────────────────────
  Widget _mapBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kGreen));
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(36.8, 10.1),
            initialZoom: 10,
          ),
          children: [
            TileLayer(
              urlTemplate:         _isSatellite ? _satelliteUrl : _osmUrl,
              userAgentPackageName: 'com.example.app',
              subdomains:          const [],
            ),
            // ── My forest polygons (below markers) ──
            if (myForests.isNotEmpty)
              PolygonLayer(polygons: _buildPolygons()),
            MarkerLayer(markers: _buildMarkers()),
          ],
        ),

        // ── Layer toggle (top-left) ──────────────────────────────────
        Positioned(
          left: 16, top: 16,
          child: GestureDetector(
            onTap: () => setState(() => _isSatellite = !_isSatellite),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:  _isSatellite ? const Color(0xFF1A2E25) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 10)],
                border: Border.all(color: _isSatellite ? _kGreenLight : _kBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isSatellite ? Icons.map_outlined : Icons.satellite_alt,
                    size: 16,
                    color: _isSatellite ? _kAccent : _kTextHead,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _isSatellite ? 'Street view' : 'Satellite',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: _isSatellite ? Colors.white : _kTextHead,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Refresh (top-right) ──────────────────────────────────────
        Positioned(
          right: 16, top: 16,
          child: _MapBtn(icon: Icons.refresh_rounded, onPressed: _loadAll),
        ),

        // ── Zoom controls (right) ────────────────────────────────────
        Positioned(
          right: 16, bottom: 90,
          child: Column(
            children: [
              _MapBtn(
                icon: Icons.add,
                onPressed: () => _mapController.move(
                    _mapController.camera.center, _mapController.camera.zoom + 1),
              ),
              const SizedBox(height: 6),
              _MapBtn(
                icon: Icons.remove,
                onPressed: () => _mapController.move(
                    _mapController.camera.center, _mapController.camera.zoom - 1),
              ),
            ],
          ),
        ),

        // ── Legend (bottom-left) ─────────────────────────────────────
        Positioned(
          left: 16, bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10)],
              border: Border.all(color: _kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Forest polygon legend entry
                if (myForests.isNotEmpty) ...[
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 18, height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE63946).withValues(alpha: 0.18),
                        border: Border.all(color: const Color(0xFFE63946), width: 1.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('My forests', style: TextStyle(fontSize: 12, color: _kTextSub)),
                  ]),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: _kBorder),
                  const SizedBox(height: 8),
                ],
                // Incident status dots
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LegendDot(color: const Color(0xFF40916C), label: 'Accepted'),
                    const SizedBox(width: 14),
                    _LegendDot(color: const Color(0xFFF4A261), label: 'Pending'),
                    const SizedBox(width: 14),
                    _LegendDot(color: const Color(0xFFE63946), label: 'Rejected'),
                    const SizedBox(width: 14),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 16, height: 16,
                        decoration: const BoxDecoration(color: Color(0xFFE63946), shape: BoxShape.circle),
                        child: const Center(
                          child: Text('!',
                              style: TextStyle(color: Colors.white, fontSize: 9,
                                  fontWeight: FontWeight.w900, height: 1)),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text('Critical', style: TextStyle(fontSize: 12, color: _kTextSub)),
                    ]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _mapBody();

    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Map Overview',
            style: TextStyle(color: _kTextHead, fontWeight: FontWeight.w600, fontSize: 16)),
        iconTheme: const IconThemeData(color: _kTextHead),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: _mapBody(),
    );
  }
}

// ── Data model ───────────────────────────────────────────────────────────────
class _ForestPolygon {
  final String id;
  final String name;
  final List<LatLng> points;
  const _ForestPolygon({required this.id, required this.name, required this.points});
}

// ── Reusable map button ───────────────────────────────────────────────────────
class _MapBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _MapBtn({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      shadowColor: const Color(0x22000000),
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: SizedBox(
          width: 38, height: 38,
          child: Icon(icon, size: 20, color: _kTextHead),
        ),
      ),
    );
  }
}

// ── Legend dot ────────────────────────────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 12, color: _kTextSub)),
    ]);
  }
}