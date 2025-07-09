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

  @override
  void initState() {
    super.initState();
    _fetchSteps();
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

  @override
  Widget build(BuildContext context) {
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
              // TODO: 點擊圖片查看大圖或編輯
            },
          );
        },
      )),
    );
  }
}
