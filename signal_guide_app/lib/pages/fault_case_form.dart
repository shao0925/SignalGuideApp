import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class FaultCaseFormPage extends StatefulWidget {
  final int deviceId;
  final String deviceName;
  final Map<String, dynamic>? fault; // 若為 null 表示新增模式

  const FaultCaseFormPage({
    super.key,
    required this.deviceId,
    required this.deviceName,
    this.fault,
  });

  @override
  State<FaultCaseFormPage> createState() => _FaultCaseFormPageState();
}

class _FaultCaseFormPageState extends State<FaultCaseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final storage = FlutterSecureStorage();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.fault != null) {
      _descriptionController.text = widget.fault!['description'] ?? '';
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final token = await storage.read(key: 'access_token');
    final isEditing = widget.fault != null;
    final url = isEditing
        ? Uri.parse('$kBaseUrl/faultcases/${widget.fault!['id']}/')
        : Uri.parse('$kBaseUrl/faultcases/');

    setState(() => _isSubmitting = true);

    final response = await (isEditing
        ? http.put(url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'device': widget.deviceId,
          'description': _descriptionController.text.trim(),
        }))
        : http.post(url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'device': widget.deviceId,
          'description': _descriptionController.text.trim(),
        })));

    setState(() => _isSubmitting = false);

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? '✅ 已更新故障案例' : '✅ 已新增故障案例')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ 儲存失敗 (${response.statusCode})')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.fault != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing
            ? '編輯故障案例 - ${widget.deviceName}'
            : '新增故障案例 - ${widget.deviceName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: '故障描述',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入故障描述';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _isSubmitting
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(isEditing ? '更新' : '儲存'),
                onPressed: _submitForm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
