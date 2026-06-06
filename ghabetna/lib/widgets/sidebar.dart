import 'package:flutter/material.dart';

class Sidebar extends StatefulWidget {
  final Function(int) onMenuSelected;
  final int selectedIndex;
  final Map<String, dynamic>? user;

  const Sidebar({
    super.key,
    required this.onMenuSelected,
    this.selectedIndex = 0,
    this.user,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  static const _primaryGreen = Color(0xFF1B5E20);
  static const _accentGreen = Color(0xFF2E7D32);
  static const _hoverGreen = Color(0xFF388E3C);
  static const _activeGreen = Color(0xFF43A047);
  static const _textLight = Color(0xFFE8F5E9);
  static const _textMuted = Color(0xFFA5D6A7);

  final List<_NavItem> _items = const [
    _NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, index: 0),
    _NavItem(label: 'Users', icon: Icons.people_alt_rounded, index: 1),
    _NavItem(label: 'Forests', icon: Icons.park_rounded, index: 2),
    _NavItem(label: 'Assign Supervisor', icon: Icons.manage_accounts_rounded, index: 3),
    _NavItem(label: 'Partitions', icon: Icons.map_rounded, index: 4),
    _NavItem(label: 'Assign Agent', icon: Icons.person_pin_rounded, index: 5),
  ];

  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A3A1A), Color(0xFF0D2B0D)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 12,
            offset: Offset(3, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          _buildDivider(),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _items
                  .map((item) => _buildNavItem(item))
                  .toList(),
            ),
          ),
          _buildDivider(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _activeGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.forest_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ghabetna',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                'Admin Panel',
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(_NavItem item) {
    final isActive = widget.selectedIndex == item.index;
    final isHovered = _hoveredIndex == item.index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = item.index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () => widget.onMenuSelected(item.index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isActive
                ? _activeGreen.withValues(alpha: 0.25)
                : isHovered
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(
                color: isActive ? _activeGreen : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 20,
                color: isActive
                    ? const Color(0xFF81C784)
                    : const Color(0xFF6D9B6D),
              ),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFFB0C4B0),
                  fontSize: 13.5,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  Widget _buildFooter() {
    final email = widget.user?['email'] as String? ?? 'Admin';
    final initials = email.isNotEmpty ? email[0].toUpperCase() : 'A';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _activeGreen,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  email.length > 18 ? '${email.substring(0, 16)}…' : email,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final int index;
  const _NavItem({required this.label, required this.icon, required this.index});
}