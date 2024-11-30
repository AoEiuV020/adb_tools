import 'package:adb_tools_interface/adb_tools_interface.dart';
import 'package:logging/logging.dart';

import '../services/adb_command.dart';
import '../services/device_storage.dart';
import '../utils/sorted_list.dart';

class DeviceManagerImpl extends DeviceManager {
  static final _logger = Logger('DeviceManager');
  final AdbInterface _adb = AdbCommand();
  final DeviceStorage _storage = DeviceStorage();
  final SortedList<Device> _devices = SortedList<Device>((a, b) {
    // 首先按照 status 的枚举顺序排序
    final statusCompare = a.status.index.compareTo(b.status.index);
    // 如果 status 相同，则按照 address 排序
    return statusCompare != 0 ? statusCompare : a.address.compareTo(b.address);
  });
  bool _isLoading = false;

  @override
  List<Device> get devices => _devices.items;

  @override
  bool get isLoading => _isLoading;

  @override
  AdbInterface get adb => _adb;

  DeviceManagerImpl() {
    _initDevices();
  }

  Future<void> _initDevices() async {
    try {
      final savedDevices = await _storage.loadDevices();
      _devices.addAll(savedDevices);
      await refreshDevices();
    } catch (e, stackTrace) {
      _logger.severe('初始化设备列表失败', e, stackTrace);
    }
  }

  @override
  Future<void> refreshDevices() async {
    _isLoading = true;
    notifyListeners();

    try {
      _logger.info('刷新设备列表');
      final connectedDevices = await _adb.getDevices();

      // 更新现有设备状态
      for (var device in List.from(_devices.items)) {
        final connectedDevice = connectedDevices.firstWhere(
          (d) => d.address == device.address,
          orElse: () => device.copyWith(status: DeviceStatus.disconnected),
        );
        _devices.update(connectedDevice, (d) => d.address == device.address);
      }

      // 添加新设备
      for (var device in connectedDevices) {
        if (!_devices.items.any((d) => d.address == device.address)) {
          _devices.add(device);
        }
      }

      await _storage.saveDevices(_devices.items);
      _logger.info('设备列表刷新完成，共${_devices.length}个设备');
    } catch (e, stackTrace) {
      _logger.severe('刷新设备列表失败', e, stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> addDevice(String address) async {
    try {
      _logger.info('尝试连接设备: $address');

      if (_devices.items.indexWhere((d) => d.address == address) == -1) {
        final device = Device(
          name: '新设备',
          address: address,
          status: DeviceStatus.disconnected,
        );
        _devices.add(device);
        await _storage.saveDevices(_devices.items);
        notifyListeners();
      }

      final success = await _adb.connectDevice(address);
      if (success) {
        final status = await _adb.checkDeviceStatus(address);
        if (status != DeviceStatus.connected) {
          _logger.warning('设备连接失败: $address, 状态: $status');
          return;
        }
        final name = await _adb.getDeviceName(address) ?? '新设备';

        final device = Device(
          name: name,
          address: address,
          status: status,
        );

        _devices.update(
          device,
          (d) => d.address == address,
        );

        await _storage.saveDevices(_devices.items);
        _logger.info('设备连接成功: $address ($name)');
        notifyListeners();
      } else {
        _logger.warning('设备连接失败: $address');
      }
    } catch (e, stackTrace) {
      _logger.severe('连接设备出错: $address', e, stackTrace);
    }
  }

  @override
  Future<void> removeDevice(String address) async {
    try {
      _logger.info('删除设备: $address');
      await _adb.disconnectDevice(address);
      _devices.removeWhere((device) => device.address == address);
      await _storage.saveDevices(_devices.items);
      _logger.info('设备已删除: $address');
      notifyListeners();
    } catch (e, stackTrace) {
      _logger.severe('删除设备失败: $address', e, stackTrace);
    }
  }

  @override
  Future<void> disconnectDevice(String address) async {
    try {
      _logger.info('断开设备连接: $address');
      await _adb.disconnectDevice(address);
      final device = _devices.items.firstWhere((d) => d.address == address);
      _devices.update(
        device.copyWith(status: DeviceStatus.disconnected),
        (d) => d.address == address,
      );
      notifyListeners();
    } catch (e, stackTrace) {
      _logger.severe('断开设备连接失败: $address', e, stackTrace);
    }
  }
}
