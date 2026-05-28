import 'package:flutter/material.dart';
import '../../services/incident_service.dart';

class MyIncidentsScreen extends StatefulWidget {
  const MyIncidentsScreen({super.key});

  @override
  State<MyIncidentsScreen> createState() => _MyIncidentsScreenState();
}

class _MyIncidentsScreenState extends State<MyIncidentsScreen>
    with SingleTickerProviderStateMixin {
  List incidents = [];
  bool isLoading = true;
  String? error;
  late AnimationController _animController;

  // ── Theme ──────────────────────────────────────────────────────────────────
  static const _bg = Color(0xFFF7F7F5);
  static const _ink = Color(0xFF111111);
  static const _muted = Color(0xFF888888);
  static const _accent = Color(0xFF2D6A3F);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    fetchIncidents();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> fetchIncidents() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final data = await IncidentService.getMyIncidents();
      setState(() => incidents = data);
      _animController.forward(from: 0);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'My Incidents',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEEEEEC)),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) return _buildLoading();
    if (error != null) return _buildError();
    if (incidents.isEmpty) return _buildEmpty();
    return _buildList();
  }

  Widget _buildLoading() {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _accent,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 36, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 16),
            const Text(
              'Could not load incidents',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull to refresh or tap retry',
              style: TextStyle(fontSize: 13, color: _muted),
            ),
            const SizedBox(height: 24),
            _MinimalButton(label: 'Retry', onTap: fetchIncidents),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined,
                size: 40, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 16),
            const Text(
              'No incidents yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your reported incidents will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: fetchIncidents,
      color: _accent,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
        itemCount: incidents.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                '${incidents.length} ${incidents.length == 1 ? 'report' : 'reports'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: _muted,
                  letterSpacing: 0.2,
                ),
              ),
            );
          }
          final i = index - 1;
          final incident = incidents[i];
          return AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final delay = (i * 0.06).clamp(0.0, 0.5);
              final v = CurvedAnimation(
                parent: _animController,
                curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0),
                    curve: Curves.easeOut),
              ).value;
              return Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - v)),
                  child: child,
                ),
              );
            },
            child: _IncidentRow(incident: incident),
          );
        },
      ),
    );
  }
}

class _IncidentRow extends StatelessWidget {
  const _IncidentRow({required this.incident});
  final Map incident;

  static const _statusConfig = {
    'open': {'label': 'Open', 'color': 0xFF1A56A0},
    'in_progress': {'label': 'In Progress', 'color': 0xFFB05800},
    'in progress': {'label': 'In Progress', 'color': 0xFFB05800},
    'resolved': {'label': 'Resolved', 'color': 0xFF2D6A3F},
    'closed': {'label': 'Closed', 'color': 0xFF888888},
  };

  Map<String, dynamic> get _status {
    final key = (incident['status'] ?? '').toString().toLowerCase();
    return _statusConfig[key] ??
        {'label': incident['status'] ?? 'Open', 'color': 0xFF1A56A0};
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final description = (incident['description'] ?? '').toString();
    final typeCode =
        (incident['type_code'] ?? incident['type'] ?? 'Incident').toString();
    final createdAt = incident['created_at']?.toString();
    final statusInfo = _status;
    final statusColor = Color(statusInfo['color'] as int);
    final statusLabel = statusInfo['label'] as String;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  typeCode,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111111),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _StatusPill(label: statusLabel, color: statusColor),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF888888),
                height: 1.4,
              ),
            ),
          ],
          if (createdAt != null) ...[
            const SizedBox(height: 10),
            Text(
              _formatDate(createdAt),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFAAAAAA),
                letterSpacing: 0.1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _MinimalButton extends StatelessWidget {
  const _MinimalButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDDDDDB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
        ),
      ),
    );
  }
}