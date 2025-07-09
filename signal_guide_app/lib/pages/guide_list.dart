import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'guide_form.dart';

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
  List<Map<String, dynamic>> _guides = [];
  bool _isLoading = true;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _fetchGuides();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final token = await storage.read(key: 'access_token');
    if (token != null) {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
        final decoded = jsonDecode(payload);
        setState(() {
          userRole = decoded['role'];
        });
        print('解析後角色：$userRole'); // Debug
      }
    }
  }

  Future<void> _fetchGuides() async {
    final token = await storage.read(key: 'access_token');
    final url = Uri.parse('http://10.0.2.2:8000/api/signal-guides/?job_type=${widget.jobTypeId}');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _guides = List<Map<String, dynamic>>.from(data);
          // Optional: 排序置頂優先
          _guides.sort((a, b) {
            if (a['is_pinned'] == b['is_pinned']) return 0;
            return a['is_pinned'] == true ? -1 : 1;
          });
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        await storage.deleteAll();
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

  void _showGuideOptions(BuildContext context, Map<String, dynamic> guide) {
    if (userRole != 'A') return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('修改'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GuideFormPage(
                      jobTypeId: widget.jobTypeId,
                      jobTypeName: widget.jobTypeName,
                      guide: guide, // ✅ 傳入該筆資料
                    ),
                  ),
                );
                if (result == true) _fetchGuides();
              },
            ),

            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('刪除'),
              onTap: () {
                Navigator.pop(context);
                _deleteGuide(guide['id']);
              },
            ),
            ListTile(
              leading: Icon(
                guide['is_pinned'] ? Icons.push_pin : Icons.push_pin_outlined,
              ),
              title: Text(guide['is_pinned'] ? '取消置頂' : '設為置頂'),
              onTap: () {
                Navigator.pop(context);
                _togglePin(guide['id'], !guide['is_pinned']);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteGuide(int id) async {
    final token = await storage.read(key: 'access_token');
    final url = Uri.parse('http://10.0.2.2:8000/api/signal-guides/$id/');

    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('確認刪除'),
        content: const Text('確定要刪除此說明書嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('刪除')),
        ],
      ),
    );

    if (confirm == true) {
      final res = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 204) {
        _fetchGuides();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('刪除失敗')),
        );
      }
    }
  }

  Future<void> _togglePin(int id, bool pin) async {
    final token = await storage.read(key: 'access_token');
    final url = Uri.parse('http://10.0.2.2:8000/api/signal-guides/$id/');

    final res = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'is_pinned': pin}),
    );

    if (res.statusCode == 200) {
      _fetchGuides();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('更新置頂狀態失敗')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.jobTypeName} - 工作說明書')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_guides.isEmpty
          ? const Center(child: Text('尚未有工作說明書'))
          : ListView.builder(
        itemCount: _guides.length,
        itemBuilder: (context, index) {
          final guide = _guides[index];
          final isPinned = guide['is_pinned'] == true;

          return ListTile(
            leading: Icon(Icons.description, color: isPinned ? Colors.orange : null),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (guide['doc_number'] != null && guide['doc_number'].toString().isNotEmpty)
                  Text(
                    guide['doc_number'],
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                Text(
                  guide['title'],
                  style: isPinned
                      ? const TextStyle(fontWeight: FontWeight.bold)
                      : null,
                ),
              ],
            ),
            trailing: isPinned
                ? const Text('置頂', style: TextStyle(color: Colors.orange))
                : null,
            onLongPress: userRole == 'A'
                ? () => _showGuideOptions(context, guide)
                : null,
          );
        },
      )),
      floatingActionButton: (userRole == null)
          ? null
          : (userRole == 'A'
          ? FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GuideFormPage(
                jobTypeId: widget.jobTypeId,
                jobTypeName: widget.jobTypeName,
              ),
            ),
          );
          if (result == true) _fetchGuides();
        },
        child: const Icon(Icons.add),
        tooltip: '新增說明書',
      )
          : null),
    );
  }
}
