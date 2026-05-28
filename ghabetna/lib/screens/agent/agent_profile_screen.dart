import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AgentProfileScreen extends StatefulWidget {
  final Map user;

  const AgentProfileScreen({super.key, required this.user});

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> {
  Map<String, dynamic>? profile;
  List parcelles = [];
  bool isLoading = true;
  bool isEditing = false;
  bool isSaving = false;

  late TextEditingController _phoneController;

  // ── Theme ──────────────────────────────────────────────────────────────────
  static const _bg = Color(0xFFF7F7F5);
  static const _ink = Color(0xFF111111);
  static const _muted = Color(0xFF888888);
  static const _accent = Color(0xFF2D6A3F);
  static const _surface = Colors.white;
  static const _border = Color(0xFFE2E2E0);
  static const _danger = Color(0xFFCC3333);

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);
    try {
      final p = await ApiService.getMyProfile();
      final parc = await ApiService.getMyParcelles();
      setState(() {
        profile = p;
        parcelles = parc;
        _phoneController.text = p['numtel'] ?? '';
      });
    } catch (e) {
      if (e.toString().contains('PROFILE_NOT_CACHED')) {
        final id = (widget.user['id'] ??
            widget.user['user_id'] ??
            ApiService.userId) as String?;
        if (id != null) {
          await ApiService.syncUserCache(id);
          await _loadProfile();
          return;
        }
      }
      _snack('Could not load profile', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => isSaving = true);
    try {
      await ApiService.updateMyProfile({'numtel': _phoneController.text});
      setState(() {
        profile!['numtel'] = _phoneController.text;
        isEditing = false;
      });
      _snack('Profile updated');
    } catch (_) {
      _snack('Update failed', isError: true);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontSize: 13, color: Colors.white)),
        backgroundColor: isError ? _danger : _accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String get _initials {
    final prenom = profile?['prenom']?.toString() ?? '';
    final nom = profile?['nom']?.toString() ?? '';
    final f = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final l = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return '$f$l'.isNotEmpty ? '$f$l' : 'A';
  }

  String get _fullName {
    final first = profile?['prenom'] ?? '';
    final last = profile?['nom'] ?? '';
    return '$first $last'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _ink,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Profile',
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
        actions: [
          if (!isLoading && profile != null && !isEditing)
            TextButton(
              onPressed: () => setState(() => isEditing = true),
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: _accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (isEditing) ...[
            isSaving
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _accent),
                    ),
                  )
                : TextButton(
                    onPressed: _save,
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
            TextButton(
              onPressed: () {
                _phoneController.text = profile?['numtel'] ?? '';
                setState(() => isEditing = false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: _muted, fontSize: 14),
              ),
            ),
          ],
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEEEEEC)),
        ),
      ),
      body: isLoading
          ? _buildLoading()
          : profile == null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  color: _accent,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                    children: [
                      _buildAvatar(),
                      const SizedBox(height: 32),
                      _buildSectionLabel('Personal info'),
                      const SizedBox(height: 12),
                      _buildInfoSection(),
                      const SizedBox(height: 28),
                      _buildSectionLabel('Assigned parcels'),
                      const SizedBox(height: 12),
                      _buildParcelSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
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
            const Icon(Icons.person_off_outlined,
                size: 36, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 16),
            const Text(
              'Profile not found',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _ink),
            ),
            const SizedBox(height: 20),
            _MinimalButton(label: 'Retry', onTap: _loadProfile),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Column(
      children: [
        // Avatar circle
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: _accent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _fullName.isNotEmpty ? _fullName : 'Agent',
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: _ink,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Forest Agent',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _accent,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
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

  Widget _buildInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _InfoRow(
            label: 'First name',
            value: profile!['prenom'] ?? '—',
          ),
          _Divider(),
          _InfoRow(
            label: 'Last name',
            value: profile!['nom'] ?? '—',
          ),
          _Divider(),
          _InfoRow(
            label: 'Email',
            value: profile!['email'] ?? '—',
          ),
          _Divider(),
          _InfoRow(
            label: 'CIN',
            value: profile!['cin'] ?? '—',
          ),
          _Divider(),
          isEditing
              ? Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 90,
                        child: Text(
                          'Phone',
                          style: TextStyle(fontSize: 14, color: _muted),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontSize: 14, color: _ink),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: _border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: _accent, width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: _border),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : _InfoRow(
                  label: 'Phone',
                  value: profile!['numtel'] ?? '—',
                ),
        ],
      ),
    );
  }

  Widget _buildParcelSection() {
    if (parcelles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: const Center(
          child: Text(
            'No parcels assigned',
            style: TextStyle(fontSize: 14, color: _muted),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < parcelles.length; i++) ...[
            if (i > 0) _Divider(),
            _ParcelRow(parcel: parcelles[i]),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF888888),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111111),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParcelRow extends StatelessWidget {
  const _ParcelRow({required this.parcel});
  final Map parcel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          const Icon(Icons.crop_square_rounded,
              size: 16, color: Color(0xFF2D6A3F)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              parcel['partition_nom'] ?? 'Unnamed parcel',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111111),
              ),
            ),
          ),
          Text(
            'ID: ${parcel['partition_id'] ?? '—'}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F0),
        indent: 16, endIndent: 16);
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
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
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