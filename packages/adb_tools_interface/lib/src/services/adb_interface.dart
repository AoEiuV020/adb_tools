import '../models/device.dart';
import '../models/device_status.dart';

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
}
