import 'package:flutter/material.dart';

import 'package:adb_tools_interface/adb_tools_interface.dart';
import 'package:provider/provider.dart';

import 'device_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADB工具'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 连接新设备部分
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('连接新设备',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'IP地址:端口',
                              hintText: '例如: 192.168.1.100:5555',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (value) {
                              _connectDevice(value.trim());
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            _connectDevice(_addressController.text.trim());
                          },
                          child: const Text('连接'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 已连接设备列表标题栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '已连接设备',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Consumer<DeviceManager>(
                  builder: (context, deviceManager, child) {
                    return IconButton(
                      icon: deviceManager.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      onPressed: deviceManager.isLoading
                          ? null
                          : () => deviceManager.refreshDevices(),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 设备列表
            Expanded(
              child: Consumer<DeviceManager>(
                builder: (context, deviceManager, child) {
                  if (deviceManager.devices.isEmpty) {
                    return const Center(
                      child: Text('暂无已连接设备'),
                    );
                  }

                  return ListView.builder(
                    itemCount: deviceManager.devices.length,
                    itemBuilder: (context, index) {
                      final device = deviceManager.devices[index];
                      return Card(
                        child: InkWell(
                          onTap: () {
                            if (device.status == DeviceStatus.disconnected) {
                              deviceManager.addDevice(device.address);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DevicePage(device: device),
                                ),
                              );
                            }
                          },
                          child: ListTile(
                            title: Text(device.name),
                            subtitle: Text(device.address),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () {
                                    if (device.status ==
                                        DeviceStatus.disconnected) {
                                      deviceManager.addDevice(device.address);
                                    } else {
                                      deviceManager
                                          .disconnectDevice(device.address);
                                    }
                                  },
                                  child: Chip(
                                    label: Text(device.status.label),
                                    backgroundColor:
                                        _getStatusColor(device.status),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () {
                                    deviceManager.removeDevice(device.address);
                                  },
                                ),
                                const Icon(Icons.arrow_forward),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.connected:
        return Colors.green.shade100;
      case DeviceStatus.connecting:
        return Colors.blue.shade100;
      case DeviceStatus.unauthorized:
        return Colors.orange.shade100;
      case DeviceStatus.offline:
      case DeviceStatus.disconnected:
        return Colors.grey.shade300;
    }
  }

  void _connectDevice(String address) {
    if (address.isNotEmpty) {
      if (!address.contains(':')) {
        address = '$address:5555';
      }
      context.read<DeviceManager>().addDevice(address);
      _addressController.clear();
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}
