import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Load saved baseUrl
  static Future<String?> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("base_url");
  }

  // Save baseUrl
  static Future<void> saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("base_url", url);
  }

  // Login API endpoint
  static Future<String> loginUrl() async {
    final base = await getBaseUrl();
    return "$base/api/auth/login";
  }

  // Status API endpoint
  static Future<String> statusUrl() async {
    final base = await getBaseUrl();
    return "$base/api/esp/status";
  }

  // Detection Report API (NO JWT REQUIRED)
  static Future<String> detectionReportUrl() async {
    final base = await getBaseUrl();
    return "$base/api/detection-report";
  }
}
