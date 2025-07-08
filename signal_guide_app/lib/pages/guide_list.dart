import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GuideListPage extends StatefulWidget {
  final int jobTypeId;
  final String jobTypeName;

  const GuideListPage({super.key, required this.jobTypeId, required this.jobTypeName});

  @override
  State<GuideListPage> createState() => _GuideListPageState();
}

class _GuideListPageState extends State<GuideListPage> {
  final storage = FlutterSecureStorage();
  List<String> _guideTitles = [];

  @override
  void initState() {
    super.initState();
    _fetchGuides();
  }

  Future<void> _fetchGuides() async {
    final token = await storage.read(key: 'access_token');
    final url = Uri.parse('http://10.0.2.2:8000/api/signal-guides/?job_type=${widget.jobTypeId}');

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _guideTitles = data.map<String>((item) => item['title'] as String).toList();
      });
    } else {
      print('取得工作說明書失敗：${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.jobTypeName} - 工作說明書')),
      body: _guideTitles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _guideTitles.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.description),
            title: Text(_guideTitles[index]),
          );
        },
      ),
    );
  }
}
