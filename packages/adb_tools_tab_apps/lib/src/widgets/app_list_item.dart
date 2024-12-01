import 'package:flutter/material.dart';

import 'package:adb_tools_interface/adb_tools_interface.dart';
import 'package:provider/provider.dart';

import '../providers/apps_provider.dart';

class AppListItem extends StatelessWidget {
  final AppInfo app;
  final bool multiSelect;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const AppListItem({
    super.key,
    required this.app,
    required this.multiSelect,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildLeading(),
      title: Text(app.appName ?? app.packageName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (app.appName != null) Text(app.packageName),
          if (app.versionName != null)
            Text('版本: ${app.versionName} (${app.versionCode})'),
          if (app.installTime != null)
            Text('安装时间: ${app.installTime!.toLocal()}'),
          if (app.size != null) Text('大小: ${_formatSize(app.size!)}'),
        ],
      ),
      trailing: multiSelect
          ? Checkbox(
              value: isSelected,
              onChanged: (_) => onTap(),
            )
          : _buildStatusIcon(context),
      onTap: onTap,
      onLongPress: onLongPress,
      tileColor: !app.enabled ? Colors.grey.withOpacity(0.2) : null,
    );
  }

  Widget _buildLeading() {
    if (app.icon != null) {
      return Image.memory(app.icon!, width: 48, height: 48);
    }
    return const Icon(Icons.android, size: 48);
  }

  Widget _buildStatusIcon(BuildContext context) {
    final isLoading = context.select<AppsProvider, bool>(
      (provider) => provider.isAppLoading(app.packageName),
    );

    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      );
    }
    if (!app.enabled) {
      return const Icon(Icons.block, color: Colors.red);
    }
    if (app.isRunning) {
      return const Icon(Icons.play_arrow, color: Colors.green);
    }
    return const SizedBox.shrink();
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
