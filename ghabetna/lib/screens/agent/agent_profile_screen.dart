import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AgentProfileScreen extends StatefulWidget {
  final Map user; // user data from login (has "id" field)

  const AgentProfileScreen({super.key, required this.user});

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> {
  Map<String, dynamic>? profile;
  List parcelles = [];
  bool isLoading = true;
  bool isEditing = false;

  late TextEditingController numtelController;

  @override
  void initState() {
    super.initState();
    numtelController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    numtelController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);
    try {
      final p = await ApiService.getMyProfile();
      final parc = await ApiService.getMyParcelles();
      setState(() {
        profile = p;
        parcelles = parc;
        numtelController.text = p["numtel"] ?? "";
      });
    } catch (e) {
      if (e.toString().contains("PROFILE_NOT_CACHED")) {
        // Bootstrap: push the profile from admin-service to cache
        final userId = (widget.user["id"] ?? widget.user["user_id"] ?? ApiService.userId) as String?;
        if (userId != null) {
          await ApiService.syncUserCache(userId);
          await _loadProfile(); // retry
          return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading profile: $e")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    try {
      await ApiService.updateMyProfile({"numtel": numtelController.text});
      setState(() {
        profile!["numtel"] = numtelController.text;
        isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => isEditing = true),
            ),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveProfile,
            ),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                numtelController.text = profile?["numtel"] ?? "";
                setState(() => isEditing = false);
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
              ? const Center(child: Text("No profile found"))
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // ─── Avatar ───
                      const CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.green,
                        child: Icon(Icons.person, size: 50, color: Colors.white),
                      ),
                      const SizedBox(height: 20),

                      // ─── Info Card ───
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Personal Information",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const Divider(),
                              _infoRow("First Name", profile!["prenom"] ?? ""),
                              _infoRow("Last Name", profile!["nom"] ?? ""),
                              _infoRow("Email", profile!["email"] ?? ""),
                              _infoRow("CIN", profile!["cin"] ?? ""),
                              const SizedBox(height: 8),
                              // Editable phone
                              isEditing
                                  ? TextFormField(
                                      controller: numtelController,
                                      decoration: const InputDecoration(
                                        labelText: "Phone",
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.phone,
                                    )
                                  : _infoRow("Phone", profile!["numtel"] ?? ""),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ─── Parcelles Card ───
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.forest, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Assigned Forest Parcels (${parcelles.length})",
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const Divider(),
                              parcelles.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        "No parcels assigned yet",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  : Column(
                                      children: parcelles.map((p) {
                                        return ListTile(
                                          leading: const Icon(
                                              Icons.crop_square,
                                              color: Colors.green),
                                          title: Text(
                                              p["partition_nom"] ?? "Unnamed"),
                                          subtitle: Text(
                                              "ID: ${p["partition_id"]}",
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey)),
                                        );
                                      }).toList(),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}