import 'package:flutter/material.dart';
import 'create_user_screen.dart';
import '../services/api_service.dart';
import 'edit_user_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List _allUsers = [];
  List _filtered = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _roleFilter; // null = all
  final TextEditingController _searchCtrl = TextEditingController();

  static const _roles = ['admin', 'superviseur', 'agent'];

  static const _roleColors = {
    'admin': Color(0xFFE53935),
    'superviseur': Color(0xFF1565C0),
    'agent': Color(0xFF2E7D32),
  };

  static const _roleBgColors = {
    'admin': Color(0xFFFFEBEE),
    'superviseur': Color(0xFFE3F2FD),
    'agent': Color(0xFFE8F5E9),
  };

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getUsers();
      setState(() {
        _allUsers = data;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Failed to load users');
    }
  }

  void _applyFilters() {
    final q = _searchQuery.toLowerCase();
    setState(() {
      _filtered = _allUsers.where((u) {
        final matchesRole = _roleFilter == null ||
            u['role']['type_role'] == _roleFilter;
        final matchesSearch = q.isEmpty ||
            '${u["prenom"]} ${u["nom"]}'.toLowerCase().contains(q) ||
            (u["email"] as String).toLowerCase().contains(q);
        return matchesRole && matchesSearch;
      }).toList();
    });
  }

  Future<void> _deleteUser(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ApiService.deleteUser(id);
      _loadUsers();
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ── Assignment dialogs ────────────────────────────────────────────────────

  /// Opens a checklist dialog for assigning a supervisor to forests.
  /// Shows all forests; forests already assigned to this supervisor are
  /// pre-checked.  Toggling a row assigns or unassigns on the spot.
  Future<void> _showAssignSupervisorDialog(Map user) async {
    await showDialog(
      context: context,
      builder: (_) => _AssignForestDialog(user: user),
    );
    _loadUsers(); // refresh in case assignment info changed
  }

  /// Opens a checklist dialog for assigning an agent to partitions.
  /// Shows all partitions; partitions already assigned to this agent are
  /// pre-checked.  Toggling a row assigns or unassigns on the spot.
  Future<void> _showAssignAgentDialog(Map user) async {
    await showDialog(
      context: context,
      builder: (_) => _AssignPartitionDialog(user: user),
    );
    _loadUsers();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        _buildFilterChips(),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                )
              : _filtered.isEmpty
                  ? _buildEmptyState()
                  : _buildUserList(),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by name or email…',
                  hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFFAAAAAA)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF9E9E9E)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            _searchQuery = '';
                            _applyFilters();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) {
                  _searchQuery = v;
                  _applyFilters();
                },
              ),
            ),
          ),
          const SizedBox(width: 14),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateUserScreen()),
              ).then((_) => _loadUsers());
            },
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('Add User'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: Row(
        children: [
          _FilterChip(
            label: 'All (${_allUsers.length})',
            selected: _roleFilter == null,
            color: const Color(0xFF555555),
            bgColor: const Color(0xFFF0F0F0),
            onTap: () {
              _roleFilter = null;
              _applyFilters();
            },
          ),
          const SizedBox(width: 8),
          ..._roles.map((role) {
            final count = _allUsers
                .where((u) => u['role']['type_role'] == role)
                .length;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: '${_capitalize(role)} ($count)',
                selected: _roleFilter == role,
                color: _roleColors[role]!,
                bgColor: _roleBgColors[role]!,
                onTap: () {
                  _roleFilter = _roleFilter == role ? null : role;
                  _applyFilters();
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _buildUserCard(_filtered[i]),
    );
  }

  Widget _buildUserCard(Map u) {
    final role = u['role']['type_role'] as String;
    final roleColor = _roleColors[role] ?? Colors.grey;
    final roleBg = _roleBgColors[role] ?? Colors.grey.shade100;
    final fullName = '${u["prenom"]} ${u["nom"]}';
    final initials =
        '${(u["prenom"] as String).isNotEmpty ? u["prenom"][0] : ""}${(u["nom"] as String).isNotEmpty ? u["nom"][0] : ""}'
            .toUpperCase();

    final isSupervisor = role == 'superviseur';
    final isAgent = role == 'agent';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: roleBg,
              child: Text(
                initials,
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Name + contact
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A3A1A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    u['email'] ?? '',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF7A7A7A),
                    ),
                  ),
                  if (u['numtel'] != null && u['numtel'].toString().isNotEmpty)
                    Text(
                      u['numtel'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                ],
              ),
            ),
            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: roleBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _capitalize(role),
                style: TextStyle(
                  color: roleColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Assign button — only for supervisor and agent
            if (isSupervisor || isAgent) ...[
              _ActionButton(
                icon: Icons.account_tree_rounded,
                color: const Color(0xFF6A1B9A),
                tooltip: isSupervisor ? 'Assign Forests' : 'Assign Partitions',
                onTap: () {
                  if (isSupervisor) {
                    _showAssignSupervisorDialog(u);
                  } else {
                    _showAssignAgentDialog(u);
                  }
                },
              ),
              const SizedBox(width: 4),
            ],
            // Edit
            _ActionButton(
              icon: Icons.edit_rounded,
              color: const Color(0xFF1565C0),
              tooltip: 'Edit',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditUserScreen(user: u)),
                ).then((_) => _loadUsers());
              },
            ),
            const SizedBox(width: 4),
            // Delete
            _ActionButton(
              icon: Icons.delete_outline_rounded,
              color: const Color(0xFFE53935),
              tooltip: 'Delete',
              onTap: () => _deleteUser(u['id'], fullName),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty || _roleFilter != null
                ? Icons.search_off_rounded
                : Icons.people_outline_rounded,
            size: 56,
            color: const Color(0xFFCCCCCC),
          ),
          const SizedBox(height: 14),
          Text(
            _searchQuery.isNotEmpty || _roleFilter != null
                ? 'No users match your filters'
                : 'No users yet',
            style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 15),
          ),
          if (_searchQuery.isNotEmpty || _roleFilter != null) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                _searchQuery = '';
                _roleFilter = null;
                _applyFilters();
              },
              child: const Text('Clear filters'),
            ),
          ]
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ── Assign Forest Dialog (for supervisors) ───────────────────────────────────

