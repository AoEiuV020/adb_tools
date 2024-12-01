import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

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
        _logger.finest('命令输出: ${result.stdout}');
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

  @override
  Future<List<String>> getPackageList(
    String deviceAddress, {
    bool showSystemApps = true,
    bool showDisabledApps = true,
  }) async {
    final args = ['-s', deviceAddress, 'shell', 'pm', 'list', 'packages'];

    // 如果不显示系统应用,添加-3参数
    if (!showSystemApps) {
      args.add('-3');
    }

    // 如果只显示启用的应用,添加-e参数
    if (!showDisabledApps) {
      args.add('-e');
    }

    final result = await _runCommand(args);
    return result.stdout
        .toString()
        .split('\n')
        .where((line) => line.isNotEmpty)
        .map((line) => line.substring(8)) // 移除"package:"前缀
        .toList();
  }

  // 使用visibleForTesting限制可见性
  @visibleForTesting
  static (String?, String?) parseVersionInfo(String dumpsysOutput) {
    String? versionName;
    String? versionCode;

    // 修改正则表达式,分开匹配versionName和versionCode
    final codeMatch = RegExp(r'versionCode=(\d+)').firstMatch(dumpsysOutput);
    if (codeMatch != null) {
      versionCode = codeMatch.group(1);
    }

    final nameMatch = RegExp(r'versionName=([^\s]+)').firstMatch(dumpsysOutput);
    if (nameMatch != null) {
      versionName = nameMatch.group(1);
    }

    return (versionName, versionCode);
  }

  @visibleForTesting
  static (DateTime?, DateTime?) parseInstallTime(String dumpsysOutput) {
    DateTime? installTime;
    DateTime? updateTime;

    // 修改正则表达式以匹配日期时间格式
    final installMatches =
        RegExp(r'firstInstallTime=(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})')
            .allMatches(dumpsysOutput)
            .toList();
    final updateMatches =
        RegExp(r'lastUpdateTime=(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})')
            .allMatches(dumpsysOutput)
            .toList();

    // 取第一个匹配项
    if (installMatches.isNotEmpty) {
      try {
        final timeStr = installMatches.first.group(1)!;
        installTime = DateTime.parse(timeStr.replaceAll(' ', 'T'));
      } catch (e) {
        // 解析失败时返回null
      }
    }

    if (updateMatches.isNotEmpty) {
      try {
        final timeStr = updateMatches.first.group(1)!;
        updateTime = DateTime.parse(timeStr.replaceAll(' ', 'T'));
      } catch (e) {
        // 解析失败时返回null
      }
    }

    return (installTime, updateTime);
  }

  @visibleForTesting
  static bool parseSystemApp(String dumpsysOutput) {
    // 在flags或pkgFlags中查找SYSTEM标记
    final flagsMatch =
        RegExp(r'(?:flags|pkgFlags)=\[ ([^\]]+) \]').firstMatch(dumpsysOutput);
    if (flagsMatch != null) {
      final flags = flagsMatch.group(1)!.split(' ');
      return flags.contains('SYSTEM');
    }
    return false;
  }

  // 修改这个方法,不再使用parseEnabled
  @visibleForTesting
  static (bool, bool) parseAppStatus(String dumpsysOutput) {
    return (
      false,
      parseSystemApp(dumpsysOutput)
    ); // enabled默认为false,由isAppDisabled方法判断
  }

  @override
  Future<AppInfo> getAppInfo(String deviceAddress, String packageName) async {
    final dumpsys = await _runCommand([
      '-s',
      deviceAddress,
      'shell',
      'dumpsys',
      'package',
      packageName,
    ]);
    final output = dumpsys.stdout.toString();

    // 使用新方法检查停用状态
    final enabled = !await isAppDisabled(deviceAddress, packageName);
    final isSystemApp = parseSystemApp(output);
    final (versionName, versionCode) = parseVersionInfo(output);
    final (installTime, updateTime) = parseInstallTime(output);

    // 获取应用名称
    final appName = await _getAppName(deviceAddress, packageName);

    // 获取应用图标
    final icon = await getAppIcon(deviceAddress, packageName);

    // 获取应用大小
    final size = await getAppSize(deviceAddress, packageName);

    // 检查运行状态
    final isRunning = await isAppRunning(deviceAddress, packageName);

    return AppInfo(
      packageName: packageName,
      appName: appName,
      versionName: versionName,
      versionCode: versionCode,
      installTime: installTime,
      updateTime: updateTime,
      enabled: enabled,
      size: size,
      isSystemApp: isSystemApp,
      isRunning: isRunning,
      icon: icon,
    );
  }

  Future<String?> _getAppName(String deviceAddress, String packageName) async {
    // 暂时无法获取，
    // 可行的方案有， aapt解析apk文件， 但手机上没有aapt，电脑上没有apk，太麻烦了，
    return null;
  }

  @override
  Future<Uint8List?> getAppIcon(
      String deviceAddress, String packageName) async {
    // 暂时无法获取，
    return null;
  }

  @override
  Future<int?> getAppSize(String deviceAddress, String packageName) async {
    try {
      // 1. 获取APK文件路径
      final pathResult = await _runCommand([
        '-s',
        deviceAddress,
        'shell',
        'pm',
        'path',
        packageName,
      ]);

      if (pathResult.exitCode != 0) return null;

      // 2. 从输出中提取路径
      final apkPath = pathResult.stdout
          .toString()
          .trim()
          .split('\n')
          .firstWhere(
            (line) => line.startsWith('package:'),
            orElse: () => '',
          )
          .substring(8); // 移除"package:"前缀

      if (apkPath.isEmpty) return null;

      // 3. 获取文件大小
      final sizeResult = await _runCommand([
        '-s',
        deviceAddress,
        'shell',
        'stat',
        '-c',
        '%s',
        apkPath,
      ]);

      return int.tryParse(sizeResult.stdout.toString().trim());
    } catch (e) {
      _logger.warning('获取应用大小失败: $packageName', e);
      return null;
    }
  }

  @override
  Future<bool> isAppRunning(String deviceAddress, String packageName) async {
    try {
      // 先用grep过滤,减少输出数据量
      final result = await _runCommand([
        '-s',
        deviceAddress,
        'shell',
        'ps',
        '-A',
        '|',
        'grep',
        packageName,
      ]);

      // 再精确匹配包名
      return result.stdout
          .toString()
          .split('\n')
          .where((line) => line.isNotEmpty)
          .any((line) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.isEmpty) return false;

        // 进程名在最后一列
        final processName = parts.last;
        // 精确匹配包名
        return processName == packageName;
      });
    } catch (e) {
      _logger.warning('检查应用运行状态失败: $packageName', e);
      return false;
    }
  }

  @override
  Future<bool> launchApp(String deviceAddress, String packageName) async {
    try {
      final result = await _runCommand([
        '-s',
        deviceAddress,
        'shell',
        'monkey',
        '-p',
        packageName,
        '-c',
        'android.intent.category.LAUNCHER',
        '1'
      ]);
      return result.exitCode == 0;
    } catch (e) {
      _logger.warning('启动应用失败: $packageName', e);
      return false;
    }
  }

  @override
  Future<bool> stopApp(String deviceAddress, String packageName) async {
    try {
      final result = await _runCommand(
          ['-s', deviceAddress, 'shell', 'am', 'force-stop', packageName]);
      return result.exitCode == 0;
    } catch (e) {
      _logger.warning('停止应用失败: $packageName', e);
      return false;
    }
  }

  @override
  Future<bool> uninstallApp(String deviceAddress, String packageName) async {
    try {
      final result =
          await _runCommand(['-s', deviceAddress, 'uninstall', packageName]);
      return result.exitCode == 0;
    } catch (e) {
      _logger.warning('卸载应用失败: $packageName', e);
      return false;
    }
  }

  @override
  Future<bool> enableApp(String deviceAddress, String packageName) async {
    try {
      final result = await _runCommand(
          ['-s', deviceAddress, 'shell', 'pm', 'enable', packageName]);
      return result.exitCode == 0;
    } catch (e) {
      _logger.warning('启用应用失败: $packageName', e);
      return false;
    }
  }

  @override
  Future<bool> disableApp(String deviceAddress, String packageName) async {
    try {
      final result = await _runCommand(
          ['-s', deviceAddress, 'shell', 'pm', 'disable-user', packageName]);
      return result.exitCode == 0;
    } catch (e) {
      _logger.warning('停用应用失败: $packageName', e);
      return false;
    }
  }

  @override
  Future<bool> isAppDisabled(String deviceAddress, String packageName) async {
    try {
      final result = await _runCommand([
        '-s',
        deviceAddress,
        'shell',
        'pm',
        'list',
        'packages',
        '-d',
        packageName,
      ]);

      // 使用精确匹配而不是包含
      return result.stdout
          .toString()
          .split('\n')
          .where((line) => line.isNotEmpty)
          .map((line) => line.substring(8)) // 移除"package:"前缀
          .any((pkg) => pkg == packageName); // 使用相等判断
    } catch (e) {
      _logger.warning('检查应用停用状态失败: $packageName', e);
      return false;
    }
  }

  @override
  Future<String?> getAppName(String deviceAddress, String packageName) async {
    // 暂时返回null,等后续实现
    return null;
  }

  @override
  Future<(String?, String?)> getAppVersion(
      String deviceAddress, String packageName) async {
    try {
      final dumpsys = await _runCommand([
        '-s',
        deviceAddress,
        'shell',
        'dumpsys',
        'package',
        packageName,
      ]);
      return parseVersionInfo(dumpsys.stdout.toString());
    } catch (e) {
      _logger.warning('获取应用版本信息失败: $packageName', e);
      return (null, null);
    }
  }

  @override
  Future<(DateTime?, DateTime?)> getAppInstallTime(
      String deviceAddress, String packageName) async {
    try {
      final dumpsys = await _runCommand([
        '-s',
        deviceAddress,
        'shell',
        'dumpsys',
        'package',
        packageName,
      ]);
      return parseInstallTime(dumpsys.stdout.toString());
    } catch (e) {
      _logger.warning('获取应用安装时间失败: $packageName', e);
      return (null, null);
    }
  }

  @override
  Future<bool> isSystemApp(String deviceAddress, String packageName) async {
    try {
      final dumpsys = await _runCommand([
        '-s',
        deviceAddress,
        'shell',
        'dumpsys',
        'package',
        packageName,
      ]);
      return parseSystemApp(dumpsys.stdout.toString());
    } catch (e) {
      _logger.warning('检查系统应用失败: $packageName', e);
      return false;
    }
  }
}
