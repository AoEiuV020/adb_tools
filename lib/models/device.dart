import 'device_status.dart';

class Device {
  final String name;
  final String address;
  final DeviceStatus status;

  const Device({
    required this.name,
    required this.address,
    required this.status,
  });

  Device copyWith({
    String? name,
    String? address,
    DeviceStatus? status,
  }) {
    return Device(
      name: name ?? this.name,
      address: address ?? this.address,
      status: status ?? this.status,
    );
  }
}
