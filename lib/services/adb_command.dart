import 'dart:io';

import 'package:adb_tools_interface/adb_tools_interface.dart';
import 'package:logging/logging.dart';

class AdbCommand implements AdbInterface {
  static final _logger = Logger('AdbCommand');
  static const String _adbPath = 'adb'; // TODO: 根据平台配置正确的adb路径

  Future<ProcessResult> _runCommand(List<String> arguments) async {
    try {
      _logger.info('执行ADB命令: $_adbPath ${arguments.join(' ')}');
      final result = await Process.run(_adbPath, arguments);

      if (result.stdout.toString().isNotEmpty) {
        _logger.fine('命令输出: ${result.stdout}');
      }

      if (result.stderr.toString().isNotEmpty) {
        _logger.warning('错误输出: ${result.stderr}');
      }

      return result;
    } catch (e, stackTrace) {
      _logger.severe('ADB命令执行失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Device>> getDevices() async {
    final result = await _runCommand(['devices', '-l']);
    if (result.exitCode != 0) {
      throw Exception('获取设备列表失败: ${result.stderr}');
    }

    final lines = result.stdout.toString().split('\n');
    final devices = <Device>[];

    // 跳过第一行 "List of devices attached"
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        final address = parts[0];
        final statusStr = parts[1];

        // 获取设备名称
        final name = await getDeviceName(address) ?? address;

        // 解析设备状态
        DeviceStatus status;
        switch (statusStr) {
          case 'device':
            status = DeviceStatus.connected;
            break;
          case 'offline':
            status = DeviceStatus.offline;
            break;
          case 'unauthorized':
            status = DeviceStatus.unauthorized;
            break;
          default:
            status = DeviceStatus.disconnected;
        }

        devices.add(Device(
          name: name,
          address: address,
          status: status,
        ));
      }
    }

    return devices;
  }

  @override
  Future<bool> connectDevice(String address) async {
    final result = await _runCommand(['connect', address]);
    return result.exitCode == 0 &&
        !result.stdout.toString().contains('failed to connect');
  }

  @override
  Future<bool> disconnectDevice(String address) async {
    final result = await _runCommand(['disconnect', address]);
    return result.exitCode == 0;
  }

  @override
  Future<DeviceStatus> checkDeviceStatus(String address) async {
    final devices = await getDevices();
    final device = devices.firstWhere(
      (d) => d.address == address,
      orElse: () => Device(
        name: address,
        address: address,
        status: DeviceStatus.disconnected,
      ),
    );
    return device.status;
  }

  @override
  Future<String?> getDeviceName(String address) async {
    try {
      // 尝试获取设备型号
      final modelResult = await _runCommand(
          ['-s', address, 'shell', 'getprop', 'ro.product.model']);

      if (modelResult.exitCode == 0) {
        final model = modelResult.stdout.toString().trim();
        if (model.isNotEmpty) {
          return model;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
