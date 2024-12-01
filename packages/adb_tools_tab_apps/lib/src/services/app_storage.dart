import 'package:adb_tools_interface/adb_tools_interface.dart';

import 'app_storage_io.dart' if (dart.library.html) 'app_storage_web.dart';

/// 应用信息存储基类
abstract class AppStorage {
  /// 初始化存储
  Future<void> init();

  /// 保存应用信息
  Future<void> saveAppInfo(String deviceId, AppInfo appInfo);

  /// 加载设备的所有应用信息
  Future<Map<String, AppInfo>> loadAppInfos(String deviceId);

  /// 删除应用信息
  Future<void> deleteAppInfo(String deviceId, String packageName);

  /// 清除设备缓存
  Future<void> clearCache(String deviceId);

  /// 根据平台返回具体实现
  factory AppStorage() => AppStorageImpl();
}
