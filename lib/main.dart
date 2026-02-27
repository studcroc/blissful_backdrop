import 'dart:io';

import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:blissful_backdrop/about.dart';
import 'package:blissful_backdrop/active_wallpaper.dart';
import 'package:blissful_backdrop/app_shell/macos_ui_shell.dart';
import 'package:blissful_backdrop/app_shell/windows_ui_shell.dart';
import 'package:blissful_backdrop/check_update.dart';
import 'package:blissful_backdrop/home.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent_ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart' as window_manager;
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Workaround: macOS (and sometimes Cursor/IDE) can send duplicate KeyDown events
  // without KeyUp, triggering Flutter's HardwareKeyboard assertion. This is a known
  // framework/embedder bug; suppress it so the app doesn't flood the console.
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception is AssertionError &&
        details.stack != null &&
        details.stack.toString().contains('hardware_keyboard.dart') &&
        details.exception.toString().contains('KeyDownEvent') &&
        details.exception.toString().contains('already pressed')) {
      return; // known Flutter keyboard sync issue on macOS
    }
    previousOnError?.call(details);
  };

  // Initilize the analytics
  // await Aptabase.init(
  //     "A-SH-9850745473", const InitOptions(host: "http://13.201.134.252:8000"));

  doWhenWindowReady(() {
    window_manager.appWindow.alignment = Alignment.center;
    window_manager.appWindow.maximize();
    window_manager.appWindow.show();
  });

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://6d6ce2788ea17610d40279c84186f5d6@o1040380.ingest.us.sentry.io/4507128484003840';
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 0.6;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      options.profilesSampleRate = 1.0;
      if (kReleaseMode) {
        options.environment = 'production';
      } else {
        options.environment = 'development';
      }
    },
    appRunner: () => runApp(const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const fluent_ui.FluentApp(
      themeMode: ThemeMode.dark,
      title: 'Blissful Backdrop',
      home: MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
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
    if (Platform.isMacOS) {
      return ScaffoldMessenger(
        child: const MacOSUIShell(),
      );
    }
    if (Platform.isWindows) {
      return ScaffoldMessenger(
        child: const WindowsUIShell(),
      );
    }
    return const SizedBox.shrink();
  }
}
