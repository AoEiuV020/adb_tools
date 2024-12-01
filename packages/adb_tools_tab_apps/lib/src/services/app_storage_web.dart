import 'package:adb_tools_interface/adb_tools_interface.dart';

import 'app_storage.dart';

class AppStorageImpl implements AppStorage {
  @override
  Future<void> init() async {
    // Web平台暂不实现
  }

  @override
  Future<void> saveAppInfo(String deviceId, AppInfo appInfo) async {
    // Web平台暂不实现
  }

  @override
  Future<Map<String, AppInfo>> loadAppInfos(String deviceId) async {
    // Web平台暂不实现
    return {};
  }

  @override
  Future<void> deleteAppInfo(String deviceId, String packageName) async {
    // Web平台暂不实现
  }

  @override
  Future<void> clearCache(String deviceId) async {
    // Web平台暂不实现
  }
} 