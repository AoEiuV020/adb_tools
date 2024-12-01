import 'dart:typed_data';

import '../../adb_tools_interface.dart';

abstract class AdbInterface {
  /// 获取已连接的设备列表
  Future<List<Device>> getDevices();

  /// 连接设备
  Future<bool> connectDevice(String address);

  /// 断开设备连接
  Future<bool> disconnectDevice(String address);

  /// 检查设备连接状态
  Future<DeviceStatus> checkDeviceStatus(String address);

  /// 获取设备名称
  Future<String?> getDeviceName(String address);

  /// 启动一个交互式的 ADB Shell
  Future<Shell> startShell(String address);

  /// 获取设备上的应用包名列表
  /// [showSystemApps] 是否包含系统应用
  /// [showDisabledApps] 是否包含已停用应用
  Future<List<String>> getPackageList(
    String deviceAddress, {
    bool showSystemApps = true,
    bool showDisabledApps = true,
  });

  /// 获取应用名称
  Future<String?> getAppName(String deviceAddress, String packageName);

  /// 获取应用版本号
  Future<(String?, String?)> getAppVersion(
      String deviceAddress, String packageName);

  /// 获取应用安装时间
  Future<(DateTime?, DateTime?)> getAppInstallTime(
      String deviceAddress, String packageName);

  /// 检查应用是否为系统应用
  Future<bool> isSystemApp(String deviceAddress, String packageName);

  /// 获取应用图标
  Future<Uint8List?> getAppIcon(String deviceAddress, String packageName);

  /// 获取应用大小
  Future<int?> getAppSize(String deviceAddress, String packageName);

  /// 检查应用是否正在运行
  Future<bool> isAppRunning(String deviceAddress, String packageName);

  /// 启动应用
  Future<bool> launchApp(String deviceAddress, String packageName);

  /// 停止应用
  Future<bool> stopApp(String deviceAddress, String packageName);

  /// 卸载应用
  Future<bool> uninstallApp(String deviceAddress, String packageName);

  /// 启用应用
  Future<bool> enableApp(String deviceAddress, String packageName);

  /// 禁用应用
  Future<bool> disableApp(String deviceAddress, String packageName);

  /// 检查应用是否被停用
  /// 返回true表示应用已停用
  Future<bool> isAppDisabled(String deviceAddress, String packageName);

  /// 获取应用的所有信息
  Future<AppInfo> getAppInfo(String deviceAddress, String packageName);
}
