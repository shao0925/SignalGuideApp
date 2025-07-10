import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProcedureStepListPage extends StatefulWidget {
  final int faultId;
  final String faultDescription;

  const ProcedureStepListPage({
    super.key,
    required this.faultId,
    required this.faultDescription,
  });

  @override
  State<ProcedureStepListPage> createState() => _ProcedureStepListPageState();
}

class _ProcedureStepListPageState extends State<ProcedureStepListPage> {
  final storage = FlutterSecureStorage();
  List<dynamic> _steps = [];
  bool _isLoading = true;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchSteps();
  }

  Future<void> _loadUserRole() async {
    final role = await storage.read(key: 'role');
    setState(() => userRole = role);
  }

  Future<void> _fetchSteps() async {
    final token = await storage.read(key: 'access_token');
    final url = Uri.parse('http://10.0.2.2:8000/api/procedure-steps/?fault_id=${widget.faultId}');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _steps = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        print('取得步驟失敗：${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('錯誤：$e');
      setState(() => _isLoading = false);
    }
  }

  void _showStepOptions(dynamic step) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('編輯步驟圖片'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigator.pushNamed(context, '/edit-step', arguments: {...});
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('刪除步驟圖片'),
            onTap: () {
              Navigator.pop(context);
              _confirmDeleteStep(step['id']);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteStep(int stepId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("確認刪除"),
        content: const Text("確定要刪除此步驟圖片嗎？此操作無法還原。"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("取消")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("刪除")),
        ],
      ),
    );

    if (confirmed == true) {
      final token = await storage.read(key: 'access_token');
      final url = Uri.parse('http://10.0.2.2:8000/api/procedure-steps/$stepId/');
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 204) {
        _fetchSteps();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ 已刪除圖片")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ 刪除失敗")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = userRole == 'A';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.faultDescription, style: const TextStyle(fontSize: 16), maxLines: 2),
            const Text('處理步驟列表', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            '/add-step',
            arguments: {
              'faultId': widget.faultId,
              'faultDescription': widget.faultDescription,
            },
          );
          if (result == true) {
            _fetchSteps();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ 已新增步驟圖片')),
            );
          }
        },
        child: const Icon(Icons.add),
      )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_steps.isEmpty
          ? const Center(child: Text('尚未上傳步驟圖片'))
          : ListView.builder(
        itemCount: _steps.length,
        itemBuilder: (context, index) {
          final step = _steps[index];
          final imageUrl = 'http://10.0.2.2:8000${step['file']}';
          return ListTile(
            leading: Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover),
            title: Text('步驟 ${step['order']}'),
            subtitle: Text('ID: ${step['id']}'),
            onTap: () {
              // 可顯示大圖或全螢幕瀏覽
            },
            onLongPress: isAdmin ? () => _showStepOptions(step) : null,
          );
        },
      )),
    );
  }
}
