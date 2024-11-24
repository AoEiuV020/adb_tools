import 'package:flutter/foundation.dart';

import '../models/device.dart';
import '../models/device_status.dart';

class DeviceManager extends ChangeNotifier {
  final List<Device> _devices = [
    // 测试数据
    const Device(
      name: '测试设备1',
      status: DeviceStatus.connected,
      address: '192.168.1.100:5555',
    ),
    const Device(
      name: '测试设备2',
      status: DeviceStatus.offline,
      address: '192.168.1.101:5555',
    ),
    const Device(
      name: '测试设备3',
      status: DeviceStatus.unauthorized,
      address: '192.168.1.102:5555',
    ),
  ];

  List<Device> get devices => List.unmodifiable(_devices);

  void addDevice(String address) {
    // TODO: 实际连接逻辑
    final newDevice = Device(
      name: '新设备',
      address: address,
      status: DeviceStatus.connecting,
    );

    _devices.add(newDevice);
    notifyListeners();
  }

  void removeDevice(String address) {
    _devices.removeWhere((device) => device.address == address);
    notifyListeners();
  }

  void updateDeviceStatus(String address, DeviceStatus status) {
    final index = _devices.indexWhere((device) => device.address == address);
    if (index != -1) {
      _devices[index] = _devices[index].copyWith(status: status);
      notifyListeners();
    }
  }
}
