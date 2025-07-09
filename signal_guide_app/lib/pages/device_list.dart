import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class DeviceListPage extends StatefulWidget {
  final int guideId;
  final String guideTitle;

  const DeviceListPage({
    super.key,
    required this.guideId,
    required this.guideTitle,
  });

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  final storage = FlutterSecureStorage();
  List<Map<String, dynamic>> _devices = [];
  bool _isLoading = true;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final role = await storage.read(key: 'role');
    setState(() => userRole = role);
  }

  Future<void> _fetchDevices() async {
    final token = await storage.read(key: 'access_token');
    final url = Uri.parse('http://10.0.2.2:8000/api/devices/by-guide/${widget.guideId}/');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _devices = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        print('取得設備失敗：${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('錯誤：$e');
      setState(() => _isLoading = false);
    }
  }

  void _showDeviceOptions(Map<String, dynamic> device) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('修改設備'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/add-device',
                arguments: {
                  'guideId': widget.guideId,
                  'guideTitle': widget.guideTitle,
                  'device': device,
                },
              ).then((result) {
                if (result == true) {
                  _fetchDevices();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ 設備已更新")));
                }
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('刪除設備'),
            onTap: () {
              Navigator.pop(context);
              _confirmDeleteDevice(device['id']);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDevice(int deviceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("確認刪除"),
        content: const Text("確定要刪除此設備嗎？此操作無法還原。"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("取消")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("刪除")),
        ],
      ),
    );

    if (confirmed == true) {
      final token = await storage.read(key: 'access_token');
      final url = Uri.parse('http://10.0.2.2:8000/api/devices/$deviceId/');
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 204) {
        _fetchDevices();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ 已刪除設備")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("刪除失敗")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.guideTitle,
              style: const TextStyle(fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Text('設備清單', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      floatingActionButton: userRole == 'A'
          ? FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/add-device',
            arguments: {
              'guideId': widget.guideId,
              'guideTitle': widget.guideTitle,
            },
          ).then((result) {
            if (result == true) {
              _fetchDevices();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ 已新增設備")));
            }
          });
        },
        child: const Icon(Icons.add),
      )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_devices.isEmpty
          ? const Center(child: Text('尚未新增設備'))
          : ListView.builder(
        itemCount: _devices.length,
        itemBuilder: (context, index) {
          final device = _devices[index];
          return ListTile(
            leading: const Icon(Icons.settings),
            title: Text(device['name'] ?? '未命名設備'),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/fault-cases',
                arguments: {
                  'deviceId': device['id'],
                  'deviceName': device['name'],
                },
              );
            },
            onLongPress: userRole == 'A' ? () => _showDeviceOptions(device) : null,
          );
        },
      )),
    );
  }
}
