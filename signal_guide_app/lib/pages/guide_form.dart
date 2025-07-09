import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GuideFormPage extends StatefulWidget {
  final int jobTypeId;
  final String jobTypeName;
  final Map<String, dynamic>? guide;

  const GuideFormPage({
    super.key,
    required this.jobTypeId,
    required this.jobTypeName,
    this.guide,
  });

  @override
  State<GuideFormPage> createState() => _GuideFormPageState();
}

class _GuideFormPageState extends State<GuideFormPage> {
  final _formKey = GlobalKey<FormState>();
  final storage = FlutterSecureStorage();

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

  final List<String> deptOptions = [
    '土板股', '大修股', '中和股', '內湖大修股', '內湖股',
    '木柵股', '北投大修股', '松山股', '信義股', '南港股',
    '淡北股', '淡南股', '新店股', '新莊股', '號誌四場本部',
    '廠本部', '蘆洲股'
  ];

  String? _system;
  final _systemController = TextEditingController();
  bool _useCustomSystem = false;

  String? _subsystem;
  final _subsystemController = TextEditingController();
  bool _useCustomSubsystem = false;

  String? _dept;
  final _deptController = TextEditingController();
  bool _useCustomDept = false;

  final _deviceTypeController = TextEditingController();
  final _docCodeAAController = TextEditingController();
  final _docCodeBBController = TextEditingController();
  final _docCodeNumController = TextEditingController();
  final _docCodeOptionalController = TextEditingController();
  final _docNameController = TextEditingController();
  final _personController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    if (widget.guide != null) {
      _system = widget.guide!['system'];
      _subsystem = widget.guide!['subsystem'];
      _dept = widget.guide!['department'];
      _deviceTypeController.text = widget.guide!['equipment_type'] ?? '';
      _docNameController.text = widget.guide!['title'] ?? '';
      _personController.text = widget.guide!['owner'] ?? '';
      _populateDocNumber(widget.guide!['doc_number']);
    }
  }

  void _populateDocNumber(String? docNumber) {
    if (docNumber == null) return;
    final parts = docNumber.split('-');
    if (parts.length >= 4 && parts[1] == '系') {
      _docCodeAAController.text = parts[0];
      _docCodeBBController.text = parts[2];
      _docCodeNumController.text = parts[3];
      if (parts.length > 4) {
        _docCodeOptionalController.text = parts.sublist(4).join('-');
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final token = await storage.read(key: 'access_token');
    final isEditing = widget.guide != null;
    final url = isEditing
        ? Uri.parse('http://10.0.2.2:8000/api/signal-guides/${widget.guide!['id']}/')
        : Uri.parse('http://10.0.2.2:8000/api/signal-guides/');
    final method = isEditing ? 'PATCH' : 'POST';

    String fullDocCode =
        '${_docCodeAAController.text}-系-${_docCodeBBController.text}-${_docCodeNumController.text}';
    if (_docCodeOptionalController.text.isNotEmpty) {
      fullDocCode += '-${_docCodeOptionalController.text}';
    }

    final request = http.Request(method, url)
      ..headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      })
      ..body = jsonEncode({
        'job_type': widget.jobTypeId,
        'system': _systemController.text.isNotEmpty
            ? _systemController.text
            : (_system ?? ''),
        'subsystem': _subsystemController.text.isNotEmpty
            ? _subsystemController.text
            : (_subsystem ?? ''),
        'equipment_type': _deviceTypeController.text,
        'doc_number': fullDocCode,
        'title': _docNameController.text,
        'department': _deptController.text.isNotEmpty
            ? _deptController.text
            : (_dept ?? ''),
        'owner': _personController.text,
      });

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    setState(() => _isSubmitting = false);

    if (response.statusCode == 201 || response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEditing ? '修改成功' : '新增成功'),
      ));
      Navigator.pop(context, true);
    } else {
      print('儲存失敗：${response.statusCode}');
      print('錯誤回應內容：${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('儲存失敗，請稍後再試')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.guide != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? '編輯工作說明書' : '新增工作說明書')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 系統欄位
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

                // 子系統欄位
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
                        validator: (value) {
                          if (value == null || value.isEmpty) return '請輸入 QM';
                          if (!RegExp(r'^[A-Z]{2}$').hasMatch(value)) return '2大寫英文字母';
                          return null;
                        },
                      ),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('-系-')),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _docCodeBBController,
                        decoration: const InputDecoration(labelText: 'WI'),
                        maxLength: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) return '請輸入 WI';
                          if (!RegExp(r'^[A-Z]{2}$').hasMatch(value)) return '2大寫英文字母';
                          return null;
                        },
                      ),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('-')),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _docCodeNumController,
                        decoration: const InputDecoration(labelText: '90000'),
                        maxLength: 5,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return '請輸入編號';
                          if (!RegExp(r'^\d{5}$').hasMatch(value)) return '5位數字';
                          return null;
                        },
                      ),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('-')),
                    Expanded(
                      flex: 2,
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

                // 權責股
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _useCustomDept
                          ? TextFormField(
                        controller: _deptController,
                        decoration: const InputDecoration(labelText: '自訂權責股（選填）'),
                      )
                          : DropdownButtonFormField<String>(
                        value: _dept,
                        decoration: const InputDecoration(labelText: '權責股（選填）'),
                        items: deptOptions
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (value) => setState(() => _dept = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: Icon(_useCustomDept ? Icons.list : Icons.edit),
                      label: Text(_useCustomDept ? '選單' : '自訂'),
                      onPressed: () => setState(() => _useCustomDept = !_useCustomDept),
                    )
                  ],
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
                  child: Text(isEditing ? '儲存修改' : '提交'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
