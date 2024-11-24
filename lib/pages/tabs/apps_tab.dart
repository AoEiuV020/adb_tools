import 'package:flutter/material.dart';

import '../../models/device.dart';
import '../../models/device_tab.dart';
import '../../services/adb_interface.dart';

class AppsTab extends DeviceTab {
  const AppsTab()
      : super(
          label: '应用',
          icon: Icons.apps,
        );

  @override
  Widget buildTabContent(
      BuildContext context, Device device, AdbInterface adb) {
    return const Center(child: Text('应用管理功能开发中...'));
  }
}
