import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class DetectionReportService {
  static Future<List<Map<String, dynamic>>> fetchReports() async {
    final url = await ApiConfig.detectionReportUrl();

    final res = await http.get(Uri.parse(url));

    if (res.statusCode != 200) {
      throw Exception("Failed to load detection report");
    }

    final List list = jsonDecode(res.body);
    return list.cast<Map<String, dynamic>>();
  }
}
