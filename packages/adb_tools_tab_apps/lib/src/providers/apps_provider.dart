import 'package:flutter/foundation.dart';

import 'package:adb_tools_interface/adb_tools_interface.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_manager.dart';
import '../services/app_storage.dart';
import '../utils/comparator_chain.dart';

class AppsProvider extends ChangeNotifier {
  static final _logger = Logger('AppsProvider');

  final AppManager appManager;
  final SharedPreferences _prefs;
  final AppStorage _storage = AppStorage();
  final String _deviceId;

  Map<String, AppInfo> _appInfoCache = {};
  List<AppInfo> _apps = [];
  bool _loading = false;
  bool _showSystemApps = true;
  bool _showDisabledApps = true;
  String _sortBy = 'name';
  bool _multiSelect = false;
  final Set<String> _selectedPackages = {};
  final Set<String> _loadingApps = {};

  // 添加操作状态
  bool _operating = false;
  String? _operationMessage;

  bool get operating => _operating;
  String? get operationMessage => _operationMessage;

  bool _sortDescending = false; // 添加排序方向

  bool get sortDescending => _sortDescending;

  AppsProvider(this.appManager, this._prefs, this._deviceId) {
    _init();
  }

  Future<void> _init() async {
    await _storage.init();
    _loadPreferences();
    _appInfoCache = await _storage.loadAppInfos(_deviceId);
    if (_appInfoCache.isNotEmpty) {
      _apps = _appInfoCache.values.toList();
      _sortApps();
      notifyListeners();
    }
    loadApps();
  }

  List<AppInfo> get apps => _apps;
  bool get loading => _loading;
  bool get showSystemApps => _showSystemApps;
  bool get showDisabledApps => _showDisabledApps;
  String get sortBy => _sortBy;
  bool get multiSelect => _multiSelect;
  Set<String> get selectedPackages => _selectedPackages;

  void _loadPreferences() {
    _showSystemApps = _prefs.getBool('showSystemApps') ?? true;
    _showDisabledApps = _prefs.getBool('showDisabledApps') ?? true;
    _sortBy = _prefs.getString('sortBy') ?? 'name';
    _sortDescending = _prefs.getBool('sortDescending') ?? false; // 加载排序方向
  }

