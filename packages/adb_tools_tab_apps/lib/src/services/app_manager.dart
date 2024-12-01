import 'package:adb_tools_interface/adb_tools_interface.dart';

class AppManager {
  final AdbInterface _adb;
  final String _deviceAddress;

  AppManager(this._adb, this._deviceAddress);

  Future<String?> getAppName(String packageName) async {
    return _adb.getAppName(_deviceAddress, packageName);
  }

  Future<(String?, String?)> getAppVersion(String packageName) async {
    return _adb.getAppVersion(_deviceAddress, packageName);
  }

  Future<(DateTime?, DateTime?)> getAppInstallTime(String packageName) async {
    return _adb.getAppInstallTime(_deviceAddress, packageName);
  }

  Future<bool> isSystemApp(String packageName) async {
    return _adb.isSystemApp(_deviceAddress, packageName);
  }

  Future<bool> isAppDisabled(String packageName) async {
    return _adb.isAppDisabled(_deviceAddress, packageName);
  }

  Future<bool> isAppRunning(String packageName) async {
    return _adb.isAppRunning(_deviceAddress, packageName);
  }

  Future<int?> getAppSize(String packageName) async {
    return _adb.getAppSize(_deviceAddress, packageName);
  }

  Future<List<String>> getPackageList({
    bool showSystemApps = true,
    bool showDisabledApps = true,
  }) async {
    return _adb.getPackageList(
      _deviceAddress,
      showSystemApps: showSystemApps,
      showDisabledApps: showDisabledApps,
    );
  }

  Future<bool> launchApp(String packageName) async {
    return _adb.launchApp(_deviceAddress, packageName);
  }

  Future<bool> stopApp(String packageName) async {
    return _adb.stopApp(_deviceAddress, packageName);
  }

  Future<bool> uninstallApp(String packageName) async {
    return _adb.uninstallApp(_deviceAddress, packageName);
  }

  Future<bool> enableApp(String packageName) async {
    return _adb.enableApp(_deviceAddress, packageName);
  }

  Future<bool> disableApp(String packageName) async {
    return _adb.disableApp(_deviceAddress, packageName);
  }

  Future<AppInfo> getAppInfo(String packageName) async {
    return _adb.getAppInfo(_deviceAddress, packageName);
  }
}
