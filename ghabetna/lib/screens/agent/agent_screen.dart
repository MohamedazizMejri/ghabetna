import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'my_incidents_screen.dart';
import 'create_incident_screen.dart';
import 'agent_profile_screen.dart';

class AgentScreen extends StatefulWidget {
  final Map user;

  const AgentScreen({super.key, required this.user});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  // ── Theme ──────────────────────────────────────────────────────────────────
  static const _bg = Color(0xFFF7F7F5);
  static const _ink = Color(0xFF111111);
  static const _muted = Color(0xFF888888);
  static const _accent = Color(0xFF2D6A3F); // forest green
  static const _surface = Colors.white;
  static const _divider = Color(0xFFE8E8E6);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String get _firstName {
    final prenom = widget.user['prenom'];
    final email = widget.user['email'] as String?;
    if (prenom != null && prenom.toString().isNotEmpty) {
      return prenom.toString();
    }
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'Agent';
  }

  String get _initials {
    final prenom = widget.user['prenom']?.toString() ?? '';
    final nom = widget.user['nom']?.toString() ?? '';
    final f = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final l = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return '$f$l'.isNotEmpty ? '$f$l' : 'A';
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: FadeTransition(
            opacity: _animController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    children: [
                      const SizedBox(height: 32),
                      _buildSectionLabel('Actions'),
                      const SizedBox(height: 12),
                      _ActionTile(
                        label: 'Report Incident',
                        description: 'Submit a new forest incident',
                        icon: Icons.add_circle_outline_rounded,
                        accent: _accent,
                        onTap: () => _push(context, const CreateIncidentScreen()),
                      ),
                      _ActionTile(
                        label: 'My Incidents',
                        description: 'View your submitted reports',
                        icon: Icons.list_alt_rounded,
                        accent: _ink,
                        onTap: () => _push(context, const MyIncidentsScreen()),
                      ),
                      _ActionTile(
                        label: 'Profile',
                        description: 'Your account information',
                        icon: Icons.person_outline_rounded,
                        accent: _ink,
                        onTap: () =>
                            _push(context, AgentProfileScreen(user: widget.user)),
                      ),
                      const SizedBox(height: 32),
                      _buildSectionLabel('Account'),
                      const SizedBox(height: 12),
                      _ActionTile(
                        label: 'Log Out',
                        description: 'End your current session',
                        icon: Icons.logout_rounded,
                        accent: const Color(0xFFCC3333),
                        onTap: () => _showLogout(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _muted,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _firstName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () =>
                _push(context, AgentProfileScreen(user: widget.user)),
            child: _Avatar(initials: _initials, size: 42),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _muted,
        letterSpacing: 1.2,
      ),
    );
  }

  void _push(BuildContext ctx, Widget page) {
    Navigator.push(
      ctx,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  void _showLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _MinimalDialog(
        title: 'Log out?',
        body: 'You will be returned to the login screen.',
        confirmLabel: 'Log out',
        isDestructive: true,
        onConfirm: () {
          Navigator.pop(ctx);
          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, required this.size});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF2D6A3F),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatefulWidget {
  const _ActionTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          margin: const EdgeInsets.only(bottom: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 22, color: widget.accent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: widget.accent == const Color(0xFFCC3333)
                            ? const Color(0xFFCC3333)
                            : const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFCCCCCC),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MinimalDialog extends StatelessWidget {
  const _MinimalDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
    this.isDestructive = false,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF888888),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onConfirm,
                  child: Text(
                    confirmLabel,
                    style: TextStyle(
                      color: isDestructive
                          ? const Color(0xFFCC3333)
                          : const Color(0xFF2D6A3F),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}