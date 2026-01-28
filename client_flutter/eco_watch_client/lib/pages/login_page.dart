import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_config.dart';
import '../api/auth_service.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final serverController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String errorMsg = "";

  void doLogin() async {
    setState(() {
      loading = true;
      errorMsg = "";
    });

    String server = serverController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (!server.startsWith("http")) {
      server = "http://$server";
    }

    String? token = await AuthService.login(server, email, password);

    if (token != null) {
      // Save baseUrl + token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("jwt_token", token);
      await ApiConfig.saveBaseUrl(server);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } else {
      setState(() {
        errorMsg = "Login Failed! Check server/email/password.";
      });
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Eco Watch Client Login",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Server Field
                  TextField(
                    controller: serverController,
                    decoration: const InputDecoration(
                      labelText: "Server IP:Port",
                      hintText: "192.168.0.140:8080",
                      prefixIcon: Icon(Icons.wifi),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Email Field
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Password Field
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (errorMsg.isNotEmpty)
                    Text(errorMsg, style: const TextStyle(color: Colors.red)),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: loading ? null : doLogin,
                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text("Login"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
