import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'create_forest_screen.dart';
import 'partitions_screen.dart';


class ForestsScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const ForestsScreen({super.key, required this.user});

  @override
  State<ForestsScreen> createState() => _ForestsScreenState();
}

class _ForestsScreenState extends State<ForestsScreen> {
  List<Map<String, dynamic>> forests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadForests();
  }

  Future<void> loadForests() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getForests();
      setState(() {
        forests = data.cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _snack('Failed to load forests');
    }
  }

  Future<void> deleteForest(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Forest'),
        content: const Text('Are you sure you want to delete this forest?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService.deleteForest(id);
      _snack('Forest deleted', success: true);
      loadForests();
    } catch (e) {
      _snack('Failed to delete forest');
    }
  }

  Future<void> editForest(Map<String, dynamic> forest) async {
    final nameController =
        TextEditingController(text: forest['nom'] as String? ?? '');
    String? selectedRegion = forest['region'] as String?;

    const gouvernorats = [
      'Ariana', 'Béja', 'Ben Arous', 'Bizerte', 'Gabès', 'Gafsa',
      'Jendouba', 'Kairouan', 'Kasserine', 'Kébili', 'Le Kef', 'Mahdia',
      'La Manouba', 'Médenine', 'Monastir', 'Nabeul', 'Sfax', 'Sidi Bouzid',
      'Siliana', 'Sousse', 'Tataouine', 'Tozeur', 'Tunis', 'Zaghouan',
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Forest'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Forest name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRegion,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Region',
                  border: OutlineInputBorder(),
                ),
                items: gouvernorats
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedRegion = v),
              ),
            ],
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
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.updateForest(forest['id'] as String, {
        'nom': nameController.text.trim(),
        'region': selectedRegion,
      });
      _snack('Forest updated', success: true);
      loadForests();
    } catch (e) {
      _snack('Failed to update forest');
    }
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Forests',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Create Forest'),
                onPressed: () async {
                  final created = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CreateForestScreen(user: widget.user)),
                  );
                  if (created == true) loadForests();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : forests.isEmpty
                    ? const Center(
                        child: Text(
                          'No forests yet.\nTap "Create Forest" to add one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: loadForests,
                        child: ListView.separated(
                          itemCount: forests.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _ForestCard(
                            forest: forests[i],
                            onEdit: () => editForest(forests[i]),
                            onDelete: () =>
                                deleteForest(forests[i]['id'] as String),
                            onPartitions: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PartitionsScreen(
                                  forest: forests[i],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ForestCard extends StatelessWidget {
  final Map<String, dynamic> forest;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPartitions;

  const _ForestCard({
    required this.forest,
    required this.onEdit,
    required this.onDelete,
    required this.onPartitions,
  });

  @override
  Widget build(BuildContext context) {
    final name = forest['nom'] as String? ?? '—';
    final region = forest['region'] as String? ?? 'No region';
    final km2 = forest['superficie_km2'];
    final km2Text =
        km2 != null ? '${(km2 as num).toStringAsFixed(2)} km²' : '— km²';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.forest, color: Colors.green, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 13, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text(region,
                          style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(width: 12),
                      const Icon(Icons.straighten, size: 13, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text(km2Text,
                          style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),

            // Partitions button
            IconButton(
              icon: const Icon(Icons.grid_view_rounded, color: Colors.teal),
              tooltip: 'Partitions',
              onPressed: onPartitions,
            ),

            // Edit button
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              tooltip: 'Edit',
              onPressed: onEdit,
            ),

            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}