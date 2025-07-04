import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'pages/splash.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false, // 🔧 隱藏 DEBUG 標籤
      theme: AppTheme.nrtcTheme, // 使用統一樣式
      home: const SplashPage(),   // 起始頁
    ),
  );
}
