import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class FaultCaseListPage extends StatefulWidget {
  final int deviceId;
  final String deviceName;

  const FaultCaseListPage({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  State<FaultCaseListPage> createState() => _FaultCaseListPageState();
}

class _FaultCaseListPageState extends State<FaultCaseListPage> {
  final storage = FlutterSecureStorage();
  List<Map<String, dynamic>> _faults = [];
  bool _isLoading = true;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchFaultCases();
  }

  Future<void> _loadUserRole() async {
    final role = await storage.read(key: 'role');
    setState(() => userRole = role);
  }

  Future<void> _fetchFaultCases() async {
    final token = await storage.read(key: 'access_token');
    final url = Uri.parse('http://10.0.2.2:8000/api/faultcases/?device_id=${widget.deviceId}');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _faults = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        print('取得故障案例失敗：${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('錯誤：$e');
      setState(() => _isLoading = false);
    }
  }

  void _showFaultOptions(Map<String, dynamic> fault) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('修改故障案例'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/edit-fault',
                arguments: {
                  'deviceId': widget.deviceId,
                  'deviceName': widget.deviceName,
                  'fault': fault,
                },
              ).then((result) {
                if (result == true) {
                  _fetchFaultCases();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("✅ 故障案例已更新")));
                }
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('刪除故障案例'),
            onTap: () {
              Navigator.pop(context);
              _confirmDeleteFault(fault['id']);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFault(int faultId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("確認刪除"),
        content: const Text("確定要刪除此故障案例嗎？此操作無法還原。"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("取消")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("刪除")),
        ],
      ),
    );

    if (confirmed == true) {
      final token = await storage.read(key: 'access_token');
      final url = Uri.parse('http://10.0.2.2:8000/api/faultcases/$faultId/');
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 204) {
        _fetchFaultCases();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ 已刪除故障案例")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("刪除失敗")));
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
            Text(
              widget.deviceName,
              style: const TextStyle(fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Text('故障案例清單', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/add-fault',
            arguments: {
              'deviceId': widget.deviceId,
              'deviceName': widget.deviceName,
            },
          ).then((result) {
            if (result == true) {
              _fetchFaultCases();
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ 已新增故障案例")));
            }
          });
        },
        child: const Icon(Icons.add),
      )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_faults.isEmpty
          ? const Center(child: Text('尚未新增故障案例'))
          : ListView.builder(
        itemCount: _faults.length,
        itemBuilder: (context, index) {
          final fault = _faults[index];
          return ListTile(
            leading: const Icon(Icons.error_outline),
            title: Text(fault['description'] ?? '未命名故障案例'),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/procedure-steps',
                arguments: {
                  'faultId': fault['id'],
                  'faultDescription': fault['description'],
                },
              );
            },
            onLongPress: isAdmin ? () => _showFaultOptions(fault) : null,
          );
        },
      )),
    );
  }
}
