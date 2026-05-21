import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SupervisorProfileScreen extends StatefulWidget {
  final Map user;

  const SupervisorProfileScreen({super.key, required this.user});

  @override
  State<SupervisorProfileScreen> createState() =>
      _SupervisorProfileScreenState();
}

class _SupervisorProfileScreenState extends State<SupervisorProfileScreen> {
  Map<String, dynamic>? profile;
  List forests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);
    try {
      final p = await ApiService.getMyProfile();
      final f = await ApiService.getMyForests();
      setState(() {
        profile = p;
        forests = f;
      });
    } catch (e) {
      if (e.toString().contains("PROFILE_NOT_CACHED")) {
        final userId = widget.user["id"] ?? ApiService.userId;
        if (userId != null) {
          await ApiService.syncUserCache(userId);
          await _loadProfile();
          return;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
              ? const Center(child: Text("No profile found"))
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.supervisor_account,
                            size: 50, color: Colors.white),
                      ),
                      const SizedBox(height: 20),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Personal Information",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const Divider(),
                              _row("First Name", profile!["prenom"] ?? ""),
                              _row("Last Name", profile!["nom"] ?? ""),
                              _row("Email", profile!["email"] ?? ""),
                              _row("Phone", profile!["numtel"] ?? ""),
                              _row("CIN", profile!["cin"] ?? ""),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.park, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Supervised Forests (${forests.length})",
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const Divider(),
                              forests.isEmpty
                                  ? const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 8),
                                      child: Text("No forests assigned yet",
                                          style:
                                              TextStyle(color: Colors.grey)),
                                    )
                                  : Column(
                                      children: forests.map((f) {
                                        return ListTile(
                                          leading: const Icon(Icons.forest,
                                              color: Colors.blue),
                                          title: Text(
                                              f["forest_nom"] ?? "Unnamed"),
                                          subtitle: Text(
                                              "ID: ${f["forest_id"]}",
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

  Widget _row(String label, String value) {
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