import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/status_service.dart';
import 'login_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Timer? _timer;
  bool _loading = true;

  String _baseUrl = "";
  String _token = "";

  // values
  double? currentTemp;
  double? currentHum;
  double? currentMq2;

  double? threshTemp;
  double? threshMq2;

  int statusTemp = 0;
  int statusMq2 = 0;

  String user = "";

  // alarm
  final AudioPlayer _player = AudioPlayer();
  bool _alarmPlaying = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = (prefs.getString("base_url") ?? "").trim();
    _token = (prefs.getString("jwt_token") ?? "").trim();

    if (_baseUrl.isEmpty || _token.isEmpty) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    await _fetchAndUpdate();

    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _fetchAndUpdate(),
    );
  }

  Future<void> _fetchAndUpdate() async {
    try {
      final data = await StatusService.getStatus(
        baseUrl: _baseUrl,
        token: _token,
      );

      if (data.isEmpty) return;
      final m = data.first;

      final ct = _toDouble(m["current_temparature"]);
      final ch = _toDouble(m["current_humidity"]);
      final cm = _toDouble(m["current_mq2"]);

      final tt = _toDouble(m["threshold_temparature"]);
      final tm = _toDouble(m["threshold_mq2"]);

      final st = _toInt(m["status_temparature"]);
      final sm = _toInt(m["status_mq2"]);

      final u = (m["user"] ?? "").toString();

      if (!mounted) return;
      setState(() {
        _loading = false;
        currentTemp = ct;
        currentHum = ch;
        currentMq2 = cm;
        threshTemp = tt;
        threshMq2 = tm;
        statusTemp = st;
        statusMq2 = sm;
        user = u;
      });

      // alarm logic: any 1 => alarm ON
      final shouldAlarm = (statusTemp == 1) || (statusMq2 == 1);
      if (shouldAlarm) {
        await _startAlarm();
      } else {
        await _stopAlarm();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      // token invalid হলে Login page এ পাঠাতে চাইলে uncomment কর:
      // await _logout();
    }
  }

  double _ratio(double? current, double? threshold) {
    if (current == null || threshold == null) return 0.0;
    if (threshold <= 0) return 0.0;
    final r = current / threshold;
    return min(max(r, 0.0), 1.0);
  }

  Future<void> _startAlarm() async {
    if (_alarmPlaying) return;
    _alarmPlaying = true;

    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
      await _player.play(AssetSource("alarm.mp3"));
    } catch (_) {
      // silent fail (asset/pubspec/permission সমস্যা হলে এখানে আসতে পারে)
    }

    if (mounted) setState(() {});
  }

  Future<void> _stopAlarm() async {
    if (!_alarmPlaying) return;
    _alarmPlaying = false;

    try {
      await _player.stop();
    } catch (_) {}

    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    await _stopAlarm();
    _timer?.cancel();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("jwt_token");

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tempRatio = _ratio(currentTemp, threshTemp);
    final mq2Ratio = _ratio(currentMq2, threshMq2);

    final alarmOn = (statusTemp == 1) || (statusMq2 == 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Client Dashboard"),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAndUpdate,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // user + alarm badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.isEmpty ? "Logged in" : "Logged in as: $user",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: alarmOn
                              ? Colors.red.withOpacity(.12)
                              : Colors.green.withOpacity(.12),
                          border: Border.all(
                            color: alarmOn ? Colors.red : Colors.green,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              alarmOn
                                  ? Icons.warning_amber
                                  : Icons.check_circle,
                              color: alarmOn ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              alarmOn ? "ALARM" : "SAFE",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: alarmOn ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Gauges row
                  Row(
                    children: [
                      Expanded(
                        child: _GaugeCard(
                          title: "Temperature",
                          unit: "°C",
                          current: currentTemp,
                          threshold: threshTemp,
                          ratio: tempRatio,
                          status: statusTemp,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GaugeCard(
                          title: "MQ2",
                          unit: "",
                          current: currentMq2,
                          threshold: threshMq2,
                          ratio: mq2Ratio,
                          status: statusMq2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Humidity Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.water_drop, size: 34),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Humidity",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  currentHum == null
                                      ? "-"
                                      : "${currentHum!.toStringAsFixed(1)} %",
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ✅ "Auto refresh..." intentionally removed
                ],
              ),
            ),
    );
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

class _GaugeCard extends StatelessWidget {
  final String title;
  final String unit;
  final double? current;
  final double? threshold;
  final double ratio; // 0..1
  final int status; // 0/1

  const _GaugeCard({
    required this.title,
    required this.unit,
    required this.current,
    required this.threshold,
    required this.ratio,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final over = status == 1;

    final currentText = current == null
        ? "-"
        : "${current!.toStringAsFixed(1)}$unit";

    final thresholdText = threshold == null
        ? "Threshold: -"
        : "Threshold: ${threshold!.toStringAsFixed(1)}$unit";

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(
                  over ? Icons.notifications_active : Icons.notifications_off,
                  color: over ? Colors.red : Colors.grey,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ✅ 1) Value ABOVE gauge
            Text(
              currentText,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 12),

            // ✅ 2) Bigger gauge
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: ratio,
                strokeWidth: 12,
                backgroundColor: Colors.grey.withOpacity(.22),
                valueColor: AlwaysStoppedAnimation<Color>(
                  over ? Colors.red : Colors.deepPurple,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ✅ 3) Threshold below gauge
            Text(
              thresholdText,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              over ? "EXCEEDED" : "NORMAL",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: over ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
