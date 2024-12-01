import 'package:flutter/material.dart';

import 'package:adb_tools_interface/adb_tools_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/apps_provider.dart';
import 'services/app_manager.dart';
import 'widgets/app_actions_sheet.dart';
import 'widgets/app_list_item.dart';
import 'widgets/bottom_action_bar.dart';

class AppsTab extends DeviceTab {
  const AppsTab()
      : super(
          label: '应用',
          icon: Icons.apps,
        );

  @override
  Widget buildTabContent(
      BuildContext context, Device device, DeviceManager deviceManager) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ChangeNotifierProvider<AppsProvider>(
          create: (context) => AppsProvider(
            AppManager(deviceManager.adb, device.address),
            snapshot.data!,
            device.address,
          ),
          child: const _AppsTabContent(),
        );
      },
    );
  }
}

class _AppsTabContent extends StatelessWidget {
  const _AppsTabContent();

  void _scheduleLoadAppDetails(BuildContext context, AppInfo app) {
    if (!app.isFullyLoaded) {
      Future.microtask(() {
        if (context.mounted) {
          context.read<AppsProvider>().loadAppDetails(app.packageName);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Consumer<AppsProvider>(
                builder: (context, provider, child) {
                  if (provider.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final apps = provider.apps;

                  return Stack(
                    children: [
                      ListView.builder(
                        itemCount: apps.length,
                        itemBuilder: (context, index) {
                          final app = apps[index];
                          _scheduleLoadAppDetails(context, app);

                          return AppListItem(
                            app: app,
                            multiSelect: provider.multiSelect,
                            isSelected: provider.selectedPackages.contains(
                              app.packageName,
                            ),
                            onTap: () {
                              if (provider.multiSelect) {
                                provider
                                    .togglePackageSelection(app.packageName);
                              } else {
                                final provider = context.read<AppsProvider>();
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) => ChangeNotifierProvider<
                                      AppsProvider>.value(
                                    value: provider,
                                    child: AppActionsSheet(app: app),
                                  ),
                                );
                              }
                            },
                            onLongPress: () {
                              if (provider.multiSelect) {
                                final provider = context.read<AppsProvider>();
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) => ChangeNotifierProvider<
                                      AppsProvider>.value(
                                    value: provider,
                                    child: AppActionsSheet(app: app),
                                  ),
                                );
                              } else {
                                provider.toggleMultiSelect();
                                provider
                                    .togglePackageSelection(app.packageName);
                              }
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            const BottomActionBar(),
          ],
        ),
        Consumer<AppsProvider>(
          builder: (context, provider, child) {
            if (!provider.operating) return const SizedBox.shrink();
            return Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          provider.operationMessage ?? '正在操作...',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
