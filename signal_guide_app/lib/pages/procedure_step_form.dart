import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProcedureStepFormPage extends StatefulWidget {
  final int faultId;
  final String faultDescription;

  const ProcedureStepFormPage({
    super.key,
    required this.faultId,
    required this.faultDescription,
  });

  @override
  State<ProcedureStepFormPage> createState() => _ProcedureStepFormPageState();
}

class _ProcedureStepFormPageState extends State<ProcedureStepFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _orderController = TextEditingController();
  final storage = FlutterSecureStorage();

  XFile? _selectedFile;
  String? _fileName;

  Future<void> _pickFile() async {
    final file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(label: 'images_and_pdf', extensions: ['jpg', 'jpeg', 'png', 'pdf']),
      ],
    );

    if (file != null) {
      setState(() {
        _selectedFile = file;
        _fileName = file.name;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) return;

    final token = await storage.read(key: 'access_token');
    final uri = Uri.parse('http://10.0.2.2:8000/api/procedure-steps/');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['fault'] = widget.faultId.toString()
      ..fields['order'] = _orderController.text
      ..files.add(await http.MultipartFile.fromPath('file', _selectedFile!.path));

    final response = await request.send();

    if (response.statusCode == 201) {
      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ 已新增步驟圖片")));
      }
    } else {
      final body = await response.stream.bytesToString();
      print('新增失敗：${response.statusCode} - $body');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ 上傳失敗")));
      }
    }
  }

  @override
  void dispose() {
    _orderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("新增步驟圖片")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(widget.faultDescription, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _orderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '排序順序'),
                validator: (value) {
                  if (value == null || value.isEmpty) return '請輸入排序順序';
                  if (int.tryParse(value) == null) return '請輸入數字';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file),
                label: Text(_fileName ?? '選擇圖片或 PDF'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('上傳步驟圖片'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
