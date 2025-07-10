import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'home.dart';
import '../constants.dart';


class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final _formKey = GlobalKey<FormState>();
  final employeeIdController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  String selectedRole = 'B'; // 預設角色為查詢者
  bool _obscurePassword = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');

    final response = await http.post(
      Uri.parse('$kBaseUrl/create_user/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'employee_id': employeeIdController.text.trim(),
        'name': nameController.text.trim(),
        'password': passwordController.text,
        'role': selectedRole,
      }),
    );

    if (response.statusCode == 201) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('帳號建立成功！')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
      );
    } else {
      final error = jsonDecode(response.body);
      String errorMessage;

      if (response.statusCode == 401) {
        errorMessage = '建立失敗：憑證已過期，請重新登入後再嘗試建立帳號';
      } else if (error['employee_id'] != null &&
          error['employee_id'][0].toString().contains('已存在')) {
        // 假設你的後端傳的是 "此欄位必須唯一。" 或類似文字
        errorMessage = '建立失敗：員工編號已存在';
      } else {
        errorMessage = '建立失敗：${error['detail'] ?? '未知錯誤'}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }

  }

  @override
  void initState() {
    super.initState();
    employeeIdController.addListener(_generatePassword);
  }

  void _generatePassword() {
    final id = employeeIdController.text.trim();
    passwordController.text = id.isNotEmpty ? 'e$id' : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新增帳號')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: employeeIdController,
                decoration: const InputDecoration(labelText: '員工編號 (五碼)'),
                validator: (value) => value == null || value.isEmpty ? '請輸入員工編號' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '姓名'),
                validator: (value) => value == null || value.isEmpty ? '請輸入姓名' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: '密碼（自動產生）',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入密碼';
                  }
                  if (value.length < 6) {
                    return '密碼至少 6 碼';
                  }
                  if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
                    return '密碼中至少要有一個英文字母';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: 'A', child: Text('管理者 (A)')),
                  DropdownMenuItem(value: 'B', child: Text('查詢者 (B)')),
                ],
                onChanged: (value) => setState(() => selectedRole = value!),
                decoration: const InputDecoration(labelText: '角色'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('建立帳號'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
