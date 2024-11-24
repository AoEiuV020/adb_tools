import 'package:flutter/material.dart';

import '../models/device.dart';
import '../services/adb_interface.dart';

abstract class DeviceTab {
  final String label;
  final IconData icon;

  const DeviceTab({
    required this.label,
    required this.icon,
  });

  Widget buildTabContent(BuildContext context, Device device, AdbInterface adb);
}
