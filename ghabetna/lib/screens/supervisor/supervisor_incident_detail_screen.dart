import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/incident_service.dart';

class IncidentDetailScreen extends StatefulWidget {
  final String incidentId;

  const IncidentDetailScreen({super.key, required this.incidentId});

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {

  Map<String, dynamic>? detail;
  bool isLoading = true;
  bool isSubmitting = false;

  // Action form state
  String? selectedAction;         // "accepted" or "rejected"
  final _commentController = TextEditingController();

  // ── Theme ──────────────────────────────────────────────────────────────────
  static const _bg        = Color(0xFFF7F7F5);
  static const _surface   = Colors.white;
  static const _ink       = Color(0xFF111111);
  static const _muted     = Color(0xFF888888);
  static const _accent    = Color(0xFF2D6A3F);
  static const _danger    = Color(0xFFCC3333);
  static const _border    = Color(0xFFE2E2E0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    try {
      final data = await IncidentService.getIncidentDetails(widget.incidentId);
      setState(() {
        detail = data;
        // Pre-fill action if already reviewed
        selectedAction = (data['status'] == 'accepted' || data['status'] == 'rejected')
            ? data['status']
            : null;
        _commentController.text = data['comment'] ?? '';
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _snack('Failed to load incident details', isError: true);
    }
  }

  Future<void> _submitAction() async {
    if (selectedAction == null) {
      _snack('Select Accept or Reject', isError: true);
      return;
    }
    if (selectedAction == 'rejected' && _commentController.text.trim().isEmpty) {
      _snack('A comment is required when rejecting', isError: true);
      return;
    }
    setState(() => isSubmitting = true);
    try {
      await IncidentService.updateIncidentStatus(
        widget.incidentId,
        selectedAction!,
        selectedAction == 'rejected' ? _commentController.text.trim() : null,
      );
      _snack(selectedAction == 'accepted' ? 'Incident accepted' : 'Incident rejected');
      await _load(); // refresh detail
    } catch (_) {
      _snack('Action failed — please try again', isError: true);
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 13)),
        backgroundColor: isError ? _danger : _accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _statusColor(String? s) {
    switch (s) {
      case 'accepted': return Colors.green;
      case 'rejected': return _danger;
      default:         return Colors.orange;
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'accepted': return 'Accepted';
      case 'rejected': return 'Rejected';
      default:         return 'Pending';
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final d = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      return '$d/$mo/${dt.year}  $h:$mi';
    } catch (_) {
      return iso;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _ink,
        elevation: 0,
        title: Text(
          detail != null ? detail!['reference_code'] ?? 'Incident Detail' : 'Incident Detail',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _ink),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEC)),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : detail == null
              ? const Center(child: Text('Could not load incident'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  children: [

                    // ── Status banner ──────────────────────────────────────
                    _StatusBanner(
                      status: detail!['status'],
                      statusColor: _statusColor(detail!['status']),
                      statusLabel: _statusLabel(detail!['status']),
                      isCritical: detail!['severity'] == true,
                    ),
                    const SizedBox(height: 20),

                    // ── Photo ──────────────────────────────────────────────
                    if (detail!['image_url'] != null) ...[
                      _SectionLabel('Photo'),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          '${IncidentService.baseUrl}${detail!['image_url']}',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 200,
                            color: const Color(0xFFEEEEEC),
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined,
                                  color: _muted, size: 40),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Info card ──────────────────────────────────────────
                    _Card(children: [
                      _InfoRow(
                        icon: Icons.category_outlined,
                        label: 'Type',
                        value: detail!['type_code'] ?? '—',
                      ),
                      _Divider(),
                      _InfoRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Reported by',
                        value: [
                          detail!['agent_prenom'],
                          detail!['agent_nom'],
                        ].where((v) => v != null && v.toString().isNotEmpty)
                            .join(' ')
                            .ifEmpty('—'),
                      ),
                      _Divider(),
                      _InfoRow(
                        icon: Icons.access_time_rounded,
                        label: 'Date & time',
                        value: _formatDate(detail!['created_at']?.toString()),
                      ),
                      _Divider(),
                      _InfoRow(
                        icon: Icons.forest_outlined,
                        label: 'Forest',
                        value: detail!['foret_nom'] ?? '—',
                      ),
                      _Divider(),
                      _InfoRow(
                        icon: Icons.grid_view_rounded,
                        label: 'Partition',
                        value: detail!['parcelle_nom'] ?? '—',
                      ),
                      _Divider(),
                      _InfoRow(
                        icon: Icons.warning_amber_rounded,
                        label: 'Critical',
                        value: detail!['severity'] == true ? 'Yes' : 'No',
                        valueColor: detail!['severity'] == true
                            ? _danger
                            : Colors.green,
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Description ────────────────────────────────────────
                    _SectionLabel('Description'),
                    const SizedBox(height: 8),
                    _Card(children: [
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          detail!['description'] ?? '—',
                          style: const TextStyle(
                              fontSize: 14, color: _ink, height: 1.55),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── GPS map ────────────────────────────────────────────
                    if (detail!['latitude'] != null &&
                        detail!['longitude'] != null) ...[
                      _SectionLabel('Location'),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 200,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(
                                (detail!['latitude'] as num).toDouble(),
                                (detail!['longitude'] as num).toDouble(),
                              ),
                              initialZoom: 14,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none, // static view
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(
                                      (detail!['latitude'] as num).toDouble(),
                                      (detail!['longitude'] as num).toDouble(),
                                    ),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: _danger,
                                      size: 36,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(detail!['latitude'] as num).toStringAsFixed(5)}, '
                        '${(detail!['longitude'] as num).toStringAsFixed(5)}',
                        style: const TextStyle(fontSize: 12, color: _muted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Supervisor action ──────────────────────────────────
                    _SectionLabel('Supervisor Action'),
                    const SizedBox(height: 8),
                    _Card(children: [

                      // Dropdown: Accept / Reject
                      DropdownButtonFormField<String>(
                        value: selectedAction,
                        decoration: InputDecoration(
                          labelText: 'Decision',
                          labelStyle: const TextStyle(fontSize: 14, color: _muted),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: _accent, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'accepted',
                            child: Row(children: [
                              Icon(Icons.check_circle_outline,
                                  color: Colors.green, size: 18),
                              SizedBox(width: 8),
                              Text('Accept'),
                            ]),
                          ),
                          DropdownMenuItem(
                            value: 'rejected',
                            child: Row(children: [
                              Icon(Icons.cancel_outlined,
                                  color: _danger, size: 18),
                              SizedBox(width: 8),
                              Text('Reject'),
                            ]),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => selectedAction = val),
                      ),

                      // Comment field — visible only when rejecting
                      if (selectedAction == 'rejected') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _commentController,
                          maxLines: 3,
                          style: const TextStyle(fontSize: 14, color: _ink),
                          decoration: InputDecoration(
                            labelText: 'Rejection comment *',
                            labelStyle:
                                const TextStyle(fontSize: 14, color: _muted),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: _border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: _border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: _accent, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                        ),
                      ],

                      // Show existing rejection comment if already rejected
                      if (detail!['status'] == 'rejected' &&
                          selectedAction != 'rejected' &&
                          (detail!['comment'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3F3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _danger.withOpacity(0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.comment_outlined,
                                  color: _danger, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  detail!['comment'],
                                  style: const TextStyle(
                                      fontSize: 13, color: _ink),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : _submitAction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedAction == 'rejected'
                                ? _danger
                                : _accent,
                            disabledBackgroundColor:
                                const Color(0xFFDDDDDB),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  selectedAction == 'rejected'
                                      ? 'Confirm Rejection'
                                      : 'Confirm Acceptance',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ]),

                  ],
                ),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

extension _StringX on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF555555),
          letterSpacing: 0.4,
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E2E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 20, color: Color(0xFFEEEEEC));
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF888888)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor ?? const Color(0xFF111111),
                    fontWeight: valueColor != null
                        ? FontWeight.w600
                        : FontWeight.w400,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.status,
    required this.statusColor,
    required this.statusLabel,
    required this.isCritical,
  });
  final dynamic status;
  final Color statusColor;
  final String statusLabel;
  final bool isCritical;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            status == 'accepted'
                ? Icons.check_circle_outline
                : status == 'rejected'
                    ? Icons.cancel_outlined
                    : Icons.hourglass_empty_rounded,
            color: statusColor,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
          const Spacer(),
          if (isCritical)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFCC3333),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 13),
                  SizedBox(width: 4),
                  Text(
                    '! CRITICAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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