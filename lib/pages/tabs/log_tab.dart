import 'package:flutter/material.dart';

import 'package:adb_tools_interface/adb_tools_interface.dart';

class LogTab extends DeviceTab {
  const LogTab()
      : super(
          label: '日志',
          icon: Icons.article,
        );

  @override
  Widget buildTabContent(
      BuildContext context, Device device, DeviceManager deviceManager) {
    return const Center(child: Text('日志查看功能开发中...'));
  }
}
