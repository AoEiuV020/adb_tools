import 'package:flutter/material.dart';

import '../../models/device.dart';
import '../../models/device_tab.dart';
import '../../services/adb_interface.dart';

class LogTab extends DeviceTab {
  const LogTab()
      : super(
          label: '日志',
          icon: Icons.article,
        );

  @override
  Widget buildTabContent(
      BuildContext context, Device device, AdbInterface adb) {
    return const Center(child: Text('日志查看功能开发中...'));
  }
}
