import 'package:flutter/material.dart';
import 'supervisor_map_screen.dart';
import 'supervisor_incidents_screen.dart';
import 'supervisor_profile_screen.dart';

// ── Design tokens ──────────────────────────────────────────────────────────
const _kGreen     = Color(0xFF2D6A4F);
const _kGreenLight= Color(0xFF40916C);
const _kAccent    = Color(0xFF74C69D);
const _kSurface   = Color(0xFFF6F8F6);
const _kBorder    = Color(0xFFE2E8E4);
const _kTextHead  = Color(0xFF1A2E25);
const _kTextSub   = Color(0xFF6B7C74);
const _kSidebarW  = 230.0;

// ── Route indices ──────────────────────────────────────────────────────────
enum _NavItem { map, incidents, profile, logout }

class SupervisorScreen extends StatefulWidget {
  final Map user;
  const SupervisorScreen({super.key, required this.user});

  @override
  State<SupervisorScreen> createState() => _SupervisorScreenState();
}

class _SupervisorScreenState extends State<SupervisorScreen> {
  _NavItem _selected = _NavItem.map; // default: show map first

  String get _userName =>
      '${widget.user["prenom"] ?? ""} ${widget.user["nom"] ?? ""}'.trim();
  String get _userEmail => widget.user["email"] ?? "";

  Widget _buildContent() {
    switch (_selected) {
      case _NavItem.map:
        return const SupervisorMapScreen(embedded: true);
      case _NavItem.incidents:
        return const SupervisorIncidentsScreen(embedded: true);
      case _NavItem.profile:
        return SupervisorProfileScreen(user: widget.user, embedded: true);
      case _NavItem.logout:
        return const SizedBox.shrink();
    }
  }

  String get _pageTitle {
    switch (_selected) {
      case _NavItem.map:        return 'Map Overview';
      case _NavItem.incidents:  return 'Incidents';
      case _NavItem.profile:    return 'My Profile';
      case _NavItem.logout:     return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────────
          _Sidebar(
            selected: _selected,
            userName: _userName.isEmpty ? 'Supervisor' : _userName,
            userEmail: _userEmail,
            onSelect: (item) {
              if (item == _NavItem.logout) {
                Navigator.pushReplacementNamed(context, '/login');
                return;
              }
              setState(() => _selected = item);
            },
          ),

          // ── Main content ─────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                _TopBar(title: _pageTitle),
                // Page body
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar ────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final _NavItem selected;
  final String userName;
  final String userEmail;
  final void Function(_NavItem) onSelect;

  const _Sidebar({
    required this.selected,
    required this.userName,
    required this.userEmail,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kSidebarW,
      decoration: const BoxDecoration(
        color: _kGreen,
        boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.forest, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Ghabetna',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // Nav items
          _NavTile(icon: Icons.map_outlined,        label: 'Map',       item: _NavItem.map,       selected: selected, onTap: onSelect),
          _NavTile(icon: Icons.warning_amber_rounded,label: 'Incidents', item: _NavItem.incidents, selected: selected, onTap: onSelect),
          _NavTile(icon: Icons.person_outline,       label: 'Profile',   item: _NavItem.profile,   selected: selected, onTap: onSelect),

          const Spacer(),

          // User info + logout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _kAccent.withValues(alpha: 0.35),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(userEmail,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Logout button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: GestureDetector(
              onTap: () => onSelect(_NavItem.logout),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, size: 16, color: Colors.white.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Text('Logout',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final _NavItem item;
  final _NavItem selected;
  final void Function(_NavItem) onTap;

  const _NavTile({
    required this.icon, required this.label, required this.item,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selected == item;
    return GestureDetector(
      onTap: () => onTap(item),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.13) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18,
                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6)),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.65),
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                )),
            if (isActive) ...[
              const Spacer(),
              Container(
                width: 5, height: 5,
                decoration: const BoxDecoration(color: _kAccent, shape: BoxShape.circle),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: _kTextHead)),
        ],
      ),
    );
  }
}