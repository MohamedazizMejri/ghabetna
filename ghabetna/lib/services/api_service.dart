import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
class ApiService {

  //static const String authBaseUrl = "http://127.0.0.1:8000"; /*http://localhost:8000*/
  /*static String get authBaseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:8000"; // web (admin)
    } else {
      return "http://10.0.2.2:8000"; // mobile emulator
    }
  }*/
  // AUTH + ADMIN SERVICE
  static String get authBaseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:8000";
    } else {
      return  "http://192.168.1.25:8000";//http://192.168.1.17:8000;//http://10.0.2.2:8000
    }
  }

  // INCIDENT SERVICE
  static String get incidentBaseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:8001";
    } else {
      return "http://192.168.1.25:8001" ;//http://192.168.1.17:8001;//http://10.0.2.2:8001
    }
  }

  static String? token;
  static Map<String, String> get headers => {
  "Content-Type": "application/json",
  "Authorization": "Bearer $token",
  };

  /*static Future<Map<String, dynamic>> login(String email, String password) async {

  final response = await http.post(
    Uri.parse("$BaseUrl/auth/login"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "email": email,
      "password": password
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    print(response.body); 
    throw Exception("Login failed");
  }
}*/
  static Future<Map<String, dynamic>> login(String email, String password) async {

    final response = await http.post(
      Uri.parse("$authBaseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      token = data["access_token"]; // ✅ STORE TOKEN HERE

      return data;
    } else {
      print(response.body); 
      throw Exception("Login failed");
    }
  }

  static Future<List<dynamic>> getRoles() async {
    final response = await http.get(Uri.parse("$authBaseUrl/roles/"));

    print(response.body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load roles");
    }
  }

  static Future<void> createUser(Map data) async {
    final response = await http.post(
      Uri.parse("$authBaseUrl/users/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to create user");
    }
  }

static Future<void> createForest(Map data) async {

  final response = await http.post(
    Uri.parse("$authBaseUrl/forests/"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(data),
  );

  if (response.statusCode != 200 && response.statusCode != 201) {
    print(response.body);
    throw Exception("Failed to create forest");
  }
}

static Future<List<dynamic>> getForests() async {

  final response = await http.get(
    Uri.parse("$authBaseUrl/forests/")
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load forests");
  }
}

static Future<List<dynamic>> getSupervisors() async {
  final response = await http.get(Uri.parse("$authBaseUrl/users/superviseurs/"));

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load supervisors");
  }
}

/*static Future<void> createPartition(Map data) async {
  final response = await http.post(
    Uri.parse("$BaseUrl/partitions/"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(data),
  );

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception("Failed to create partition");
  }
}*/
static Future<void> createPartition(Map<String, dynamic> data) async {
  try {
    final response = await http.post(
      Uri.parse("$authBaseUrl/partitions/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to create partition");
    }

  } catch (e) {
    print("ERROR: $e");
    rethrow; // keep throwing so your UI can handle it
  }
}

static Future<List<dynamic>> getAgents() async {
  final response = await http.get(Uri.parse("$authBaseUrl/users/agents/"));

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load agents");
  }
}

static Future<List<dynamic>> getPartitions() async {
  final response = await http.get(
    Uri.parse("$authBaseUrl/partitions/")
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load partitions");
  }
}

static Future<void> assignSupervisor(String forestId, String supervisorId) async {
  final response = await http.put(
    Uri.parse("$authBaseUrl/forests/$forestId/assign-supervisor?supervisor_id=$supervisorId"),
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to assign supervisor");
  }
}

static Future<void> assignAgent(String partitionId, String agentId) async {
  final response = await http.put(
    Uri.parse("$authBaseUrl/partitions/$partitionId/assign-agent?agent_id=$agentId"),
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to assign agent");
  }
}

static Future<Map<String, dynamic>> getStats() async {
  final response = await http.get(Uri.parse("$authBaseUrl/stats/"));

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load stats");
  }
}

static Future<List> getUsers() async {
  final response = await http.get(
    Uri.parse("$authBaseUrl/users/"),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load users");
  }
}

static Future<void> deleteUser(String id) async {
  final response = await http.delete(
    Uri.parse("$authBaseUrl/users/$id"),
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to delete user");
  }
}

static Future<void> updateUser(String id, Map data) async {
  final response = await http.patch(
    Uri.parse("$authBaseUrl/users/$id"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(data),
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to update user");
  }
}


}