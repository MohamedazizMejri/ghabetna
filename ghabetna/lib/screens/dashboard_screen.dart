import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import 'users_screen.dart';
import 'forests_screen.dart';
import 'partitions_screen.dart';
import 'assign_supervisor_screen.dart';
import 'assign_agent_screen.dart';
import '../services/api_service.dart';
/*class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}*/
/*class DashboardScreen extends StatefulWidget  {

  final Map user;

  const DashboardScreen({super.key, required this.user});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
  
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome ${user["email"]}"),
      ),
      body: const Center(
        child: Text("Admin Dashboard"),
      ),
    );
  }
}

class _DashboardScreenState extends State<DashboardScreen> {

  int selectedIndex = 0;

  final pages = [
    const Center(child: Text("Dashboard")),
    const UsersScreen(),
    const ForestsScreen(),
    const PartitionsScreen(),
  ];

  void changePage(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [

          Sidebar(onMenuSelected: changePage),

          Expanded(
            child: pages[selectedIndex],
          ),
        ],
      ),
    );
  }
}*/


class DashboardScreen extends StatefulWidget {

  final Map user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  int selectedIndex = 0;

  late final List<Widget> pages;

  Map<String, dynamic> stats = {};

  @override
  void initState() {
    super.initState();

    pages = [
      /*Center(child: Text("Welcome ${widget.user["email"]}")),*/
      //buildStatsGrid(),
      Container(),
      //MapScreen(),
      const UsersScreen(),
      ForestsScreen(user: widget.user), 
      AssignSupervisorScreen(),
      const PartitionsScreen(),
      AssignAgentScreen(),
    ];
    loadStats();
  }

  Future<void> loadStats() async {
    try {
      final data = await ApiService.getStats();
      setState(() {
        stats = data;
        pages[0] = buildStatsGrid(); // Update the grid when stats loaded
      });
    } catch (e) {
      print("Error loading stats: $e");
    }
  }

  Widget buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        children: [
          buildCard("Admins", stats["admins"] ?? 0, Icons.admin_panel_settings, Colors.red),
          buildCard("Supervisors", stats["supervisors"] ?? 0, Icons.supervisor_account, Colors.blue),
          buildCard("Agents", stats["agents"] ?? 0, Icons.person, Colors.green),
          buildCard("Forests", stats["forests"] ?? 0, Icons.park, Colors.teal),
          buildCard("Partitions", stats["partitions"] ?? 0, Icons.map, Colors.orange),
        ],
      ),
    );
  }

  Widget buildCard(String title, int value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(2, 2),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 10),
          Text(
            "$value",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  void changePage(int index) {
    setState(() {
      selectedIndex = index;
    });
    if (index == 0) {
      loadStats(); 
    }
    
  }
void _logout(BuildContext context) {
  // Optionally, clear any stored token/session here
  // e.g., using SharedPreferences or any global variable

  // Navigate back to login screen
  Navigator.pushReplacementNamed(context, '/login');
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard - ${widget.user["email"]}"),
        actions: [
        IconButton(
          icon: Icon(Icons.logout),
          tooltip: "Log Out",
          onPressed: () {
            _logout(context);
          },
        ),
      ],
      ),
      body: Row(
        children: [

          Sidebar(onMenuSelected: changePage),

          Expanded(
            /*child: pages[selectedIndex],*/ 
            child: selectedIndex == 0
            ? buildStatsGrid() 
            : pages[selectedIndex],
          ),
        ],
      ),
    );
  }
}