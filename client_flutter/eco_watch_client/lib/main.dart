import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';

void main() {
  runApp(const EcoWatchApp());
}

class EcoWatchApp extends StatelessWidget {
  const EcoWatchApp({super.key});

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("jwt_token") != null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Eco Watch Client",
      home: FutureBuilder(
        future: isLoggedIn(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return snapshot.data == true
              ? const DashboardPage()
              : const LoginPage();
        },
      ),
    );
  }
}
