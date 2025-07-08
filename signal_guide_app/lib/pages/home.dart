import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  DateTime? _lastBackPressed; // 加在 _HomePageState 裡

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final storage = FlutterSecureStorage();
    final name = await storage.read(key: 'name');
    final id = await storage.read(key: 'employee_id');
    final role = await storage.read(key: 'role');
    setState(() {
      _userName = name;
      _employeeId = id;
      _userRole = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // 1. Drawer 開啟時，先關掉 Drawer
        if (_scaffoldKey.currentState?.isDrawerOpen == true) {
          Navigator.of(context).pop();
          return;
        }

        // 判斷是否為第一次按返回鍵
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

        // 3. 第二次返回鍵 → 結束 App
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
                final storage = FlutterSecureStorage();
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
                decoration: const BoxDecoration(
                  color: Color(0xFF00704A),
                ),
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
              if (_employeeId == 'A0000') // ✅ 只有特定員工編號才顯示
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('後台管理'),
                  onTap: () async {
                    Navigator.pop(context);
                    const url = 'http://10.0.2.2:8000/admin/';
                    // 嘗試用瀏覽器開啟（使用 url_launcher 套件）
                    // 若尚未加入依賴請見下方說明
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
                    print("點選：新增帳號");
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
              GestureDetector(
                onTap: () => print("查看工作說明書"),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00704A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description, color: Colors.white),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "QM系WI92073高運量號誌系統線上故障緊急排除工作說明書(16)",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text("請選擇作業類別：", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildCategoryButton("行政管理", Icons.account_balance),
                    _buildCategoryButton("故障檢修", Icons.build),
                    _buildCategoryButton("特別檢修", Icons.engineering),
                    _buildCategoryButton("預防檢修", Icons.shield),
                    _buildCategoryButton("維修管理", Icons.settings),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String label, IconData icon) {
    return ElevatedButton(
      onPressed: () => print("點選分類：$label"),
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
