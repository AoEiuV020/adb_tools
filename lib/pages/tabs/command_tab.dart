import 'package:flutter/material.dart';

import 'package:adb_tools_interface/adb_tools_interface.dart';

class CommandTab extends DeviceTab {
  const CommandTab()
      : super(
          label: '命令行',
          icon: Icons.terminal,
        );

  @override
  Widget buildTabContent(
      BuildContext context, Device device, AdbInterface adb) {
    return const Center(child: Text('命令行功能开发中...'));
  }
}
