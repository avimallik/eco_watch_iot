import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:eco_watch_client/pages/detection_report_page.dart';

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
  bool _alarmManuallyStopped = false;

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

      final shouldAlarm = (st == 1) || (sm == 1);

      // new danger → allow alarm again
      if (shouldAlarm) {
        _alarmManuallyStopped = false;
      }

      // alarm will NOT auto stop
      if (shouldAlarm && !_alarmManuallyStopped) {
        await _startAlarm();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _startAlarm() async {
    if (_alarmPlaying) return;
    _alarmPlaying = true;

    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
      await _player.play(AssetSource("alarm.mp3"));
    } catch (_) {
      _alarmPlaying = false;
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

  // STOP ALARM
  Future<void> _manualStopAlarm() async {
    _alarmManuallyStopped = true;
    await _stopAlarm();
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

  @override
  Widget build(BuildContext context) {
    final alarmOn = _alarmPlaying;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: "Detection Report",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DetectionReportPage()),
              );
            },
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAndUpdate,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // USER + ALARM
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
                            Text(
                              alarmOn ? "ALARM" : "SAFE",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: alarmOn ? Colors.red : Colors.green,
                              ),
                            ),
                            if (alarmOn) ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _manualStopAlarm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                ),
                                child: const Text(
                                  "STOP ALARM",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // GAUGES
                  Row(
                    children: [
                      Expanded(
                        child: _GaugeCard(
                          title: "Temperature",
                          unit: "°C",
                          current: currentTemp,
                          threshold: threshTemp,
                          status: statusTemp,
                          gaugeSize: 120,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GaugeCard(
                          title: "MQ2",
                          unit: "",
                          current: currentMq2,
                          threshold: threshMq2,
                          status: statusMq2,
                          gaugeSize: 120,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // HUMIDITY (UNCHANGED)
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
                                const SizedBox(height: 2),
                                Text(
                                  currentHum == null
                                      ? "-"
                                      : "${currentHum!.toStringAsFixed(1)} %",
                                  style: const TextStyle(
                                    fontSize: 16,
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
                ],
              ),
            ),
    );
  }
}

/// ---------------- GAUGE CARD (ORIGINAL UI) ----------------

class _GaugeCard extends StatelessWidget {
  final String title;
  final String unit;
  final double? current;
  final double? threshold;
  final int status;
  final double gaugeSize;

  const _GaugeCard({
    required this.title,
    required this.unit,
    required this.current,
    required this.threshold,
    required this.status,
    this.gaugeSize = 220,
  });

  @override
  Widget build(BuildContext context) {
    final over = status == 1;

    final centerText = current == null
        ? "-"
        : "${current!.toStringAsFixed(1)}$unit";

    final t = (threshold == null || threshold! <= 0) ? 100.0 : threshold!;
    final c = (current ?? 0.0).clamp(0.0, t).toDouble();

    final thresholdText = threshold == null
        ? "Threshold: -"
        : "Threshold: ${threshold!.toStringAsFixed(1)}$unit";

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
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
            const SizedBox(height: 25),
            SizedBox(
              width: gaugeSize,
              height: gaugeSize,
              child: SleekCircularSlider(
                min: 0.0,
                max: t,
                initialValue: c,
                appearance: CircularSliderAppearance(
                  startAngle: 150,
                  angleRange: 240,
                  customWidths: CustomSliderWidths(
                    trackWidth: 18,
                    progressBarWidth: 18,
                    handlerSize: 0,
                  ),
                  customColors: CustomSliderColors(
                    trackColor: Colors.grey.withOpacity(.18),
                    progressBarColor: over ? Colors.red : Colors.deepPurple,
                    hideShadow: true,
                  ),
                  infoProperties: InfoProperties(modifier: (_) => centerText),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(thresholdText),
            const SizedBox(height: 10),
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
