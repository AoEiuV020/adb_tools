import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/apps_provider.dart';

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppsProvider>(
      builder: (context, provider, child) {
        if (provider.multiSelect) {
          return _buildMultiSelectActions(context);
        }
        return _buildNormalActions(context);
      },
    );
  }

  Widget _buildNormalActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.refresh,
            label: '刷新',
            onPressed: () => context.read<AppsProvider>().refresh(),
          ),
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.cleaning_services,
            label: '清缓存',
            onPressed: () => context.read<AppsProvider>().forceRefresh(),
          ),
          _ActionButton(
            icon: Icons.sort,
            label: '排序',
            onPressed: () => _showSortOptions(context),
          ),
          _ActionButton(
            icon: Icons.visibility_off,
            label: '隐藏',
            onPressed: () => _showHideOptions(context),
          ),
          _ActionButton(
            icon: Icons.check_box_outlined,
            label: '多选',
            onPressed: () => context.read<AppsProvider>().toggleMultiSelect(),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectActions(BuildContext context) {
    final selectedCount = context.select<AppsProvider, int>(
      (provider) => provider.selectedPackages.length,
    );

    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '已选择 $selectedCount 个应用',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: '卸载选中',
            onPressed: selectedCount > 0
                ? () => _showUninstallConfirmation(context)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.block),
            tooltip: '停用选中',
            onPressed: selectedCount > 0
                ? () => _showDisableConfirmation(context)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.check_circle),
            tooltip: '启用选中',
            onPressed: selectedCount > 0
                ? () => context.read<AppsProvider>().enableSelected()
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: '取消多选',
            onPressed: () => context.read<AppsProvider>().toggleMultiSelect(),
          ),
        ],
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    final provider = context.read<AppsProvider>();

    showModalBottomSheet(
      context: context,
      builder: (context) => ChangeNotifierProvider<AppsProvider>.value(
        value: provider,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer<AppsProvider>(
              builder: (context, provider, child) => ListTile(
                title: const Text('排序方式'),
                trailing: IconButton(
                  icon: Icon(provider.sortDescending
                      ? Icons.arrow_downward
                      : Icons.arrow_upward),
                  onPressed: () => provider.toggleSortDirection(),
                  tooltip: provider.sortDescending ? '降序' : '升序',
                ),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('按名称'),
              onTap: () {
                provider.setSortBy('name');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('按安装时间'),
              onTap: () {
                provider.setSortBy('installTime');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('按大小'),
              onTap: () {
                provider.setSortBy('size');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHideOptions(BuildContext context) {
    final provider = context.read<AppsProvider>();

    showModalBottomSheet(
      context: context,
      builder: (context) => ChangeNotifierProvider<AppsProvider>.value(
        value: provider,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  SwitchListTile(
                    title: const Text('显示系统应用'),
                    value: provider.showSystemApps,
                    onChanged: (value) {
                      provider.toggleShowSystemApps();
                      setState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: const Text('显示已停用应用'),
                    value: provider.showDisabledApps,
                    onChanged: (value) {
                      provider.toggleShowDisabledApps();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUninstallConfirmation(BuildContext context) {
    final provider = context.read<AppsProvider>();

    showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider<AppsProvider>.value(
        value: provider,
        child: AlertDialog(
          title: const Text('确认卸载'),
          content: Text('确定要卸载选中的 ${provider.selectedPackages.length} 个应用吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
                provider.uninstallSelected();
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDisableConfirmation(BuildContext context) {
    final provider = context.read<AppsProvider>();
    final selectedCount = provider.selectedPackages.length;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认停用'),
        content: Text('确定要停用选中的 $selectedCount 个应用吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
              provider.disableSelected();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
