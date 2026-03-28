import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
  
}

class _MapScreenState extends State<MapScreen> {
  List<List<LatLng>> forests = [];

  @override
  void initState() {
    super.initState();
    loadForests();
  }

  Future<void> loadForests() async {
    try {
      final data = await ApiService.getForests();

      List<List<LatLng>> loaded = [];

      for (var forest in data) {
        final coords = forest["geom"]["coordinates"][0];

        List<LatLng> polygon = coords.map<LatLng>((c) {
          return LatLng(c[1], c[0]); // lat, lng
        }).toList();

        loaded.add(polygon);
      }

      setState(() {
        forests = loaded;
      });

    } catch (e) {
      print("Error loading forests: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(36.8, 10.1),
        initialZoom: 8,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: "com.example.app",
        ),

        PolygonLayer(
          polygons: forests.map((points) {
            return Polygon(
              points: points,
              color: Colors.blue.withValues(alpha: 0.3),
              borderColor: Colors.blue,
              borderStrokeWidth: 2,
            );
          }).toList(),
        ),
      ],
    );
  }
}