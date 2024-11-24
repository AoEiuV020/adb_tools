import 'dart:convert';

import 'package:adb_tools_interface/adb_tools_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceStorage {
  static const String _key = 'device_history';

  Future<List<Device>> loadDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceList = prefs.getStringList(_key) ?? [];

    return deviceList.map((deviceJson) {
      final map = json.decode(deviceJson) as Map<String, dynamic>;
      return Device(
        name: map['name'] as String,
        address: map['address'] as String,
        status: DeviceStatus.disconnected, // 初始状态都设为断开
      );
    }).toList();
  }

  Future<void> saveDevices(List<Device> devices) async {
    final prefs = await SharedPreferences.getInstance();
    final deviceList = devices.map((device) {
      return json.encode({
        'name': device.name,
        'address': device.address,
      });
    }).toList();

    await prefs.setStringList(_key, deviceList);
  }
}
