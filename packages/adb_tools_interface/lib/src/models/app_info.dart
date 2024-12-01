import 'package:flutter/foundation.dart';

@immutable
class AppInfo {
  final String packageName;
  final String? appName;
  final String? versionName;
  final String? versionCode;
  final DateTime? installTime;
  final DateTime? updateTime;
  final bool enabled;
  final int? size;
  final bool isSystemApp;
  final bool isRunning;
  final Uint8List? icon;
  final bool isFullyLoaded;

  const AppInfo({
    required this.packageName,
    this.appName,
    this.versionName,
    this.versionCode,
    this.installTime,
    this.updateTime,
    this.enabled = true,
    this.size,
    this.isSystemApp = false,
    this.isRunning = false,
    this.icon,
    this.isFullyLoaded = true,
  });

  factory AppInfo.basic(String packageName) {
    return AppInfo(
      packageName: packageName,
      isFullyLoaded: false,
    );
  }

  AppInfo copyWith({
    String? packageName,
    String? appName,
    String? versionName,
    String? versionCode,
    DateTime? installTime,
    DateTime? updateTime,
    bool? enabled,
    int? size,
    bool? isSystemApp,
    bool? isRunning,
    Uint8List? icon,
    bool? isFullyLoaded,
  }) {
    return AppInfo(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      versionName: versionName ?? this.versionName,
      versionCode: versionCode ?? this.versionCode,
      installTime: installTime ?? this.installTime,
      updateTime: updateTime ?? this.updateTime,
      enabled: enabled ?? this.enabled,
      size: size ?? this.size,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      isRunning: isRunning ?? this.isRunning,
      icon: icon ?? this.icon,
      isFullyLoaded: isFullyLoaded ?? this.isFullyLoaded,
    );
  }
}
