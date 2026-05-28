import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/incident_service.dart';

class CreateIncidentScreen extends StatefulWidget {
  const CreateIncidentScreen({super.key});

  @override
  State<CreateIncidentScreen> createState() => _CreateIncidentScreenState();
}

class _CreateIncidentScreenState extends State<CreateIncidentScreen> {
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  List types = [];
  String? selectedType;
  File? imageFile;
  Position? position;

  bool isLoading = false;
  bool isTypesLoading = true;
  bool isCritical = false;
  bool isGettingLocation = false;

  // ── Theme ──────────────────────────────────────────────────────────────────
  static const _bg = Color(0xFFF7F7F5);
  static const _ink = Color(0xFF111111);
  static const _muted = Color(0xFF888888);
  static const _accent = Color(0xFF2D6A3F);
  static const _danger = Color(0xFFCC3333);
  static const _surface = Colors.white;
  static const _border = Color(0xFFE2E2E0);

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    try {
      final data = await IncidentService.getIncidentTypes();
      setState(() {
        types = data;
        if (types.isNotEmpty) selectedType = types[0]['code'];
        isTypesLoading = false;
      });
    } catch (_) {
      setState(() => isTypesLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked =
        await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1200);
    if (picked != null) setState(() => imageFile = File(picked.path));
  }

  void _showImageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 16),
              _SheetOption(
                icon: Icons.camera_alt_outlined,
                label: 'Take a photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              _SheetOption(
                icon: Icons.photo_library_outlined,
                label: 'Choose from gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getLocation() async {
    setState(() => isGettingLocation = true);
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _snack('Enable location services', isError: true);
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        _snack('Location permission permanently denied', isError: true);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => position = pos);
    } catch (_) {
      _snack('Could not get location', isError: true);
    } finally {
      if (mounted) setState(() => isGettingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedType == null) {
      _snack('Select an incident type', isError: true);
      return;
    }
    if (imageFile == null) {
      _snack('Attach a photo', isError: true);
      return;
    }
    if (position == null) {
      _snack('Capture your location', isError: true);
      return;
    }
    setState(() => isLoading = true);
    try {
      await IncidentService.createIncident(
        description: _descController.text,
        latitude: position!.latitude,
        longitude: position!.longitude,
        typeCode: selectedType!,
        imagePath: imageFile!.path,
      );
      _snack('Incident submitted');
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      _snack('Submission failed — please try again', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
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
        duration: const Duration(seconds: 3),
      ),
    );
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
          'Report Incident',
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          children: [
            // ── Type ────────────────────────────────────────────────────────
            _FieldLabel(label: 'Incident type', required: true),
            const SizedBox(height: 8),
            _buildTypeSelector(),
            const SizedBox(height: 24),

            // ── Description ─────────────────────────────────────────────────
            _FieldLabel(label: 'Description', required: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 4,
              style: const TextStyle(fontSize: 14, color: _ink),
              decoration: _inputDecoration('Describe what you observed…'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 24),

            // ── Photo ────────────────────────────────────────────────────────
            _FieldLabel(label: 'Photo', required: true),
            const SizedBox(height: 8),
            _buildPhotoField(),
            const SizedBox(height: 24),

            // ── Location ─────────────────────────────────────────────────────
            _FieldLabel(label: 'Location', required: true),
            const SizedBox(height: 8),
            _buildLocationField(),
            const SizedBox(height: 24),

            // ── Critical toggle ───────────────────────────────────────────────
            _buildCriticalToggle(),
            const SizedBox(height: 32),

            // ── Submit ────────────────────────────────────────────────────────
            _buildSubmit(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    if (isTypesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedType,
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: _ink),
          icon: const Icon(Icons.expand_more_rounded,
              color: _muted, size: 20),
          onChanged: (val) => setState(() => selectedType = val),
          items: types.map<DropdownMenuItem<String>>((t) {
            return DropdownMenuItem<String>(
              value: t['code'] as String,
              child: Text(t['label'] ?? t['code'] ?? ''),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPhotoField() {
    if (imageFile != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              imageFile!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => imageFile = null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: _showImageSheet,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: _muted, size: 22),
            SizedBox(width: 10),
            Text(
              'Add photo',
              style: TextStyle(
                fontSize: 14,
                color: _muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return GestureDetector(
      onTap: isGettingLocation ? null : _getLocation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: position != null ? _accent.withOpacity(0.4) : _border,
            width: position != null ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              position != null
                  ? Icons.location_on_rounded
                  : Icons.my_location_rounded,
              color: position != null ? _accent : _muted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    position != null ? 'Location captured' : 'Get current location',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: position != null ? _accent : _ink,
                    ),
                  ),
                  if (position != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${position!.latitude.toStringAsFixed(5)}, ${position!.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
                ],
              ),
            ),
            if (isGettingLocation)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _accent),
              )
            else if (position != null)
              const Icon(Icons.check_rounded, color: _accent, size: 18)
            else
              const Icon(Icons.chevron_right_rounded,
                  color: _muted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCritical ? _danger.withOpacity(0.4) : _border,
          width: isCritical ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: isCritical ? _danger : _muted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Critical incident',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isCritical ? _danger : _ink,
                  ),
                ),
                const Text(
                  'Mark if this requires immediate attention',
                  style: TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isCritical,
            activeColor: _danger,
            onChanged: (val) => setState(() => isCritical = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmit() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: isCritical ? _danger : _accent,
          disabledBackgroundColor: const Color(0xFFDDDDDB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(
                isCritical ? 'Submit Critical Report' : 'Submit Report',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: _muted),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: _surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _danger, width: 1.5),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.required = false});
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
            letterSpacing: 0.1,
          ),
        ),
        if (required)
          const Text(' *',
              style: TextStyle(
                  color: Color(0xFFCC3333),
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF444444)),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF111111),
              ),
            ),
          ],
        ),
      ),
    );
  }
}