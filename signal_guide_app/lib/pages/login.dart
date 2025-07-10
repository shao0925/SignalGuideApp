import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'home.dart';
import '../constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final employeeidController = TextEditingController();
  final passwordController = TextEditingController();
  final storage = FlutterSecureStorage();
  bool _obscureLoginPassword = true;

  Future<void> _login() async {
    print("⚡️ Login button clicked"); // ← 加這行看看有無被觸發
    final url = Uri.parse('$kBaseUrl/token/');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'employee_id': employeeidController.text.trim(),
        'password': passwordController.text.trim(),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await storage.write(key: 'access_token', value: data['access']);
      await storage.write(key: 'refresh_token', value: data['refresh']);
      await storage.write(key: 'name', value: data['name']);
      await storage.write(key: 'employee_id', value: data['employee_id']);
      await storage.write(key: 'role', value: data['role']);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("登入失敗"),
          content: const Text("請確認帳號或密碼是否正確"),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("確定"))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("號誌系統線上緊急故障排除指引")),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("請輸入登入資訊：", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              TextField(
                controller: employeeidController,
                decoration: const InputDecoration(
                  labelText: "員工編號",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: _obscureLoginPassword,
                decoration: InputDecoration(
                  labelText: "密碼",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureLoginPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureLoginPassword = !_obscureLoginPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _login,
                  child: const Text("登入"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
