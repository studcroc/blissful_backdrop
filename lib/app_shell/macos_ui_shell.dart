// create a macOS-style app shell with a sidebar and a content area

import 'package:blissful_backdrop/about.dart';
import 'package:blissful_backdrop/active_wallpaper.dart';
import 'package:blissful_backdrop/check_update.dart';
import 'package:blissful_backdrop/home.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent_ui;
import 'package:bitsdojo_window/bitsdojo_window.dart' as window_manager;

class MacOSUIShell extends StatefulWidget {
  const MacOSUIShell({super.key});

  @override
  State<MacOSUIShell> createState() => _MacOSUIShellState();
}

class _MacOSUIShellState extends State<MacOSUIShell> {
  int selectedPanelIndex = 0;
  PackageInfo? packageInfo;

  List<fluent_ui.NavigationPaneItem> items = [
    fluent_ui.PaneItem(
      icon: const Icon(fluent_ui.FluentIcons.home),
      title: const Text('Home'),
      body: const Home(),
    ),
    fluent_ui.PaneItem(
      icon: const Icon(fluent_ui.FluentIcons.photo),
      title: const Text('Active Wallpaper'),
      body: const ActiveWallpaper(),
    )
  ];

  @override
  void initState() {
    super.initState();

    checkForAppUpdate(context);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: fluent_ui.NavigationView(
        titleBar: fluent_ui.TitleBar(
          isBackButtonVisible: false,
          title: Builder(
            builder: (context) {
              return SizedBox(
                width: MediaQuery.sizeOf(context).width,
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.wallpaper, size: 24),
                    ),
                    const Text(
                      'Blissful Backdrop',
                      style: TextStyle(fontSize: 16),
                    ),
                    Expanded(child: window_manager.MoveWindow()),
                    window_manager.MinimizeWindowButton(animate: true),
                    window_manager.RestoreWindowButton(animate: true),
                    window_manager.CloseWindowButton(
                      animate: true,
                      onPressed: () {
                        // Aptabase.instance.trackEvent('app_closed');
                        window_manager.appWindow.close();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        pane: fluent_ui.NavigationPane(
          selected: selectedPanelIndex,
          onChanged: (index) {
            setState(() {
              selectedPanelIndex = index;
            });
          },
          displayMode: fluent_ui.PaneDisplayMode.auto,
          // Avoid fluent_ui bug: pane uses height -1 when header==null and no menu button (invalid BoxConstraints)
          header: const SizedBox.shrink(),
          size: const fluent_ui.NavigationPaneSize(headerHeight: 0),
          items: items,
          footerItems: [
            fluent_ui.PaneItemAction(
                icon: const Icon(fluent_ui.FluentIcons.info),
                title: const Text('About'),
                onTap: () async {
                  if (packageInfo == null) {
                    PackageInfo pckgInfo = await PackageInfo.fromPlatform();
                    setState(() {
                      packageInfo = pckgInfo;
                    });
                  }
                  showDialog(
                      // ignore: use_build_context_synchronously
                      context: context,
                      builder: (context) => AboutApp(
                            appVersion: packageInfo!.version,
                          ),
                      barrierDismissible: true);
                }),
            // fluent_ui.PaneItem(
            //   icon: const Icon(fluent_ui.FluentIcons.settings),
            //   title: const Text('Settings'),
            //   body: Center(
            //     child: fluent_ui.ToggleSwitch(
            //       checked: false,
            //       onChanged: (value) {
            //         log(value.toString());
            //       },
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
