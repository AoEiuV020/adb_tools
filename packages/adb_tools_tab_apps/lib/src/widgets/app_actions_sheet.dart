import 'package:flutter/material.dart';

import 'package:adb_tools_interface/adb_tools_interface.dart';
import 'package:provider/provider.dart';

import '../providers/apps_provider.dart';

class AppActionsSheet extends StatelessWidget {
  final AppInfo app;

  const AppActionsSheet({
    super.key,
    required this.app,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppsProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.refresh),
          title: const Text('刷新'),
          onTap: () async {
            Navigator.pop(context);
            await provider.refreshApp(app.packageName);
          },
        ),
        ListTile(
          leading: const Icon(Icons.play_arrow),
          title: const Text('启动'),
          onTap: () async {
            Navigator.pop(context);
            await provider.launchApp(app.packageName);
          },
        ),
        ListTile(
          leading: const Icon(Icons.stop),
          title: const Text('停止'),
          onTap: () async {
            Navigator.pop(context);
            await provider.stopApp(app.packageName);
          },
        ),
        if (app.enabled)
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('停用'),
            onTap: () async {
              Navigator.pop(context);
              await provider.disableApp(app.packageName);
            },
          )
        else
          ListTile(
            leading: const Icon(Icons.check_circle),
            title: const Text('启用'),
            onTap: () async {
              Navigator.pop(context);
              await provider.enableApp(app.packageName);
            },
          ),
        if (!app.isSystemApp)
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('卸载'),
            onTap: () async {
              Navigator.pop(context);
              if (!context.mounted) return;

              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) =>
                    ChangeNotifierProvider<AppsProvider>.value(
                  value: provider,
                  child: AlertDialog(
                    title: const Text('确认卸载'),
                    content: Text('确定要卸载 ${app.appName ?? app.packageName} 吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                ),
              );

              if (confirmed == true && context.mounted) {
                await provider.uninstallApp(app.packageName);
              }
            },
          ),
      ],
    );
  }
}
