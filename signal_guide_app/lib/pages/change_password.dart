import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('新密碼與確認密碼不相符')),
      );
      return;
    }

    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/change_password/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        // 'old_password': oldPasswordController.text,
        'new_password': newPasswordController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密碼修改成功！')),
      );
      Navigator.pop(context);
    } else if (response.statusCode == 401) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('驗證失敗，請重新登入後再嘗試')),
      );
    } else {
      try {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('修改失敗：${error['detail'] ?? '發生錯誤'}')),
        );
      } catch (e) {
        debugPrint('無法解析錯誤訊息：${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('修改失敗：伺服器錯誤或路徑錯誤')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('修改密碼')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              /*
              TextFormField(
                controller: oldPasswordController,
                decoration: const InputDecoration(labelText: '舊密碼'),
                obscureText: true,
                validator: (value) => value == null || value.isEmpty ? '請輸入舊密碼' : null,
              ),
               */
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                decoration: InputDecoration(
                  labelText: '新密碼',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureNewPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入新密碼';
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
              TextFormField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: '確認新密碼',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請再次輸入新密碼';
                  }
                  if (value != newPasswordController.text) {
                    return '與新密碼不一致';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _changePassword,
                child: const Text('修改密碼'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
