import 'package:flutter/material.dart';
import '../../services/api_service.dart';

const _kGreen     = Color(0xFF2D6A4F);
const _kAccent    = Color(0xFF74C69D);
const _kSurface   = Color(0xFFF6F8F6);
const _kBorder    = Color(0xFFE2E8E4);
const _kTextHead  = Color(0xFF1A2E25);
const _kTextSub   = Color(0xFF6B7C74);

class SupervisorProfileScreen extends StatefulWidget {
  final Map user;
  final bool embedded;
  const SupervisorProfileScreen({super.key, required this.user, this.embedded = false});

  @override
  State<SupervisorProfileScreen> createState() => _SupervisorProfileScreenState();
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
      setState(() { profile = p; forests = f; });
    } catch (e) {
      if (e.toString().contains('PROFILE_NOT_CACHED')) {
        final userId = widget.user['id'] ?? ApiService.userId;
        if (userId != null) {
          await ApiService.syncUserCache(userId);
          await _loadProfile();
          return;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _bodyContent() {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: _kGreen));
    if (profile == null) return const Center(child: Text('No profile found'));

    final initials = [profile!['prenom'], profile!['nom']]
        .where((v) => v != null && v.toString().isNotEmpty)
        .map((v) => v.toString()[0].toUpperCase())
        .join();

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: _kGreen,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Avatar card ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: _kGreen,
                  child: Text(initials.isEmpty ? 'S' : initials,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 20),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${profile!["prenom"] ?? ""} ${profile!["nom"] ?? ""}'.trim(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kTextHead)),
                  const SizedBox(height: 4),
                  Text(profile!['email'] ?? '',
                      style: const TextStyle(fontSize: 13, color: _kTextSub)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF8F2), borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFB2DFC8)),
                    ),
                    child: const Text('Supervisor', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kGreen)),
                  ),
                ]),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Personal info ────────────────────────────────────────────
          _Section(
            title: 'Personal Information',
            icon: Icons.person_outline,
            child: Column(
              children: [
                _InfoRow(label: 'First Name', value: profile!['prenom'] ?? '—'),
                _InfoRow(label: 'Last Name',  value: profile!['nom']    ?? '—'),
                _InfoRow(label: 'Email',      value: profile!['email']  ?? '—'),
                _InfoRow(label: 'Phone',      value: profile!['numtel'] ?? '—'),
                _InfoRow(label: 'CIN',        value: profile!['cin']    ?? '—', last: true),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Forests ──────────────────────────────────────────────────
          _Section(
            title: 'Supervised Forests (${forests.length})',
            icon: Icons.park_outlined,
            child: forests.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No forests assigned yet', style: TextStyle(color: _kTextSub)),
                  )
                : Column(
                    children: forests.asMap().entries.map((entry) {
                      final f = entry.value;
                      final isLast = entry.key == forests.length - 1;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(children: [
                              Container(
                                width: 34, height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEBF8F2), borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.forest, size: 18, color: _kGreen),
                              ),
                              const SizedBox(width: 12),
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(f['forest_nom'] ?? 'Unnamed',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kTextHead)),
                                Text('ID: ${f["forest_id"]}',
                                    style: const TextStyle(fontSize: 11, color: _kTextSub)),
                              ]),
                            ]),
                          ),
                          if (!isLast) const Divider(height: 1, color: _kBorder),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Container(color: _kSurface, child: _bodyContent());
    }
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Profile',
            style: TextStyle(color: _kTextHead, fontWeight: FontWeight.w600, fontSize: 16)),
        iconTheme: const IconThemeData(color: _kTextHead),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: _bodyContent(),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Section({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: _kGreen),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kTextHead)),
          ]),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _kBorder),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;
  const _InfoRow({required this.label, required this.value, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            SizedBox(width: 110,
                child: Text(label, style: const TextStyle(fontSize: 13, color: _kTextSub))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kTextHead))),
          ]),
        ),
        if (!last) const Divider(height: 1, color: _kBorder),
      ],
    );
  }
}