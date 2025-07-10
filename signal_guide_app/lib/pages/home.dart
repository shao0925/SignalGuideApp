import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'login.dart';
import 'create_user.dart';
import 'change_password.dart';
import 'guide_list.dart';
import 'device_list.dart';
import '../constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _userName;
  String? _employeeId;
  String? _userRole;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _lastBackPressed;
  final storage = FlutterSecureStorage();
  List<Map<String, dynamic>> _jobTypes = [];
  List<Map<String, dynamic>> _pinnedGuides = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchJobTypes();
    _fetchPinnedGuides();
  }

  Future<void> _loadUserInfo() async {
    final name = await storage.read(key: 'name');
    final id = await storage.read(key: 'employee_id');
    final role = await storage.read(key: 'role');
    setState(() {
      _userName = name;
      _employeeId = id;
      _userRole = role;
    });
  }

  Future<void> _fetchJobTypes() async {
    final token = await storage.read(key: 'access_token');
    final url = Uri.parse('$kBaseUrl/jobtypes/');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _jobTypes = data.map((item) => {
            'id': item['id'],
            'name': item['name'],
          }).toList();
        });
      } else if (response.statusCode == 401) {
        await storage.deleteAll();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
        );
      } else {
        print('取得分類失敗：${response.statusCode}');
      }
    } catch (e) {
      print('錯誤：$e');
    }
  }

  Future<void> _fetchPinnedGuides() async {
    final token = await storage.read(key: 'access_token');
    final url = Uri.parse('$kBaseUrl/signal-guides/?is_pinned=true');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _pinnedGuides = List<Map<String, dynamic>>.from(data);
        });
      } else {
        print('取得置頂說明書失敗：${response.statusCode}');
      }
    } catch (e) {
      print('錯誤：$e');
    }
  }

  void _showJobTypeOptions(int id, String currentName) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('修改類別名稱'),
            onTap: () {
              Navigator.pop(context);
              _editJobType(id, currentName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('刪除類別'),
            onTap: () {
              Navigator.pop(context);
              _confirmDeleteJobType(id);
            },
          ),
        ],
      ),
    );
  }

  void _editJobType(int id, String oldName) async {
    final TextEditingController controller =
    TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("修改類別名稱"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "新名稱"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("取消")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final token = await storage.read(key: 'access_token');
              final url =
              Uri.parse('$kBaseUrl/jobtypes/$id/');
              final response = await http.put(
                url,
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({'name': controller.text.trim()}),
              );
              if (response.statusCode == 200) {
                _fetchJobTypes();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("修改成功")));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("修改失敗")));
              }
            },
            child: const Text("確定"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteJobType(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("確認刪除"),
        content: const Text("確定要刪除此類別嗎？此動作無法還原。"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("取消")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final token = await storage.read(key: 'access_token');
              final url =
              Uri.parse('$kBaseUrl/jobtypes/$id/');
              final response = await http.delete(
                url,
                headers: {
                  'Authorization': 'Bearer $token',
                },
              );
              if (response.statusCode == 204) {
                _fetchJobTypes();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("刪除成功")));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("刪除失敗")));
              }
            },
            child: const Text("刪除"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text(
          "號誌系統線上緊急故障排除指引",
          style: TextStyle(fontSize: 18),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "登出",
            onPressed: () async {
              await storage.deleteAll();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF00704A)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _userName ?? '使用者',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('員工編號：${_employeeId ?? '未知'}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('修改密碼'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordPage()));
              },
            ),
            if (_userRole == 'A') ...[
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('新增帳號'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateUserPage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('新增作業類別'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/add-jobtype').then((result) {
                    if (result == true) {
                      _fetchJobTypes();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ 已新增類別")));
                    }
                  });
                },
              ),
            ]
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchJobTypes();
          await _fetchPinnedGuides();
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              if (_pinnedGuides.isNotEmpty) ...[
                const Text("📌 置頂工作說明書", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Column(
                  children: _pinnedGuides.map((guide) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 3,
                      child: ListTile(
                        title: Text(guide['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(guide['doc_number'] ?? ''),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeviceListPage(
                                guideId: guide['id'],
                                guideTitle: guide['title'] ?? '',
                              ),
                            ),
                          ).then((_) {
                            _fetchPinnedGuides(); // 回來時刷新置頂列表
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
              const Text("請選擇作業類別：", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _jobTypes.map((job) {
                  return _buildCategoryButton(job['name'], Icons.work, job['id']);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String label, IconData icon, int id) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GuideListPage(jobTypeId: id, jobTypeName: label),
          ),
        );
      },
      onLongPress: () {
        _showJobTypeOptions(id, label);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
