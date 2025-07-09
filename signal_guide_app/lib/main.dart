import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'pages/splash.dart';
import 'pages/jobtype_form.dart';
import 'pages/device_form.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false, // 🔧 隱藏 DEBUG 標籤
      theme: AppTheme.nrtcTheme, // 使用統一樣式
      home: const SplashPage(),   // 起始頁
      routes: {
        '/add-jobtype': (context) => const JobTypeFormPage(),
        '/add-device': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return DeviceFormPage(
            guideId: args['guideId'],
            guideTitle: args['guideTitle'],
            device: args['device'],
          );
        },
      },
    ),
  );
}
