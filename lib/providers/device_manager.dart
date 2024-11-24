import 'package:flutter/foundation.dart';

import 'package:logging/logging.dart';

import '../models/device.dart';
import '../services/adb_command.dart';
import '../services/adb_interface.dart';

class DeviceManager extends ChangeNotifier {
  static final _logger = Logger('DeviceManager');
  final AdbInterface _adb = AdbCommand();
  final List<Device> _devices = [];
  bool _isLoading = false;

  List<Device> get devices => List.unmodifiable(_devices);
  bool get isLoading => _isLoading;

  DeviceManager() {
    refreshDevices();
  }

  Future<void> refreshDevices() async {
    _isLoading = true;
    notifyListeners();

    try {
      _logger.info('刷新设备列表');
      final devices = await _adb.getDevices();
      _devices.clear();
      _devices.addAll(devices);
      _logger.info('设备列表刷新完成，共${devices.length}个设备');
    } catch (e, stackTrace) {
      _logger.severe('刷新设备列表失败', e, stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDevice(String address) async {
    try {
      _logger.info('尝试连接设备: $address');
      final success = await _adb.connectDevice(address);
      if (success) {
        final status = await _adb.checkDeviceStatus(address);
        final name = await _adb.getDeviceName(address) ?? '新设备';

        _devices.add(Device(
          name: name,
          address: address,
          status: status,
        ));
        _logger.info('设备连接成功: $address ($name)');
        notifyListeners();
      } else {
        _logger.warning('设备连接失败: $address');
      }
    } catch (e, stackTrace) {
      _logger.severe('连接设备出错: $address', e, stackTrace);
    }
  }

  Future<void> removeDevice(String address) async {
    try {
      _logger.info('尝试断开设备连接: $address');
      await _adb.disconnectDevice(address);
      _devices.removeWhere((device) => device.address == address);
      _logger.info('设备已断开连接: $address');
      notifyListeners();
    } catch (e, stackTrace) {
      _logger.severe('断开设备连接失败: $address', e, stackTrace);
    }
  }
}
