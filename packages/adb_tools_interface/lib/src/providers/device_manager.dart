import 'package:flutter/foundation.dart';

import '../models/device.dart';
import '../services/adb_interface.dart';

abstract class DeviceManager extends ChangeNotifier {
  bool get isLoading;
  List<Device> get devices;
  AdbInterface get adb;

  Future<void> refreshDevices();
  Future<void> addDevice(String address);
  Future<void> removeDevice(String address);
  Future<void> disconnectDevice(String address);
}