class _AssignForestDialog extends StatefulWidget {
  final Map user;
  const _AssignForestDialog({required this.user});

  @override
  State<_AssignForestDialog> createState() => _AssignForestDialogState();
}

class _AssignForestDialogState extends State<_AssignForestDialog> {
  List<Map<String, dynamic>> _forests = [];
  // forest id → currently assigned supervisor id
  Map<String, String?> _forestSupervisor = {};
  bool _isLoading = true;
  // tracks in-flight operations per forest id
  Set<String> _pending = {};

  String get _userId => widget.user['id'].toString();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final forests = await ApiService.getForests();
      final map = <String, String?>{};
      for (final f in forests) {
        final fMap = f as Map<String, dynamic>;
        map[fMap['id'].toString()] =
            fMap['supervised_by']?.toString();
      }
      setState(() {
        _forests = forests.cast<Map<String, dynamic>>();
        _forestSupervisor = map;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  bool _isAssignedToMe(String forestId) =>
      _forestSupervisor[forestId] == _userId;

  Future<void> _toggle(String forestId) async {
    if (_pending.contains(forestId)) return;
    setState(() => _pending.add(forestId));

    try {
      if (_isAssignedToMe(forestId)) {
        // Unassign: assign with empty/null — adapt to your API's unassign endpoint
        await ApiService.unassignSupervisor(forestId);
        setState(() => _forestSupervisor[forestId] = null);
      } else {
        await ApiService.assignSupervisor(forestId, _userId);
        setState(() => _forestSupervisor[forestId] = _userId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      setState(() => _pending.remove(forestId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = '${widget.user["prenom"]} ${widget.user["nom"]}';
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Column(
          children: [
            // Header
            _DialogHeader(
              icon: Icons.forest_rounded,
              iconColor: const Color(0xFF2E7D32),
              title: 'Assign Forests',
              subtitle: fullName,
            ),
            // Body
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
                  : _forests.isEmpty
                      ? const Center(child: Text('No forests available'))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _forests.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 16, endIndent: 16),
                          itemBuilder: (_, i) {
                            final f = _forests[i];
                            final fId = f['id'].toString();
                            final assignedTo = _forestSupervisor[fId];
                            final isMe = assignedTo == _userId;
                            final isOther = assignedTo != null && !isMe;
                            final inFlight = _pending.contains(fId);

                            return _AssignRow(
                              title: f['nom'] ?? 'Unnamed Forest',
                              subtitle: isMe
                                  ? 'Assigned to you'
                                  : isOther
                                      ? 'Assigned to another supervisor'
                                      : 'Unassigned',
                              subtitleColor: isMe
                                  ? const Color(0xFF2E7D32)
                                  : isOther
                                      ? const Color(0xFFE65100)
                                      : const Color(0xFF9E9E9E),
                              checked: isMe,
                              enabled: !isOther && !inFlight,
                              inFlight: inFlight,
                              onChanged: (_) => _toggle(fId),
                            );
                          },
                        ),
            ),
            // Footer
            _DialogFooter(onClose: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

// ── Assign Partition Dialog (for agents) ─────────────────────────────────────

class _AssignPartitionDialog extends StatefulWidget {
  final Map user;
  const _AssignPartitionDialog({required this.user});

  @override
  State<_AssignPartitionDialog> createState() => _AssignPartitionDialogState();
}

class _AssignPartitionDialogState extends State<_AssignPartitionDialog> {
  // Step 1 — forests
  List<Map<String, dynamic>> _forests = [];
  Map<String, dynamic>? _selectedForest;

  // Step 2 — partitions for the selected forest
  List<Map<String, dynamic>> _partitions = [];

  // partition id → whether THIS agent is already assigned
  Map<String, bool> _isAssignedToMe = {};

  bool _isLoadingForests = true;
  bool _isLoadingPartitions = false;
  Set<String> _pending = {};

  String get _userId => widget.user['id'].toString();

  @override
  void initState() {
    super.initState();
    _loadForests();
  }

  Future<void> _loadForests() async {
    setState(() => _isLoadingForests = true);
    try {
      final forests = await ApiService.getForests();
      setState(() {
        _forests = forests.cast<Map<String, dynamic>>();
        _isLoadingForests = false;
      });
    } catch (e) {
      setState(() => _isLoadingForests = false);
    }
  }

  Future<void> _onForestSelected(Map<String, dynamic> forest) async {
    setState(() {
      _selectedForest = forest;
      _partitions = [];
      _isAssignedToMe = {};
      _isLoadingPartitions = true;
    });

    try {
      final allPartitions = await ApiService.getPartitions();
      final forestId = forest['id'].toString();

      // Filter to only this forest's partitions
      final filtered = allPartitions
          .cast<Map<String, dynamic>>()
          .where((p) => p['foret_id'].toString() == forestId)
          .toList();

      // Build assignment map — agents is a list of {id, nom, ...}
      final assignedMap = <String, bool>{};
      for (final p in filtered) {
        final agents = (p['agents'] as List?) ?? [];
        assignedMap[p['id'].toString()] =
            agents.any((a) => a['id'].toString() == _userId);
      }

      setState(() {
        _partitions = filtered;
        _isAssignedToMe = assignedMap;
        _isLoadingPartitions = false;
      });
    } catch (e) {
      setState(() => _isLoadingPartitions = false);
    }
  }

  Future<void> _toggle(String partitionId) async {
    if (_pending.contains(partitionId)) return;
    setState(() => _pending.add(partitionId));
    try {
      if (_isAssignedToMe[partitionId] == true) {
        await ApiService.unassignAgent(partitionId, _userId);
        setState(() => _isAssignedToMe[partitionId] = false);
      } else {
        await ApiService.assignAgent(partitionId, _userId);
        setState(() => _isAssignedToMe[partitionId] = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      setState(() => _pending.remove(partitionId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = '${widget.user["prenom"]} ${widget.user["nom"]}';
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Column(
          children: [
            _DialogHeader(
              icon: Icons.map_outlined,
              iconColor: const Color(0xFF6A1B9A),
              title: 'Assign Partition',
              subtitle: fullName,
            ),
            // Forest dropdown
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: _isLoadingForests
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedForest,
                      hint: const Text('Select a forest', style: TextStyle(fontSize: 13.5)),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.forest_rounded, size: 18, color: Color(0xFF2E7D32)),
                      ),
                      items: _forests.map((f) {
                        return DropdownMenuItem(
                          value: f,
                          child: Text(f['nom'] ?? 'Unnamed Forest',
                              style: const TextStyle(fontSize: 13.5)),
                        );
                      }).toList(),
                      onChanged: (f) { if (f != null) _onForestSelected(f); },
                    ),
            ),
            const Divider(height: 1),
            // Partition list
            Expanded(
              child: _selectedForest == null
                  ? const Center(
                      child: Text('Select a forest to see its partitions',
                          style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
                    )
                  : _isLoadingPartitions
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A1B9A)))
                      : _partitions.isEmpty
                          ? const Center(
                              child: Text('No partitions in this forest',
                                  style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _partitions.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, indent: 16, endIndent: 16),
                              itemBuilder: (_, i) {
                                final p = _partitions[i];
                                final pId = p['id'].toString();
                                final assignedToMe = _isAssignedToMe[pId] == true;
                                final inFlight = _pending.contains(pId);

                                return _AssignRow(
                                  title: p['nom'] ?? 'Unnamed Partition',
                                  subtitle: assignedToMe ? 'Assigned to you' : 'Unassigned',
                                  subtitleColor: assignedToMe
                                      ? const Color(0xFF6A1B9A)
                                      : const Color(0xFF9E9E9E),
                                  checked: assignedToMe,
                                  enabled: !inFlight,
                                  inFlight: inFlight,
                                  onChanged: (_) => _toggle(pId),
                                );
                              },
                            ),
            ),
            _DialogFooter(onClose: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

// ── Shared dialog sub-widgets ─────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _DialogHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A))),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12.5, color: Color(0xFF7A7A7A))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
            color: const Color(0xFF9E9E9E),
          ),
        ],
      ),
    );
  }
}

class _AssignRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final bool checked;
  final bool enabled;
  final bool inFlight;
  final ValueChanged<bool?> onChanged;

  const _AssignRow({
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
    required this.checked,
    required this.enabled,
    required this.inFlight,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: enabled ? const Color(0xFF1A1A1A) : const Color(0xFF9E9E9E),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11.5, color: subtitleColor),
      ),
      trailing: inFlight
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Checkbox(
              value: checked,
              onChanged: enabled ? onChanged : null,
              activeColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
      onTap: enabled && !inFlight ? () => onChanged(!checked) : null,
    );
  }
}

class _DialogFooter extends StatelessWidget {
  final VoidCallback onClose;
  const _DialogFooter({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: onClose,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }
}