import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import 'image_gallery.dart';

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
    final url = Uri.parse('$kBaseUrl/steps/?fault_id=${widget.faultId}');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final List decoded = jsonDecode(response.body);
        decoded.sort((a, b) => a['order'].compareTo(b['order']));
        setState(() {
          _steps = decoded;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrderToBackend() async {
    final token = await storage.read(key: 'access_token');

    for (int i = 0; i < _steps.length; i++) {
      final step = _steps[i];
      final url = Uri.parse('$kBaseUrl/steps/${step['id']}/');
      final newOrder = i + 1;

      await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'order': newOrder}),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ 排序已更新')),
    );
  }

  void _showStepOptions(dynamic step) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('編輯步驟圖片'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: 編輯功能
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
          ),
        ),
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
      final url = Uri.parse('$kBaseUrl/steps/$stepId/');
      await http.delete(url, headers: {'Authorization': 'Bearer $token'});
      _fetchSteps();
    }
  }

  String _cleanFileName(String fullPath) {
    final decoded = Uri.decodeFull(fullPath.split('/').last);
    final fileNameWithoutExt = decoded.replaceAll(RegExp(r'\.\w+$'), ''); // 去副檔名
    final nameWithoutHash = fileNameWithoutExt.replaceAll(RegExp(r'_[a-zA-Z0-9]{6,}$'), ''); // 去亂碼
    return nameWithoutHash;
  }


  @override
  Widget build(BuildContext context) {
    final isAdmin = userRole == 'A';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.faultDescription, style: const TextStyle(fontSize: 16)),
            const Text('處理步驟圖片列表', style: TextStyle(fontSize: 12)),
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
          if (result == true) _fetchSteps();
        },
        child: const Icon(Icons.add),
      )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_steps.isEmpty
          ? const Center(child: Text('尚未上傳步驟圖片'))
          : ReorderableListView(
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = _steps.removeAt(oldIndex);
            _steps.insert(newIndex, item);
          });
          _updateOrderToBackend();
        },
        children: [
          for (int i = 0; i < _steps.length; i++) _buildStepTile(_steps[i], i),
        ],
      )),
    );
  }

  Widget _buildStepTile(dynamic step, int index) {
    final rawUrl = step['file'].toString();
    final fileUrl = rawUrl.startsWith('http') ? rawUrl : '$kHostUrl$rawUrl';
    final isPdf = fileUrl.toLowerCase().endsWith('.pdf');

    return ListTile(
      key: ValueKey(step['id']),
      leading: isPdf
          ? const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40)
          : Image.network(
        fileUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      ),
      title: Text(
        _cleanFileName(rawUrl),
        overflow: TextOverflow.ellipsis,
      ),
      onTap: isPdf
          ? () async {
        if (await canLaunchUrl(Uri.parse(fileUrl))) {
          await launchUrl(Uri.parse(fileUrl));
        }
      }
          : () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImageGalleryPage(
              steps: _steps,
              initialIndex: index,
            ),
          ),
        );
      },
      onLongPress: userRole == 'A' ? () => _showStepOptions(step) : null,
    );
  }
}
