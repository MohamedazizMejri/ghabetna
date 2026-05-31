import 'package:flutter/material.dart';
import '../../services/incident_service.dart';
import '../../services/api_service.dart';
import 'supervisor_incident_detail_screen.dart';

const _kGreen      = Color(0xFF2D6A4F);
const _kGreenLight = Color(0xFF40916C);
const _kAccent     = Color(0xFF74C69D);
const _kSurface    = Color(0xFFF6F8F6);
const _kBorder     = Color(0xFFE2E8E4);
const _kTextHead   = Color(0xFF1A2E25);
const _kTextSub    = Color(0xFF6B7C74);

class SupervisorIncidentsScreen extends StatefulWidget {
  final bool embedded;
  const SupervisorIncidentsScreen({super.key, this.embedded = false});

  @override
  State<SupervisorIncidentsScreen> createState() => _SupervisorIncidentsScreenState();
}

class _SupervisorIncidentsScreenState extends State<SupervisorIncidentsScreen> {
  List _all = [];
  List _filtered = [];
  bool isLoading = true;

  // ── Filter state ──
  String _searchQuery = '';
  String? _filterStatus;   // null = all
  String? _filterCritical; // null = all | 'yes' | 'no'
  String? _filterType;     // null = all

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadIncidents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadIncidents() async {
    setState(() => isLoading = true);
    try {
      final forests = await ApiService.getMyForests();
      final myForestIds = forests
          .map((f) => f['forest_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      final all = await IncidentService.getAllIncidents();
      final filtered = myForestIds.isEmpty
          ? <dynamic>[]
          : all.where((i) {
              final fid = i['foret_id']?.toString() ?? '';
              return myForestIds.contains(fid);
            }).toList();

      setState(() {
        _all = filtered;
        _applyFilters();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('loadIncidents error: $e');
      setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    List result = List.from(_all);

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((i) {
        return (i['reference_code'] ?? '').toLowerCase().contains(q) ||
               (i['description'] ?? '').toLowerCase().contains(q) ||
               (i['type_code'] ?? '').toLowerCase().contains(q) ||
               (i['foret_nom'] ?? '').toLowerCase().contains(q);
      }).toList();
    }

    // Status
    if (_filterStatus != null) {
      result = result.where((i) => (i['status'] ?? 'pending') == _filterStatus).toList();
    }

    // Critical
    if (_filterCritical != null) {
      final wantCritical = _filterCritical == 'yes';
      result = result.where((i) => (i['severity'] == true) == wantCritical).toList();
    }

    // Type
    if (_filterType != null) {
      result = result.where((i) => (i['type_code'] ?? '') == _filterType).toList();
    }

    _filtered = result;
  }

  void _onSearch(String val) {
    setState(() {
      _searchQuery = val;
      _applyFilters();
    });
  }

  void _setFilter(String key, String? value) {
    setState(() {
      if (key == 'status')   _filterStatus   = value;
      if (key == 'critical') _filterCritical = value;
      if (key == 'type')     _filterType     = value;
      _applyFilters();
    });
  }

  void _clearFilters() {
    setState(() {
      _filterStatus   = null;
      _filterCritical = null;
      _filterType     = null;
      _searchQuery    = '';
      _searchController.clear();
      _applyFilters();
    });
  }

  List<String> get _allTypes {
    final types = _all.map((i) => (i['type_code'] ?? '') as String).toSet().toList();
    types.sort();
    return types;
  }

  bool get _hasActiveFilters =>
      _filterStatus != null || _filterCritical != null ||
      _filterType   != null || _searchQuery.isNotEmpty;

  // ── Status chip ─────────────────────────────────────────────────────────
  Widget _statusChip(String? status) {
    final s = status ?? 'pending';
    Color bg, fg, border;
    switch (s) {
      case 'accepted':
        bg = const Color(0xFFEBF8F2); fg = const Color(0xFF1B6B45); border = const Color(0xFFB2DFC8);
        break;
      case 'rejected':
        bg = const Color(0xFFFFF0F0); fg = const Color(0xFFB91C1C); border = const Color(0xFFFFC5C5);
        break;
      default:
        bg = const Color(0xFFFFF8EB); fg = const Color(0xFF92560A); border = const Color(0xFFFFD99A);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border),
      ),
      child: Text(s[0].toUpperCase() + s.substring(1),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  // ── Critical badge ───────────────────────────────────────────────────────
  Widget _criticalBadge(dynamic severity) {
    final isCritical = severity == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: isCritical ? const Color(0xFFFFF0F0) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isCritical ? const Color(0xFFFFC5C5) : _kBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isCritical ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            size: 12, color: isCritical ? const Color(0xFFB91C1C) : _kTextSub),
        const SizedBox(width: 4),
        Text(isCritical ? 'Yes' : 'No',
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: isCritical ? const Color(0xFFB91C1C) : _kTextSub,
            )),
      ]),
    );
  }

