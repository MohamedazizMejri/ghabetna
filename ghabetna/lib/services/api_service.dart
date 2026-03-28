import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

  static const String baseUrl = "http://127.0.0.1:8000"; /*http://localhost:8000*/

  static Future<Map<String, dynamic>> login(String email, String password) async {

  final response = await http.post(
    Uri.parse("$baseUrl/auth/login"),
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
}

  static Future<List<dynamic>> getRoles() async {
    final response = await http.get(Uri.parse("$baseUrl/roles/"));

    print(response.body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load roles");
    }
  }

  static Future<void> createUser(Map data) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to create user");
    }
  }

static Future<void> createForest(Map data) async {

  final response = await http.post(
    Uri.parse("$baseUrl/forests/"),
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
    Uri.parse("$baseUrl/forests/")
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load forests");
  }
}

static Future<List<dynamic>> getSupervisors() async {
  final response = await http.get(Uri.parse("$baseUrl/users/superviseurs/"));

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load supervisors");
  }
}

/*static Future<void> createPartition(Map data) async {
  final response = await http.post(
    Uri.parse("$baseUrl/partitions/"),
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
      Uri.parse("$baseUrl/partitions/"),
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
  final response = await http.get(Uri.parse("$baseUrl/users/agents/"));

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load agents");
  }
}

static Future<List<dynamic>> getPartitions() async {
  final response = await http.get(
    Uri.parse("$baseUrl/partitions/")
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load partitions");
  }
}

static Future<void> assignSupervisor(String forestId, String supervisorId) async {
  final response = await http.put(
    Uri.parse("$baseUrl/forests/$forestId/assign-supervisor?supervisor_id=$supervisorId"),
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to assign supervisor");
  }
}

static Future<void> assignAgent(String partitionId, String agentId) async {
  final response = await http.put(
    Uri.parse("$baseUrl/partitions/$partitionId/assign-agent?agent_id=$agentId"),
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to assign agent");
  }
}

static Future<Map<String, dynamic>> getStats() async {
  final response = await http.get(Uri.parse("$baseUrl/stats/"));

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load stats");
  }
}

static Future<List> getUsers() async {
  final response = await http.get(
    Uri.parse("$baseUrl/users/"),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load users");
  }
}

static Future<void> deleteUser(String id) async {
  final response = await http.delete(
    Uri.parse("$baseUrl/users/$id"),
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to delete user");
  }
}

static Future<void> updateUser(String id, Map data) async {
  final response = await http.patch(
    Uri.parse("$baseUrl/users/$id"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(data),
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to update user");
  }
}


}