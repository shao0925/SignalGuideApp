import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'login.dart';
import 'create_user.dart';
import 'change_password.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchJobTypes();
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
    print('access token: $token');
    final url = Uri.parse('http://10.0.2.2:8000/api/jobtypes/');
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
      } else {
        print('取得分類失敗：${response.statusCode}');
      }
    } catch (e) {
      print('錯誤：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_scaffoldKey.currentState?.isDrawerOpen == true) {
          Navigator.of(context).pop();
          return;
        }
        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('再按一次返回鍵退出系統'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        Navigator.of(context).maybePop();
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          automaticallyImplyLeading: true,
          titleSpacing: 12,
          title: const Text(
            "號誌系統線上緊急故障排除指引",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 20),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '員工編號：${_employeeId ?? '未知'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              if (_employeeId == 'A0000')
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('後台管理'),
                  onTap: () async {
                    Navigator.pop(context);
                    const url = 'http://10.0.2.2:8000/admin/';
                    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
                      throw Exception('無法開啟後台管理');
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('修改密碼'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
                  );
                },
              ),
              if (_userRole == 'A') ...[
                ListTile(
                  leading: const Icon(Icons.person_add),
                  title: const Text('新增帳號'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateUserPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.note_add),
                  title: const Text('新增工作說明書'),
                  onTap: () {
                    Navigator.pop(context);
                    print("點選：新增工作說明書");
                  },
                ),
              ],
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("請選擇作業類別：", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: _jobTypes.map((job) {
                    return _buildCategoryButton(job['name'], Icons.work, job['id']);
                  }).toList(),
                ),
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
        print("點選分類：$label（ID: $id）");
        // TODO: 導向到該類別的工作說明書列表頁面
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
