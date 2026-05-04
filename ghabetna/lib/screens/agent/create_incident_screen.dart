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

  final descriptionController = TextEditingController();

  List types = [];
  String? selectedType;

  File? imageFile;
  Position? position;

  bool isLoading = false;
  bool isTypesLoading = true;

  final picker = ImagePicker();

  ///  Load types from backend
  @override
  void initState() {
    super.initState();
    loadTypes();
  }

  Future<void> loadTypes() async {
    try {
      final data = await IncidentService.getIncidentTypes();

      setState(() {
        types = data;
        if (types.isNotEmpty) {
          selectedType = types[0]["code"];
        }
        isTypesLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() => isTypesLoading = false);
    }
  }

  ///  Pick Image
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  ///  Get Location
  Future<void> getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enable location services")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission denied")),
      );
      return;
    }

    final pos = await Geolocator.getCurrentPosition();

    setState(() {
      position = pos;
    });
  }

  ///  Submit
  Future<void> submit() async {
    if (selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select incident type")),
      );
      return;
    }

    if (imageFile == null || position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image & location required")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await IncidentService.createIncident(
        description: descriptionController.text,
        latitude: position!.latitude,
        longitude: position!.longitude,
        typeCode: selectedType!,
        imagePath: imageFile!.path,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incident created successfully")),
      );

      Navigator.pop(context);

    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error creating incident")),
      );
    }

    setState(() => isLoading = false);
  }

  ///  Optional: severity color
  Color getSeverityColor(int severity) {
    if (severity >= 5) return Colors.red;
    if (severity >= 3) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Incident"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            ///  Description
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "Description",
              ),
            ),

            const SizedBox(height: 15),

            ///  Dynamic Type Dropdown
            isTypesLoading
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: selectedType,
                    items: types.map<DropdownMenuItem<String>>((type) {
                      return DropdownMenuItem(
                        value: type["code"],
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 6,
                              backgroundColor: getSeverityColor(type["severity"]),
                            ),
                            const SizedBox(width: 10),
                            Text(type["label"]),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedType = value);
                    },
                    decoration: const InputDecoration(
                      labelText: "Incident Type",
                    ),
                  ),

            const SizedBox(height: 20),

            ///  Image
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text("Take Photo"),
              onPressed: pickImage,
            ),

            if (imageFile != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Image.file(imageFile!, height: 150),
              ),

            const SizedBox(height: 20),

            ///  Location
            ElevatedButton.icon(
              icon: const Icon(Icons.location_on),
              label: const Text("Get Location"),
              onPressed: getLocation,
            ),

            if (position != null)
              Text(
                "Lat: ${position!.latitude}, Lng: ${position!.longitude}",
              ),

            const SizedBox(height: 30),

            ///  Submit
            ElevatedButton(
              onPressed: isLoading ? null : submit,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Submit Incident"),
            ),
          ],
        ),
      ),
    );
  }
}