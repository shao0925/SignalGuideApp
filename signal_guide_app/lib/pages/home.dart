import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'login.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _userName;
  String? _employeeId;
  String? _userRole;

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
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          titleSpacing: 12
          ,
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
                await storage.deleteAll(); // 清除 access_token, refresh_token, role, name, employee_id

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
              if (_userRole == 'A') ...[
                ListTile(
                  leading: const Icon(Icons.person_add),
                  title: const Text('新增帳號'),
                  onTap: () {
                    Navigator.pop(context);
                    print("點選：新增帳號");
                    // Navigator.push(...); // 若未來要跳頁
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
              ListTile(
                leading: const Icon(Icons.book),
                title: const Text('查詢工作說明書'),
                onTap: () {
                  Navigator.pop(context);
                  print("點選：查詢工作說明書");
                },
              ),
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
              const Text("請選擇問題分類：", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildCategoryButton("電源系統", Icons.bolt),
                    _buildCategoryButton("通訊模組", Icons.wifi),
                    _buildCategoryButton("控制器", Icons.memory),
                    _buildCategoryButton("燈號問題", Icons.traffic),
                    _buildCategoryButton("現場回報", Icons.report_problem),
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
