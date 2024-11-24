import 'package:flutter/material.dart';

import '../models/device.dart';

class DevicePage extends StatelessWidget {
  final Device device;

  const DevicePage({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: '命令行', icon: Icon(Icons.terminal)),
                Tab(text: '文件', icon: Icon(Icons.folder)),
                Tab(text: '应用', icon: Icon(Icons.apps)),
                Tab(text: '日志', icon: Icon(Icons.article)),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTerminalTab(),
                  _buildFileTab(),
                  _buildAppsTab(),
                  _buildLogTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalTab() {
    return const Center(child: Text('命令行功能开发中...'));
  }

  Widget _buildFileTab() {
    return const Center(child: Text('文件管理功能开发中...'));
  }

  Widget _buildAppsTab() {
    return const Center(child: Text('应用管理功能开发中...'));
  }

  Widget _buildLogTab() {
    return const Center(child: Text('日志查看功能开发中...'));
  }
}
