import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class JobTypeFormPage extends StatefulWidget {
  const JobTypeFormPage({super.key});

  @override
  State<JobTypeFormPage> createState() => _JobTypeFormPageState();
}

class _JobTypeFormPageState extends State<JobTypeFormPage> {
  final TextEditingController _nameController = TextEditingController();
  final storage = FlutterSecureStorage();

  Future<void> _submit() async {
    final token = await storage.read(key: 'access_token');
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showDialog("請輸入作業類別名稱");
      return;
    }

    final url = Uri.parse('$kBaseUrl/jobtypes/');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 201) {
      Navigator.pop(context, true);
    } else {
      final msg = jsonDecode(response.body)['detail'] ?? '新增失敗';
      _showDialog("新增失敗：$msg");
    }
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("提示"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("確定"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("新增作業類別")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "作業類別名稱",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: const Text("送出"),
            ),
          ],
        ),
      ),
    );
  }
}
