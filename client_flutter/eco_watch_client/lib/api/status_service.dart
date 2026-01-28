import 'dart:convert';
import 'package:http/http.dart' as http;

class StatusService {
  static Future<List<Map<String, dynamic>>> getStatus({
    required String baseUrl,
    required String token,
  }) async {
    final uri = Uri.parse("${baseUrl.trim()}/api/esp/status");

    final res = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer ${token.trim()}",
        "Accept": "application/json",
      },
    );

    if (res.statusCode == 401) {
      throw Exception("Unauthorized (token invalid/expired)");
    }
    if (res.statusCode != 200) {
      throw Exception("Status failed: ${res.statusCode} ${res.body}");
    }

    final decoded = jsonDecode(res.body);

    if (decoded is List) {
      return decoded.map<Map<String, dynamic>>((e) {
        return Map<String, dynamic>.from(e as Map);
      }).toList();
    }

    throw Exception("Unexpected response format: not a List");
  }
}