  Future<void> loadApps({bool forceRefresh = false}) async {
    if (_loading) return;

    _loading = true;
    notifyListeners();

    try {
      final packages = await appManager.getPackageList(
        showSystemApps: _showSystemApps,
        showDisabledApps: _showDisabledApps,
      );

      final apps = <AppInfo>[];

      for (final package in packages) {
        if (!forceRefresh && _appInfoCache.containsKey(package)) {
          apps.add(_appInfoCache[package]!);
        } else {
          apps.add(AppInfo.basic(package));
        }
      }

      _apps = apps;
      _sortApps();

      // 不再自动加载详细信息
      _loading = false;
      notifyListeners();
    } catch (e, stack) {
      _logger.severe('加载应用列表失败', e, stack);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _sortApps() {
    final comparator = ComparatorChain<AppInfo>().thenCompare((a, b) {
      if (a.isFullyLoaded == b.isFullyLoaded) return 0;
      return b.isFullyLoaded ? 1 : -1;
    }).thenCompare((a, b) {
      int result;
      switch (_sortBy) {
        case 'name':
          result = (a.appName ?? a.packageName)
              .compareTo(b.appName ?? b.packageName);
          break;
        case 'installTime':
          final timeA = a.installTime ?? DateTime.fromMillisecondsSinceEpoch(0);
          final timeB = b.installTime ?? DateTime.fromMillisecondsSinceEpoch(0);
          result = timeA.compareTo(timeB);
          break;
        case 'size':
          final sizeA = a.size ?? 0;
          final sizeB = b.size ?? 0;
          result = sizeA.compareTo(sizeB);
          break;
        default:
          return 0;
      }
      // 统一处理升降序
      return _sortDescending ? -result : result;
    }).thenCompare((a, b) => a.packageName.compareTo(b.packageName));

    _apps.sort(comparator.compare);
  }

  // 普通刷新：保留缓存，重新加载列表
  Future<void> refresh() async {
    await loadApps();
  }

  // 长按刷新：清除缓存，完全重新加载
  Future<void> forceRefresh() async {
    await _storage.clearCache(_deviceId);
    _appInfoCache.clear();
    await loadApps(forceRefresh: true);
  }

  void toggleShowSystemApps() {
    _showSystemApps = !_showSystemApps;
    _prefs.setBool('showSystemApps', _showSystemApps);
    // 切换显示设置后重新加载列表
    loadApps();
  }

  void toggleShowDisabledApps() {
    _showDisabledApps = !_showDisabledApps;
    _prefs.setBool('showDisabledApps', _showDisabledApps);
    // 切换显示设置后重新加载列表
    loadApps();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    _prefs.setString('sortBy', sortBy);
    _sortApps();
    notifyListeners();
  }

  void toggleMultiSelect() {
    _multiSelect = !_multiSelect;
    if (!_multiSelect) {
      _selectedPackages.clear();
    }
    notifyListeners();
  }

  void togglePackageSelection(String packageName) {
    if (_selectedPackages.contains(packageName)) {
      _selectedPackages.remove(packageName);
    } else {
      _selectedPackages.add(packageName);
    }
    notifyListeners();
  }

  Future<void> uninstallSelected() async {
    try {
      _setOperating(true, '正在卸载选中的应用...');
      for (final package in _selectedPackages) {
        if (await appManager.uninstallApp(package)) {
          _appInfoCache.remove(package);
        }
      }
      _selectedPackages.clear();
      await loadApps();
    } catch (e, stack) {
      _logger.severe('批量卸载应用失败', e, stack);
    } finally {
      _setOperating(false);
    }
  }

  Future<void> disableSelected() async {
    try {
      _setOperating(true, '正在停用选中的应用...');
      for (final package in _selectedPackages) {
        if (await appManager.disableApp(package)) {
          final app = _appInfoCache[package];
          if (app != null) {
            _appInfoCache[package] = app.copyWith(enabled: false);
          }
        }
      }
      _selectedPackages.clear();
      await loadApps();
    } catch (e, stack) {
      _logger.severe('批量停用应用失败', e, stack);
    } finally {
      _setOperating(false);
    }
  }

  Future<void> enableSelected() async {
    try {
      _setOperating(true, '正在启用选中的应用...');
      for (final package in _selectedPackages) {
        if (await appManager.enableApp(package)) {
          final app = _appInfoCache[package];
          if (app != null) {
            _appInfoCache[package] = app.copyWith(enabled: true);
          }
        }
      }
      _selectedPackages.clear();
      await loadApps();
    } catch (e, stack) {
      _logger.severe('批量启用应用失败', e, stack);
    } finally {
      _setOperating(false);
    }
  }

  // 刷新单应用的所有信息
  Future<void> refreshApp(String packageName) async {
    try {
      // 通过getAppInfo一次性获取所有信息
      final newApp = await appManager.getAppInfo(packageName);

      // 更新应用信息
      final index = _apps.indexWhere((app) => app.packageName == packageName);
      if (index != -1) {
        _appInfoCache[packageName] = newApp;
        await _storage.saveAppInfo(_deviceId, newApp);
        _apps[index] = newApp;
        notifyListeners();
      }
    } catch (e, stack) {
      _logger.severe('刷新应用信息失败: $packageName', e, stack);
    }
  }

  Future<void> launchApp(String packageName) async {
    try {
      _setOperating(true, '正在启动应用...');
      if (await appManager.launchApp(packageName)) {
        final isRunning = await appManager.isAppRunning(packageName);
        await _updateAppStatus(packageName, isRunning: isRunning);
      }
    } catch (e, stack) {
      _logger.severe('启动应用失败: $packageName', e, stack);
    } finally {
      _setOperating(false);
    }
  }

  Future<void> stopApp(String packageName) async {
    try {
      _setOperating(true, '正在停止应用...');
      if (await appManager.stopApp(packageName)) {
        final isRunning = await appManager.isAppRunning(packageName);
        await _updateAppStatus(packageName, isRunning: isRunning);
      }
    } catch (e, stack) {
      _logger.severe('停止应用失败: $packageName', e, stack);
    } finally {
      _setOperating(false);
    }
  }

  Future<void> enableApp(String packageName) async {
    try {
      _setOperating(true, '正在启用应用...');
      if (await appManager.enableApp(packageName)) {
        final isDisabled = await appManager.isAppDisabled(packageName);
        await _updateAppStatus(packageName, enabled: !isDisabled);
      }
    } catch (e, stack) {
      _logger.severe('启用应用失败: $packageName', e, stack);
    } finally {
      _setOperating(false);
    }
  }

  Future<void> disableApp(String packageName) async {
    try {
      _setOperating(true, '正在停用应用...');
      if (await appManager.disableApp(packageName)) {
        final isDisabled = await appManager.isAppDisabled(packageName);
        await _updateAppStatus(packageName, enabled: !isDisabled);
      }
    } catch (e, stack) {
      _logger.severe('禁用应用失败: $packageName', e, stack);
    } finally {
      _setOperating(false);
    }
  }

  Future<void> uninstallApp(String packageName) async {
    try {
      _setOperating(true, '正在卸载应用...');
      if (await appManager.uninstallApp(packageName)) {
        _appInfoCache.remove(packageName);
        await _storage.deleteAppInfo(_deviceId, packageName);
        _apps.removeWhere((app) => app.packageName == packageName);
        notifyListeners();
      }
    } catch (e, stack) {
      _logger.severe('卸载应用失败: $packageName', e, stack);
    } finally {
      _setOperating(false);
    }
  }

  // 更新应用状态的辅助方法
  Future<void> _updateAppStatus(
    String packageName, {
    bool? isRunning,
    bool? enabled,
  }) async {
    final index = _apps.indexWhere((app) => app.packageName == packageName);
    if (index == -1) return;

    final oldApp = _apps[index];
    final newApp = oldApp.copyWith(
      isRunning: isRunning ?? oldApp.isRunning,
      enabled: enabled ?? oldApp.enabled,
    );

    _appInfoCache[packageName] = newApp;
    await _storage.saveAppInfo(_deviceId, newApp);
    _apps[index] = newApp;
    notifyListeners();
  }

  // 设置操作状态的辅助方法
  void _setOperating(bool value, [String? message]) {
    _operating = value;
    _operationMessage = message;
    notifyListeners();
  }

  // 添加判断方法
  bool isAppLoading(String packageName) => _loadingApps.contains(packageName);

  Future<void> loadAppDetails(String packageName) async {
    // 避免重复加载
    if (_loadingApps.contains(packageName)) return;
    if (_appInfoCache[packageName]?.isFullyLoaded ?? false) return;

    try {
      _loadingApps.add(packageName);
      notifyListeners();

      // 加载详细信息
      final fullInfo = await appManager.getAppInfo(packageName);

      // 更新缓存和列表
      _appInfoCache[packageName] = fullInfo;
      await _storage.saveAppInfo(_deviceId, fullInfo);

      final index = _apps.indexWhere((app) => app.packageName == packageName);
      if (index != -1) {
        _apps[index] = fullInfo;
      }
    } catch (e, stack) {
      _logger.severe('加载应用详细信息失败: $packageName', e, stack);
      // 加载失败时也标记为已加载,避免反复重试
      final failedApp = AppInfo(
        packageName: packageName,
        isFullyLoaded: true, // 标记为已加载
      );
      _appInfoCache[packageName] = failedApp;
      await _storage.saveAppInfo(_deviceId, failedApp);

      final index = _apps.indexWhere((app) => app.packageName == packageName);
      if (index != -1) {
        _apps[index] = failedApp;
      }
    } finally {
      _loadingApps.remove(packageName);
      notifyListeners();
    }
  }

  void toggleSortDirection() {
    _sortDescending = !_sortDescending;
    _prefs.setBool('sortDescending', _sortDescending);
    _sortApps();
    notifyListeners();
  }
}
