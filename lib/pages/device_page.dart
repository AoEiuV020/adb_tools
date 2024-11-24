import 'package:flutter/material.dart';

import 'package:adb_tools_interface/adb_tools_interface.dart';
import 'package:adb_tools_tab_command/adb_tools_tab_command.dart';
import 'package:provider/provider.dart';

import 'tabs/apps_tab.dart';
import 'tabs/file_tab.dart';
import 'tabs/log_tab.dart';

class DevicePage extends StatelessWidget {
  final Device device;

  // 定义所有可用的标签
  static const List<DeviceTab> _tabs = [
    CommandTab(),
    FileTab(),
    AppsTab(),
    LogTab(),
  ];

  const DevicePage({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    final deviceManager = context.read<DeviceManager>();

    return DefaultTabController(
      length: _tabs.length,
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelStyle: const TextStyle(fontSize: 14),
                tabs: _tabs
                    .map((tab) => Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(tab.icon),
                              const SizedBox(width: 8),
                              Text(tab.label),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: _tabs
              .map((tab) => tab.buildTabContent(context, device, deviceManager))
              .toList(),
        ),
      ),
    );
  }
}
