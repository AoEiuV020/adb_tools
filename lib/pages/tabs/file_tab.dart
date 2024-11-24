import 'package:flutter/material.dart';

import '../../models/device.dart';
import '../../models/device_tab.dart';
import '../../services/adb_interface.dart';

class FileTab extends DeviceTab {
  const FileTab()
      : super(
          label: '文件',
          icon: Icons.folder,
        );

  @override
  Widget buildTabContent(
      BuildContext context, Device device, AdbInterface adb) {
    return const Center(child: Text('文件管理功能开发中...'));
  }
}
