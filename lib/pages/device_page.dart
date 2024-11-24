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
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(device.name),
              Text(
                device.address,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelStyle: TextStyle(fontSize: 14),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.terminal),
                        SizedBox(width: 8),
                        Text('命令行'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder),
                        SizedBox(width: 8),
                        Text('文件'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.apps),
                        SizedBox(width: 8),
                        Text('应用'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.article),
                        SizedBox(width: 8),
                        Text('日志'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildTerminalTab(),
            _buildFileTab(),
            _buildAppsTab(),
            _buildLogTab(),
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
