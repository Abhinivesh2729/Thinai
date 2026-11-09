/// Window and tray behaviour.
///
/// Closing the window while the API server is running hides Thinai to the
/// tray instead of quitting, so editors and scripts using the local API keep
/// working (the desktop stand-in for Android's foreground service). With the
/// server off, closing quits as people expect.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../state/providers.dart';
import 'diagnostics.dart';

Future<void> initDeskWindow() async {
  await windowManager.ensureInitialized();
  const options = WindowOptions(
    size: Size(1240, 800),
    center: true,
    minimumSize: Size(880, 600),
    title: 'Thinai',
    titleBarStyle: TitleBarStyle.hidden,
    // macOS keeps its traffic lights; Windows draws ours.
    windowButtonVisibility: true,
    backgroundColor: Color(0xFF07090D),
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  await windowManager.setPreventClose(true);
}

/// Owns the tray icon and the close button's behaviour for the app's life.
class DeskWindowController with WindowListener, TrayListener {
  DeskWindowController(this._container);

  final ProviderContainer _container;
  bool _trayReady = false;

  Future<void> attach() async {
    windowManager.addListener(this);
    trayManager.addListener(this);
  }

  Future<void> _ensureTray() async {
    if (_trayReady) return;
    try {
      await trayManager.setIcon(
        Platform.isWindows
            ? 'assets/desktop/tray_icon.ico'
            : 'assets/desktop/tray_icon.png',
      );
      await trayManager.setToolTip('Thinai');
      await _refreshMenu();
      _trayReady = true;
    } on Object catch (e) {
      Diagnostics.log('tray: unavailable: $e');
    }
  }

  Future<void> _refreshMenu() async {
    final ta = _container.read(isTamilUiProvider);
    final status = _container.read(serverControllerProvider);
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'open', label: ta ? 'Thinai-ஐத் திற' : 'Open Thinai'),
          MenuItem.separator(),
          MenuItem(
            key: 'server',
            label: status.running
                ? (ta
                      ? 'சேவகத்தை நிறுத்து (:${status.port})'
                      : 'Stop server (:${status.port})')
                : (ta ? 'சேவகம் நிறுத்தத்தில்' : 'Server stopped'),
            disabled: !status.running,
          ),
          MenuItem.separator(),
          MenuItem(key: 'quit', label: ta ? 'வெளியேறு' : 'Quit'),
        ],
      ),
    );
  }

  Future<void> _quit() async {
    try {
      await _container.read(serverControllerProvider.notifier).stop();
    } on Object {
      // Quitting anyway.
    }
    await Diagnostics.flush();
    if (_trayReady) await trayManager.destroy();
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  @override
  Future<void> onWindowClose() async {
    final serving = _container.read(serverControllerProvider).running;
    if (!serving) {
      await _quit();
      return;
    }
    await _ensureTray();
    await _refreshMenu();
    await windowManager.hide();
    Diagnostics.log('window: hidden to tray, server still running');
  }

  @override
  void onTrayIconMouseDown() => _show();

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'open':
        await _show();
      case 'server':
        await _container.read(serverControllerProvider.notifier).stop();
        await _refreshMenu();
      case 'quit':
        await _quit();
    }
  }

  Future<void> _show() async {
    await windowManager.show();
    await windowManager.focus();
  }
}
