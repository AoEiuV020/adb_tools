import 'package:flutter_test/flutter_test.dart';

import 'package:adb_tools/services/adb_command.dart';

void main() {
  // 抽出设备ID和包名作为常量
  const testDeviceId = '192.168.2.35:5555';
  const testDisabledPackageName = 'com.android.email';
  const testRunningPackageName = 'com.android.chrome';
  const testPackageNameCalendar = 'com.android.calendar';

  // 创建一个AdbCommand实例供所有测试使用
  final adb = AdbCommand();

  group('AdbCommand Parse Methods', () {
    test('parseVersionInfo should correctly parse version information', () {
      const dumpsysOutput = '''
        Package [com.example.app] (12345678):
          versionCode=123 minSdk=24 targetSdk=33
          ...
          versionName=1.2.3
          ...
      ''';

      final (versionName, versionCode) =
          AdbCommand.parseVersionInfo(dumpsysOutput);
      expect(versionName, equals('1.2.3'));
      expect(versionCode, equals('123'));
    });

    test('parseInstallTime should correctly parse install times', () {
      const dumpsysOutput = '''
        Package [com.example.app] (12345678):
          lastUpdateTime=2024-11-26 17:47:28
          ...
          firstInstallTime=2024-10-10 09:50:05
          ...
          firstInstallTime=1970-01-01 08:00:00
          ...
      ''';

      final (installTime, updateTime) =
          AdbCommand.parseInstallTime(dumpsysOutput);
      expect(
        installTime,
        equals(DateTime.parse('2024-10-10T09:50:05')),
      );
      expect(
        updateTime,
        equals(DateTime.parse('2024-11-26T17:47:28')),
      );
    });

    group('parseSystemApp', () {
      test('should correctly identify system app from flags', () {
        const dumpsysOutput = '''
          Package [com.example.app] (12345678):
          flags=[ SYSTEM HAS_CODE ALLOW_CLEAR_USER_DATA UPDATED_SYSTEM_APP ]
          ...
        ''';
        expect(AdbCommand.parseSystemApp(dumpsysOutput), isTrue);
      });

      test('should correctly identify system app from pkgFlags', () {
        const dumpsysOutput = '''
          Package [com.example.app] (12345678):
          pkgFlags=[ SYSTEM HAS_CODE ALLOW_CLEAR_USER_DATA ]
          ...
        ''';
        expect(AdbCommand.parseSystemApp(dumpsysOutput), isTrue);
      });

      test('should correctly identify non-system app', () {
        const dumpsysOutput = '''
          Package [com.example.app] (12345678):
          flags=[ HAS_CODE ALLOW_CLEAR_USER_DATA ]
          ...
        ''';
        expect(AdbCommand.parseSystemApp(dumpsysOutput), isFalse);
      });

      test('should default to non-system app when no flags found', () {
        const dumpsysOutput = '''
          Package [com.example.app] (12345678):
          someOtherInfo=value
          ...
        ''';
        expect(AdbCommand.parseSystemApp(dumpsysOutput), isFalse);
      });
    });

    group('isAppDisabled', () {
      test('should correctly identify disabled app', () async {
        // 测试一个已知被停用的应用
        final result =
            await adb.isAppDisabled(testDeviceId, testDisabledPackageName);
        expect(result, isTrue);

        // 测试一个正常启用的应用
        final result2 =
            await adb.isAppDisabled(testDeviceId, testPackageNameCalendar);
        expect(result2, isFalse);
      });

      test('should not match package name substring', () async {
        // 测试包名子串
        final result = await adb.isAppDisabled(testDeviceId, 'android');
        expect(result, isFalse);
      });
    });

    group('getAppSize', () {
      test('should correctly parse apk path and get size', () async {
        // 使用已知存在的应用测试
        final size =
            await adb.getAppSize(testDeviceId, testDisabledPackageName);
        expect(size, isNotNull);
        expect(size, greaterThan(0));
      });

      test('should handle package name substring', () async {
        // 测试包名子串
        final size = await adb.getAppSize(testDeviceId, 'com.android');
        expect(size, isNull);
      });

      test('should handle equals sign in path', () async {
        // 使用已知存在的应用测试
        final size =
            await adb.getAppSize(testDeviceId, testDisabledPackageName);
        expect(size, isNotNull);
        expect(size, greaterThan(0));
      });
    });

    group('isAppRunning', () {
      test('should correctly identify running app', () async {
        // 测试一个已知正在运行的应用
        final result =
            await adb.isAppRunning(testDeviceId, testRunningPackageName);
        expect(result, isTrue);
      });

      test('should not match package name substring', () async {
        // 测试包名子串
        final result = await adb.isAppRunning(testDeviceId, 'android');
        expect(result, isFalse);
      });

      test('should handle non-existent package', () async {
        // 测试不存在的包名
        final result = await adb.isAppRunning(
          testDeviceId,
          'com.nonexistent.package',
        );
        expect(result, isFalse);
      });
    });
  });
}
