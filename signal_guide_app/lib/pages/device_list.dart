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

  @override
  void initState() {
    super.initState();
    _fetchDevices();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.guideTitle} - 設備清單')),
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
          );
        },
      )),
    );
  }
}
