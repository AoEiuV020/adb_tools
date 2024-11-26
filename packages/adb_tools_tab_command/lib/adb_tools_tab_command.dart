library;

import 'package:flutter/material.dart';

import 'package:adb_tools_interface/adb_tools_interface.dart';
import 'package:xterm/xterm.dart';

class CommandTab extends DeviceTab {
  const CommandTab()
      : super(
          label: '命令行',
          icon: Icons.terminal,
        );

  @override
  Widget buildTabContent(
      BuildContext context, Device device, DeviceManager deviceManager) {
    return CommandTerminal(
      device: device,
      deviceManager: deviceManager,
    );
  }
}

class CommandTerminal extends StatefulWidget {
  final Device device;
  final DeviceManager deviceManager;

  const CommandTerminal({
    super.key,
    required this.device,
    required this.deviceManager,
  });

  @override
  State<CommandTerminal> createState() => _CommandTerminalState();
}

class _CommandTerminalState extends State<CommandTerminal>
    with AutomaticKeepAliveClientMixin {
  late final terminal = Terminal();
  Shell? _shell;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _startShell();
  }

  Future<void> _startShell() async {
    try {
      _shell = await widget.deviceManager.adb.startShell(widget.device.address);

      _shell!.stdout.listen((data) {
        terminal.write(String.fromCharCodes(data));
      });

      _shell!.stderr.listen((data) {
        terminal.write(String.fromCharCodes(data));
      });

      terminal.onOutput = (data) {
        _shell?.stdin.add(data);
      };
    } catch (e) {
      terminal.write('错误: 无法启动ADB Shell\n$e\n');
    }
  }

  @override
  void dispose() {
    _shell?.terminate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return TerminalView(
      terminal,
      keyboardType: TextInputType.multiline,
      textStyle: const TerminalStyle(
        fontSize: 14,
        fontFamily: 'monospace',
      ),
      padding: const EdgeInsets.all(8),
    );
  }
}
