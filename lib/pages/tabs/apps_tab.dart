import 'package:flutter/material.dart';

import 'package:adb_tools_interface/adb_tools_interface.dart';

class AppsTab extends DeviceTab {
  const AppsTab()
      : super(
          label: '应用',
          icon: Icons.apps,
        );

  @override
  Widget buildTabContent(
      BuildContext context, Device device, DeviceManager deviceManager) {
    return const Center(child: Text('应用管理功能开发中...'));
  }
}
