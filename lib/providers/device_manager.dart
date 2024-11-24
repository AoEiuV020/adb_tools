import 'package:flutter/foundation.dart';

import 'package:logging/logging.dart';

import '../models/device.dart';
import '../models/device_status.dart';
import '../services/adb_command.dart';
import '../services/adb_interface.dart';
import '../services/device_storage.dart';

class DeviceManager extends ChangeNotifier {
  static final _logger = Logger('DeviceManager');
  final AdbInterface _adb = AdbCommand();
  final DeviceStorage _storage = DeviceStorage();
  final List<Device> _devices = [];
  bool _isLoading = false;

  List<Device> get devices => List.unmodifiable(_devices);
  bool get isLoading => _isLoading;

  DeviceManager() {
    _initDevices();
  }

  Future<void> _initDevices() async {
    try {
      // 加载历史设备
      final savedDevices = await _storage.loadDevices();
      _devices.addAll(savedDevices);
      // 刷新设备状态
      await refreshDevices();
    } catch (e, stackTrace) {
      _logger.severe('初始化设备列表失败', e, stackTrace);
    }
  }

  Future<void> refreshDevices() async {
    _isLoading = true;
    notifyListeners();

    try {
      _logger.info('刷新设备列表');
      final connectedDevices = await _adb.getDevices();

      // 更新现有设备的状态
      for (var device in _devices) {
        final connectedDevice = connectedDevices.firstWhere(
          (d) => d.address == device.address,
          orElse: () => device.copyWith(status: DeviceStatus.disconnected),
        );
        final index = _devices.indexWhere((d) => d.address == device.address);
        if (index != -1) {
          _devices[index] = connectedDevice;
        }
      }

      // 添加新设备
      for (var device in connectedDevices) {
        if (!_devices.any((d) => d.address == device.address)) {
          _devices.add(device);
        }
      }

      // 保存设备列表
      await _storage.saveDevices(_devices);

      _logger.info('设备列表刷新完成，共${_devices.length}个设备');
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

        // 检查设备是否已存在
        final index = _devices.indexWhere((d) => d.address == address);
        final device = Device(
          name: name,
          address: address,
          status: status,
        );

        if (index != -1) {
          _devices[index] = device;
        } else {
          _devices.add(device);
        }

        await _storage.saveDevices(_devices);
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
      _logger.info('删除设备: $address');
      await _adb.disconnectDevice(address);
      _devices.removeWhere((device) => device.address == address);
      await _storage.saveDevices(_devices);
      _logger.info('设备已删除: $address');
      notifyListeners();
    } catch (e, stackTrace) {
      _logger.severe('删除设备失败: $address', e, stackTrace);
    }
  }

  Future<void> disconnectDevice(String address) async {
    try {
      _logger.info('断开设备连接: $address');
      await _adb.disconnectDevice(address);
      final index = _devices.indexWhere((d) => d.address == address);
      if (index != -1) {
        _devices[index] =
            _devices[index].copyWith(status: DeviceStatus.disconnected);
        notifyListeners();
      }
    } catch (e, stackTrace) {
      _logger.severe('断开设备连接失败: $address', e, stackTrace);
    }
  }
}
