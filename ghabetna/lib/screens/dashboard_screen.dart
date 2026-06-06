import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import 'users_screen.dart';
import 'forests_screen.dart';
import 'partitions_screen.dart';
import 'assign_supervisor_screen.dart';
import 'assign_agent_screen.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic> _stats = {};
  bool _statsLoading = true;

  // Pages are built lazily — dashboard (index 0) is rendered inline
  // so we can pass live stats without storing widget instances.
  late final Map<int, Widget> _pageCache;

  @override
  void initState() {
    super.initState();
    _pageCache = {
      1: const UsersScreen(),
      2: ForestsScreen(user: widget.user),
      3: AssignSupervisorScreen(),
      4: const PartitionsScreen(),
      5: AssignAgentScreen(),
    };
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final data = await ApiService.getStats();
      setState(() {
        _stats = data;
        _statsLoading = false;
      });
    } catch (e) {
      setState(() => _statsLoading = false);
    }
  }

  void _changePage(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) _loadStats();
  }

  void _logout() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      body: Row(
        children: [
          Sidebar(
            onMenuSelected: _changePage,
            selectedIndex: _selectedIndex,
            user: widget.user,
          ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _selectedIndex == 0
                      ? _buildDashboardView()
                      : _pageCache[_selectedIndex] ?? const SizedBox(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    const sectionTitles = [
      'Dashboard',
      'Users',
      'Forests',
      'Assign Supervisor',
      'Partitions',
      'Assign Agent',
    ];

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE8EDE8), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            sectionTitles[_selectedIndex],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B3A1B),
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          // Refresh button on dashboard
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4CAF50)),
              tooltip: 'Refresh stats',
              onPressed: _loadStats,
            ),
          const SizedBox(width: 8),
          _buildAvatarMenu(),
        ],
      ),
    );
  }

  Widget _buildAvatarMenu() {
    final email = widget.user['email'] as String? ?? '';
    final initials = email.isNotEmpty ? email[0].toUpperCase() : 'A';

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFF388E3C),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            email.length > 20 ? '${email.substring(0, 18)}…' : email,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4A6A4A),
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: Color(0xFF4A6A4A)),
        ],
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: const [
              Icon(Icons.logout_rounded, size: 18, color: Colors.red),
              SizedBox(width: 10),
              Text('Log out', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'logout') _logout();
      },
    );
  }

  Widget _buildDashboardView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeBanner(),
          const SizedBox(height: 28),
          const Text(
            'Overview',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5A7A5A),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          _buildStatsGrid(),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${widget.user["email"] ?? "Admin"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Here\'s what\'s happening across your forests today.',
                  style: TextStyle(
                    color: Color(0xFFC8E6C9),
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.forest_rounded,
            size: 56,
            color: Color(0x44FFFFFF),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final cards = [
      _StatCard(
        label: 'Admins',
        value: _stats['admins'],
        icon: Icons.admin_panel_settings_rounded,
        color: const Color(0xFFE53935),
        bgColor: const Color(0xFFFFEBEE),
      ),
      _StatCard(
        label: 'Supervisors',
        value: _stats['supervisors'],
        icon: Icons.supervisor_account_rounded,
        color: const Color(0xFF1565C0),
        bgColor: const Color(0xFFE3F2FD),
      ),
      _StatCard(
        label: 'Agents',
        value: _stats['agents'],
        icon: Icons.person_rounded,
        color: const Color(0xFF2E7D32),
        bgColor: const Color(0xFFE8F5E9),
      ),
      _StatCard(
        label: 'Forests',
        value: _stats['forests'],
        icon: Icons.park_rounded,
        color: const Color(0xFF00695C),
        bgColor: const Color(0xFFE0F2F1),
      ),
      _StatCard(
        label: 'Partitions',
        value: _stats['partitions'],
        icon: Icons.map_rounded,
        color: const Color(0xFFE65100),
        bgColor: const Color(0xFFFFF3E0),
      ),
    ];

    if (_statsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 900
            ? 5
            : constraints.maxWidth > 600
                ? 3
                : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.15,
          ),
          itemCount: cards.length,
          itemBuilder: (_, i) => _buildStatCard(cards[i]),
        );
      },
    );
  }

  Widget _buildStatCard(_StatCard card) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: card.bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(card.icon, color: card.color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${card.value ?? 0}',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: card.color,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                card.label,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF7A9A7A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard {
  final String label;
  final dynamic value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}