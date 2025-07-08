import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GuideFormPage extends StatefulWidget {
  final int jobTypeId;
  final String jobTypeName;

  const GuideFormPage({
    super.key,
    required this.jobTypeId,
    required this.jobTypeName,
  });

  @override
  State<GuideFormPage> createState() => _GuideFormPageState();
}

class _GuideFormPageState extends State<GuideFormPage> {
  final _formKey = GlobalKey<FormState>();
  final storage = FlutterSecureStorage();

  // 預設選項
  final List<String> systemOptions = ['文湖線號誌', '高運量號誌', '號誌廠部'];
  final List<String> subsystemOptions = [
    '月台門系統',
    '自動列車控制系統',
    '行控中心號誌',
    '其他',
    '道旁控制系統',
    '道旁輔助控制系統',
    '電源系統',
    '管理文件',
    '轉轍器',
  ];

  // 下拉選單＋自訂輸入
  String? _system;
  final _systemController = TextEditingController();
  bool _useCustomSystem = false;

  String? _subsystem;
  final _subsystemController = TextEditingController();
  bool _useCustomSubsystem = false;

  // 其他欄位
  final _deviceTypeController = TextEditingController();
  final _docCodeAAController = TextEditingController();
  final _docCodeBBController = TextEditingController();
  final _docCodeNumController = TextEditingController();
  final _docCodeOptionalController = TextEditingController();
  final _docNameController = TextEditingController();
  final _deptController = TextEditingController();
  final _personController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final token = await storage.read(key: 'access_token');
    final url = Uri.parse('http://10.0.2.2:8000/api/signal-guides/');

    String fullDocCode =
        '${_docCodeAAController.text}-系-${_docCodeBBController.text}-${_docCodeNumController.text}';
    if (_docCodeOptionalController.text.isNotEmpty) {
      fullDocCode += '-${_docCodeOptionalController.text}';
    }

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'job_type': widget.jobTypeId,
        'system': _systemController.text.isNotEmpty ? _systemController.text : _system,
        'subsystem': _subsystemController.text.isNotEmpty ? _subsystemController.text : _subsystem,
        'equipment_type': _deviceTypeController.text,  // ✅ 修正名稱
        'doc_number': fullDocCode,                     // ✅ 修正名稱
        'title': _docNameController.text,              // ✅ 修正名稱
        'department': _deptController.text,
        'owner': _personController.text,
      }),
    );

    setState(() => _isSubmitting = false);

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('成功新增說明書')),
      );
      Navigator.pop(context, true);
    } else {
      print('新增失敗：${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('新增失敗，請稍後再試')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新增工作說明書')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 系統欄位（可切換）
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _useCustomSystem
                          ? TextFormField(
                        controller: _systemController,
                        decoration: const InputDecoration(labelText: '自訂系統名稱'),
                        validator: (value) =>
                        (value == null || value.isEmpty) ? '請輸入系統' : null,
                      )
                          : DropdownButtonFormField<String>(
                        value: _system,
                        decoration: const InputDecoration(labelText: '系統'),
                        items: systemOptions
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (value) => setState(() => _system = value),
                        validator: (_) => _system == null ? '請選擇系統' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: Icon(_useCustomSystem ? Icons.list : Icons.edit),
                      label: Text(_useCustomSystem ? '選單' : '自訂'),
                      onPressed: () => setState(() => _useCustomSystem = !_useCustomSystem),
                    )
                  ],
                ),

                // 子系統欄位（可切換）
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _useCustomSubsystem
                          ? TextFormField(
                        controller: _subsystemController,
                        decoration: const InputDecoration(labelText: '自訂子系統名稱'),
                        validator: (value) =>
                        (value == null || value.isEmpty) ? '請輸入子系統' : null,
                      )
                          : DropdownButtonFormField<String>(
                        value: _subsystem,
                        decoration: const InputDecoration(labelText: '子系統'),
                        items: subsystemOptions
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (value) => setState(() => _subsystem = value),
                        validator: (_) => _subsystem == null ? '請選擇子系統' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: Icon(_useCustomSubsystem ? Icons.list : Icons.edit),
                      label: Text(_useCustomSubsystem ? '選單' : '自訂'),
                      onPressed: () => setState(() => _useCustomSubsystem = !_useCustomSubsystem),
                    )
                  ],
                ),

                // 設備類別
                TextFormField(
                  controller: _deviceTypeController,
                  decoration: const InputDecoration(labelText: '設備類別（選填）'),
                ),

                // 作業類別
                TextFormField(
                  initialValue: widget.jobTypeName,
                  decoration: const InputDecoration(labelText: '作業類別'),
                  enabled: false,
                ),

                // 文件編號欄位
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _docCodeAAController,
                        decoration: const InputDecoration(labelText: 'QM'),
                        maxLength: 2,
                        validator: (value) =>
                        RegExp(r'^[A-Z]{2}$').hasMatch(value ?? '') ? null : '2大寫英文字母',
                      ),
                    ),
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('-系-')),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _docCodeBBController,
                        decoration: const InputDecoration(labelText: 'WI'),
                        maxLength: 2,
                        validator: (value) =>
                        RegExp(r'^[A-Z]{2}$').hasMatch(value ?? '') ? null : '2大寫英文字母',
                      ),
                    ),
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('-')),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _docCodeNumController,
                        decoration: const InputDecoration(labelText: '90000'),
                        maxLength: 5,
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                        RegExp(r'^\d{5}$').hasMatch(value ?? '') ? null : '5位數字',
                      ),
                    ),
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('-')),
                    Expanded(
                      flex: 2, // 增加寬度以顯示完整內容
                      child: TextFormField(
                        controller: _docCodeOptionalController,
                        decoration: const InputDecoration(labelText: '01-01（選填）'),
                      ),
                    ),
                  ],
                ),

                // 文件名稱
                TextFormField(
                  controller: _docNameController,
                  decoration: const InputDecoration(labelText: '文件名稱'),
                  validator: (value) => value == null || value.isEmpty ? '請輸入文件名稱' : null,
                ),

                // 權責股、負責人員
                TextFormField(
                  controller: _deptController,
                  decoration: const InputDecoration(labelText: '權責股（選填）'),
                ),
                TextFormField(
                  controller: _personController,
                  decoration: const InputDecoration(labelText: '負責人員（選填）'),
                ),

                const SizedBox(height: 24),
                _isSubmitting
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('提交'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
