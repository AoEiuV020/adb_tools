import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:adb_tools_interface/adb_tools_interface.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:logging/logging.dart';

/// Pty 的具体实现
class _PtyShell implements Shell {
  final Pty _pty;
  final StreamController<Uint8List> _stdinController;

  _PtyShell(this._pty) : _stdinController = StreamController<Uint8List>() {
    _stdinController.stream.listen((data) {
      _pty.write(data);
    });
  }

  @override
  StreamSink<Uint8List> get stdin => _stdinController.sink;

  @override
  Stream<Uint8List> get stdout => _pty.output;

  @override
  Stream<Uint8List> get stderr =>
      const Stream.empty(); // PTY 合并了 stdout 和 stderr

  @override
  Future<void> terminate() async {
    await _stdinController.close();
    _pty.kill();
  }
}

class AdbCommand implements AdbInterface {
  static final _logger = Logger('AdbCommand');
  static const String _adbPath = 'adb'; // TODO: 根据平台配置正确的adb路径

  Future<ProcessResult> _runCommand(List<String> arguments) async {
    try {
      _logger.info('执行ADB命令: $_adbPath ${arguments.join(' ')}');
      // 在mac上如果没有runInShell，会闪退，在finder中启动会闪退无法拦截， open或者可执行文件启动正常，
      // 可能是不会继承shell的环境变量，找不到adb命令，奇怪的是直接调试启动就算找不到也不会闪退，
      final result = await Process.run(_adbPath, arguments, runInShell: true);

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
    final xiaomiName = await getXiaomiDeviceName(address);
    if (xiaomiName != null) {
      return xiaomiName;
    }
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

  Future<String?> getXiaomiDeviceName(String address) async {
    try {
      // 尝试获取设备型号
      final modelResult = await _runCommand(
          ['-s', address, 'shell', 'getprop', 'ro.product.marketname']);

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

  @override
  Future<Shell> startShell(String address) async {
    try {
      _logger.info('启动设备 Shell: $address');

      if (kIsWeb) {
        throw UnsupportedError('Web平台暂不支持终端功能');
      }

      final environment = <String, String>{
        'ANDROID_SERIAL': address,
        // 没有这个的话adb无法复用daemon，会试图新建一个，导致冲突，
        ...Platform.environment,
      };
      Pty pty;
      if (Platform.isWindows) {
        pty = Pty.start(
          'cmd',
          arguments: ['/C', _adbPath, 'shell'],
          environment: environment,
          workingDirectory: '/',
        );
      } else {
        pty = Pty.start(
          _adbPath,
          arguments: ['shell'],
          environment: environment,
          workingDirectory: '/',
        );
      }
      return _PtyShell(pty);
    } catch (e, stackTrace) {
      _logger.severe('启动设备 Shell 失败', e, stackTrace);
      rethrow;
    }
  }
}
