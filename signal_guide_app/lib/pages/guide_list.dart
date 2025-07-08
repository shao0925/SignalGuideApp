import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'guide_form.dart'; // 請確認 guide_form.dart 有實作 GuideFormPage

class GuideListPage extends StatefulWidget {
  final int jobTypeId;
  final String jobTypeName;

  const GuideListPage({
    super.key,
    required this.jobTypeId,
    required this.jobTypeName,
  });

  @override
  State<GuideListPage> createState() => _GuideListPageState();
}

class _GuideListPageState extends State<GuideListPage> {
  final storage = FlutterSecureStorage();
  List<String> _guideTitles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGuides();
  }

  Future<void> _fetchGuides() async {
    final token = await storage.read(key: 'access_token');
    final url = Uri.parse(
        'http://10.0.2.2:8000/api/signal-guides/?job_type=${widget.jobTypeId}');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _guideTitles =
              data.map<String>((item) => item['title'] as String).toList();
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('登入逾時，請重新登入')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        throw Exception('Failed to load guides: ${response.statusCode}');
      }
    } catch (e) {
      print('錯誤：$e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.jobTypeName} - 工作說明書')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_guideTitles.isEmpty
          ? const Center(child: Text('尚未有工作說明書'))
          : ListView.builder(
        itemCount: _guideTitles.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.description),
            title: Text(_guideTitles[index]),
          );
        },
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 前往新增說明書頁面
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GuideFormPage(
                jobTypeId: widget.jobTypeId,
                jobTypeName: widget.jobTypeName,
              ),
            ),
          );

          // 若有新增成功則重新刷新列表
          if (result == true) {
            _fetchGuides();
          }
        },
        child: const Icon(Icons.add),
        tooltip: '新增說明書',
      ),
    );
  }
}