  // ── Filter bar ───────────────────────────────────────────────────────────
  Widget _filterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          Row(children: [
            Expanded(
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: _kSurface, borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  style: const TextStyle(fontSize: 13, color: _kTextHead),
                  decoration: InputDecoration(
                    hintText: 'Search by reference, description, type, forest…',
                    hintStyle: const TextStyle(fontSize: 13, color: _kTextSub),
                    prefixIcon: const Icon(Icons.search, size: 18, color: _kTextSub),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16, color: _kTextSub),
                            onPressed: () { _searchController.clear(); _onSearch(''); },
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Refresh
            _IconBtn(icon: Icons.refresh_rounded, onTap: loadIncidents, tooltip: 'Refresh'),
            if (_hasActiveFilters) ...[
              const SizedBox(width: 8),
              _TextBtn(label: 'Clear', onTap: _clearFilters),
            ],
          ]),

          const SizedBox(height: 10),

          // Filter chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Filter:', style: TextStyle(fontSize: 12, color: _kTextSub, fontWeight: FontWeight.w500)),
                const SizedBox(width: 10),

                // Status
                _FilterChip(label: 'Status', value: _filterStatus,
                    options: const ['pending', 'accepted', 'rejected'],
                    onSelected: (v) => _setFilter('status', v)),
                const SizedBox(width: 8),

                // Critical
                _FilterChip(label: 'Critical', value: _filterCritical,
                    options: const ['yes', 'no'],
                    onSelected: (v) => _setFilter('critical', v)),
                const SizedBox(width: 8),

                // Type
                _FilterChip(label: 'Type', value: _filterType,
                    options: _allTypes,
                    onSelected: (v) => _setFilter('type', v)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Table ────────────────────────────────────────────────────────────────
  Widget _table() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results count
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Text('${_filtered.length} incident${_filtered.length != 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 13, color: _kTextSub)),
        ),

        // Table header
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(color: _kBorder),
          ),
          child: const Row(
            children: [
              _HeaderCell('Reference', flex: 2),
              _HeaderCell('Description', flex: 3),
              _HeaderCell('Type', flex: 2),
              _HeaderCell('Critical', flex: 2),
              _HeaderCell('Status', flex: 2),
              _HeaderCell('Forest', flex: 2),
              _HeaderCell('Partition', flex: 2),
              _HeaderCell('Image', flex: 1),
            ],
          ),
        ),

        // Rows
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            decoration: BoxDecoration(
              border: Border.all(color: _kBorder),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
              color: Colors.white,
            ),
            child: ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: _kBorder),
              itemBuilder: (context, index) {
                final incident = _filtered[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IncidentDetailScreen(incidentId: incident['id'].toString()),
                      ),
                    ).then((_) => loadIncidents());
                  },
                  hoverColor: const Color(0xFFF0F8F4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text(incident['reference_code'] ?? '—',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kGreen))),
                        Expanded(flex: 3, child: Text(incident['description'] ?? '—',
                            style: const TextStyle(fontSize: 13, color: _kTextHead),
                            maxLines: 2, overflow: TextOverflow.ellipsis)),
                        Expanded(flex: 2, child: Text(incident['type_code'] ?? '—',
                            style: const TextStyle(fontSize: 13, color: _kTextHead))),
                        Expanded(flex: 2, child: _criticalBadge(incident['severity'])),
                        Expanded(flex: 2, child: _statusChip(incident['status'])),
                        Expanded(flex: 2, child: Text(incident['foret_nom'] ?? '—',
                            style: const TextStyle(fontSize: 13, color: _kTextHead))),
                        Expanded(flex: 2, child: Text(incident['parcelle_nom'] ?? '—',
                            style: const TextStyle(fontSize: 13, color: _kTextSub))),
                        Expanded(flex: 1, child: incident['image_url'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  '${IncidentService.baseUrl}${incident["image_url"]}',
                                  width: 40, height: 40, fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.image_not_supported_outlined, size: 20, color: _kBorder)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _bodyContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kGreen));
    }
    if (_all.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.forest_outlined, size: 52, color: _kBorder),
          SizedBox(height: 14),
          Text('No incidents in your forests', style: TextStyle(fontSize: 15, color: _kTextSub)),
        ]),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.search_off, size: 48, color: _kBorder),
          const SizedBox(height: 14),
          const Text('No incidents match your filters', style: TextStyle(fontSize: 15, color: _kTextSub)),
          const SizedBox(height: 12),
          TextButton(onPressed: _clearFilters, child: const Text('Clear filters', style: TextStyle(color: _kGreen))),
        ]),
      );
    }

    return _table();
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _filterBar(),
        Expanded(child: _bodyContent()),
      ],
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Incidents',
            style: TextStyle(color: _kTextHead, fontWeight: FontWeight.w600, fontSize: 16)),
        iconTheme: const IconThemeData(color: _kTextHead),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: body,
    );
  }
}

// ── Small reusable widgets ─────────────────────────────────────────────────

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HeaderCell(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(text, style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: _kTextSub, letterSpacing: 0.4)),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  const _IconBtn({required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Icon(icon, size: 18, color: _kTextHead),
        ),
      ),
    );
  }
}

class _TextBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TextBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label, style: const TextStyle(fontSize: 12, color: _kGreen, fontWeight: FontWeight.w600)),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final void Function(String?) onSelected;
  const _FilterChip({
    required this.label, required this.value,
    required this.options, required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value != null;
    return GestureDetector(
      onTap: () async {
        final result = await showMenu<String?>(
          context: context,
          position: RelativeRect.fromLTRB(0, 40, 0, 0),
          items: [
            PopupMenuItem(value: null, child: Text('All $label', style: const TextStyle(fontSize: 13))),
            ...options.map((o) => PopupMenuItem(value: o,
                child: Text(o[0].toUpperCase() + o.substring(1), style: const TextStyle(fontSize: 13)))),
          ],
        );
        if (result != null || value != null) onSelected(result);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? _kGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? _kGreen : _kBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(isActive ? value! : label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : _kTextHead)),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down, size: 14,
              color: isActive ? Colors.white : _kTextSub),
        ]),
      ),
    );
  }
}