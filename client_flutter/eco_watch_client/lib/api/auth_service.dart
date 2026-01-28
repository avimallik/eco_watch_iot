import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static Future<String?> login(
    String baseUrl,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["token"];
    }

    return null;
  }
}
