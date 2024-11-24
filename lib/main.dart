import 'package:flutter/material.dart';

import 'package:adb_tools_interface/adb_tools_interface.dart';
import 'package:provider/provider.dart';

import 'pages/home_page.dart';
import 'providers/device_manager_impl.dart';
import 'utils/logger.dart';

void main() {
  AppLogger.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DeviceManager>(
      create: (_) => DeviceManagerImpl(),
      child: MaterialApp(
        title: 'ADB工具',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}
