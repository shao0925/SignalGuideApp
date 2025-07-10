import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class DeviceFormPage extends StatefulWidget {
  final int guideId;
  final String guideTitle;
  final Map<String, dynamic>? device;

  const DeviceFormPage({
    super.key,
    required this.guideId,
    required this.guideTitle,
    this.device,
  });

  @override
  State<DeviceFormPage> createState() => _DeviceFormPageState();
}

class _DeviceFormPageState extends State<DeviceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final storage = FlutterSecureStorage();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.device != null) {
      _nameController.text = widget.device!['name'] ?? '';
    }
  }

  Future<void> _saveDevice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final token = await storage.read(key: 'access_token');
    final isEdit = widget.device != null;

    final url = isEdit
        ? Uri.parse('$kBaseUrl/devices/${widget.device!['id']}/')
        : Uri.parse('$kBaseUrl/devices/');

    final response = await (isEdit ? http.put : http.post)(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': _nameController.text.trim(),
        'guide': widget.guideId,
      }),
    );

    setState(() => _isSaving = false);

    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEdit ? '修改成功' : '新增成功'),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('儲存失敗：${response.statusCode}'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device != null ? '修改設備' : '新增設備'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '設備名稱'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入設備名稱';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveDevice,
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : const Text('儲存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
