import 'package:flutter/material.dart';
import '../api/detection_report_service.dart';

class DetectionReportPage extends StatefulWidget {
  const DetectionReportPage({super.key});

  @override
  State<DetectionReportPage> createState() => _DetectionReportPageState();
}

class _DetectionReportPageState extends State<DetectionReportPage> {
  bool loading = true;
  String error = "";
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await DetectionReportService.fetchReports();
      setState(() {
        rows = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detection Report")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(child: Text(error))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: rows.length,
                itemBuilder: (context, i) {
                  final r = rows[i];

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber),
                      title: Text(
                        r["status"] ?? "-",
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Temp: ${r["detected_temp"] ?? "-"}"),
                          Text("MQ2: ${r["detected_mq2"] ?? "-"}"),
                          Text("Date: ${r["date"]}"),
                          Text("Time: ${r["time"]}"),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
