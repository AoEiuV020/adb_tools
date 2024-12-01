import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:adb_tools_interface/adb_tools_interface.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AppStorage {
  static final _logger = Logger('AppStorage');

  late final Directory _baseDir;
  late final Directory _appInfoDir;
  late final Directory _iconDir;

  Future<void> init() async {
    final docDir = await getApplicationDocumentsDirectory();
    _baseDir = Directory(path.join(docDir.path, 'apps'));
    _appInfoDir = Directory(path.join(_baseDir.path, 'appInfo'));
    _iconDir = Directory(path.join(_baseDir.path, 'icon'));

    await _baseDir.create(recursive: true);
    await _appInfoDir.create(recursive: true);
    await _iconDir.create(recursive: true);
  }

  Future<void> saveAppInfo(String deviceId, AppInfo appInfo) async {
    try {
      final file = File(path.join(
        _appInfoDir.path,
        '${deviceId}_${appInfo.packageName}.json',
      ));

      // 保存图标
      String? iconPath;
      if (appInfo.icon != null) {
        iconPath = path.join(
          _iconDir.path,
          '${deviceId}_${appInfo.packageName}.png',
        );
        await File(iconPath).writeAsBytes(appInfo.icon!);
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
        'iconPath': iconPath,
      };

      await file.writeAsString(jsonEncode(data));
    } catch (e, stack) {
      _logger.severe('保存应用信息失败: ${appInfo.packageName}', e, stack);
    }
  }

  Future<Map<String, AppInfo>> loadAppInfos(String deviceId) async {
    final Map<String, AppInfo> result = {};
    try {
      final dir = Directory(_appInfoDir.path);
      final List<FileSystemEntity> files = await dir
          .list()
          .where((f) => f.path.startsWith('${deviceId}_'))
          .toList();

      for (var file in files) {
        if (file is File) {
          try {
            final data = jsonDecode(await file.readAsString());

            // 读取图标
            Uint8List? icon;
            if (data['iconPath'] != null) {
              final iconFile = File(data['iconPath']);
              if (await iconFile.exists()) {
                icon = await iconFile.readAsBytes();
              }
            }

            final appInfo = AppInfo(
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
              enabled: data['enabled'] ?? true,
              size: data['size'],
              isSystemApp: data['isSystemApp'] ?? false,
              isRunning: data['isRunning'] ?? false,
              icon: icon,
            );

            result[appInfo.packageName] = appInfo;
          } catch (e) {
            _logger.warning('读取应用信息失败: ${file.path}', e);
            continue;
          }
        }
      }
    } catch (e, stack) {
      _logger.severe('加载应用信息失败', e, stack);
    }
    return result;
  }

  Future<void> deleteAppInfo(String deviceId, String packageName) async {
    try {
      // 删除应用信息文件
      final infoFile = File(path.join(
        _appInfoDir.path,
        '${deviceId}_$packageName.json',
      ));
      if (await infoFile.exists()) {
        await infoFile.delete();
      }

      // 删除图标文件
      final iconFile = File(path.join(
        _iconDir.path,
        '${deviceId}_$packageName.png',
      ));
      if (await iconFile.exists()) {
        await iconFile.delete();
      }
    } catch (e) {
      _logger.warning('删除应用信息失败: $packageName', e);
    }
  }

  Future<void> clearCache(String deviceId) async {
    try {
      final dir = Directory(_appInfoDir.path);
      final files = await dir
          .list()
          .where((f) => f.path.startsWith('${deviceId}_'))
          .toList();

      for (var file in files) {
        await file.delete();
      }

      final iconDir = Directory(_iconDir.path);
      final icons = await iconDir
          .list()
          .where((f) => f.path.startsWith('${deviceId}_'))
          .toList();

      for (var icon in icons) {
        await icon.delete();
      }
    } catch (e) {
      _logger.warning('清除缓存失败', e);
    }
  }
}
