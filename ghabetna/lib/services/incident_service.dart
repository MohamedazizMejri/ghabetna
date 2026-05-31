import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class IncidentService {

  static String get baseUrl => ApiService.baseUrl; //static String get baseUrl => ApiService.incidentBaseUrl;

  static Future<List<dynamic>> getMyIncidents() async {
    final response = await http.get(
      Uri.parse("$baseUrl/incidents/my"),
      headers: ApiService.headers, //  reuse token
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load incidents");
    }
  }

  /// "isCritical" comes from the Critical toggle in CreateIncidentScreen.
  /// When true, severity is sent as "true" → saved as TRUE in the incident row.
  static Future<void> createIncident({
  required String description,
  required double latitude,
  required double longitude,
  required String typeCode,
  required String imagePath,
  required bool isCritical,
  }) async {

  var request = http.MultipartRequest(
    "POST",
    Uri.parse("$baseUrl/incidents"),
  );

  request.headers["Authorization"] = "Bearer ${ApiService.token}";

  request.fields["description"] = description;
  request.fields["latitude"] = latitude.toString();
  request.fields["longitude"] = longitude.toString();
  request.fields["type_code"] = typeCode;
  request.fields["severity"] = isCritical.toString(); // "true" or "false"

  request.files.add(
    await http.MultipartFile.fromPath("image", imagePath),
  );

  var response = await request.send();

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception("Failed to create incident");
  }
  }

  static Future<List<dynamic>> getIncidentTypes() async {
  final response = await http.get(
    Uri.parse("$baseUrl/incident-types"),
    headers: {
      "Authorization": "Bearer ${ApiService.token}",
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load incident types");
  }
  }


static Future<List<dynamic>> getAllIncidents() async {
  final response = await http.get(
    Uri.parse("${ApiService.baseUrl}/incidents"), //Uri.parse("${ApiService.incidentBaseUrl}/incidents"),
    headers: ApiService.headers,
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load incidents");
  }
}


/// Fetches full details for a single incident including agent name,
/// forest, partition, GPS, photo, status, comment, created_at.
static Future<Map<String, dynamic>> getIncidentDetails(String id) async {
  final response = await http.get(
    Uri.parse("$baseUrl/incidents/$id/details"),
    headers: ApiService.headers,
  );
  if (response.statusCode == 200) {
    return Map<String, dynamic>.from(jsonDecode(response.body));
  } else {
    throw Exception("Failed to load incident details");
  }
}

static Future<void> updateIncidentStatus(
  String id,
  String status,
  String? comment,
) async {
  final response = await http.patch(
    Uri.parse("${ApiService.baseUrl}/incidents/$id/status"), //Uri.parse("${ApiService.incidentBaseUrl}/incidents/$id/status"),
    headers: ApiService.headers,
    body: jsonEncode({
      "status": status,
      "comment": comment,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to update status");
  }
}




}

