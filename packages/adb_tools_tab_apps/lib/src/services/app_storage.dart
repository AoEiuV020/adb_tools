import 'dart:typed_data';

import 'package:adb_tools_interface/adb_tools_interface.dart';
import 'package:logging/logging.dart';
import 'package:iron_db/iron_db.dart';

class AppStorage {
  static final _logger = Logger('AppStorageImpl');

  late final Database _baseDir;
  late final Database _appInfoDir;
  late final Database _iconDir;

  Future<void> init() async {
    _baseDir = Iron.db.sub('apps');
    _logger.info('AppStorage baseDir: ${_baseDir.getPath()}');
    _appInfoDir = _baseDir.sub('appInfo');
    _iconDir = _baseDir.sub('icon');
  }

  Future<void> saveAppInfo(String deviceId, AppInfo appInfo) async {
    try {
      // 保存图标
      if (appInfo.icon != null) {
        await _iconDir.sub(deviceId).write(appInfo.packageName, appInfo.icon!);
      }

      // 序列化应用信息
      final Map<String, dynamic> data = {
        'packageName': appInfo.packageName,
        'appName': appInfo.appName,
        'versionName': appInfo.versionName,
        'versionCode': appInfo.versionCode,
        'installTime': appInfo.installTime?.toIso8601String(),
        'updateTime': appInfo.updateTime?.toIso8601String(),
        'enabled': appInfo.enabled,
        'size': appInfo.size,
        'isSystemApp': appInfo.isSystemApp,
        'isRunning': appInfo.isRunning,
        'isFullyLoaded': appInfo.isFullyLoaded,
      };

      await _appInfoDir.sub(deviceId).write(appInfo.packageName, data);
    } catch (e, stack) {
      _logger.severe('保存应用信息失败: ${appInfo.packageName}', e, stack);
    }
  }

  Future<AppInfo?> loadAppInfo(String deviceId, String packageName) async {
    try {
      final data = await _appInfoDir.sub(deviceId).read(packageName);
      if (data == null) return null;

      // 读取图标
      final icon = await _iconDir.sub(deviceId).read<Uint8List>(packageName);

      return AppInfo(
        packageName: data['packageName'],
        appName: data['appName'],
        versionName: data['versionName'],
        versionCode: data['versionCode'],
        installTime: data['installTime'] != null
            ? DateTime.parse(data['installTime'])
            : null,
        updateTime: data['updateTime'] != null
            ? DateTime.parse(data['updateTime'])
            : null,
        enabled: data['enabled'],
        size: data['size'],
        isSystemApp: data['isSystemApp'],
        isRunning: data['isRunning'],
        isFullyLoaded: data['isFullyLoaded'],
        icon: icon,
      );
    } catch (e, stack) {
      _logger.severe('读取应用信息失败: $packageName', e, stack);
      return null;
    }
  }

  Future<void> deleteAppInfo(String deviceId, String packageName) async {
    try {
      await _appInfoDir.sub(deviceId).write(packageName, null);
      await _iconDir.sub(deviceId).write(packageName, null);
    } catch (e) {
      _logger.warning('删除应用信息失败: $packageName', e);
    }
  }

  Future<void> clearCache(String deviceId) async {
    try {
      _appInfoDir.sub(deviceId).drop();
      _iconDir.sub(deviceId).drop();
    } catch (e) {
      _logger.warning('清除缓存失败', e);
    }
  }
}
