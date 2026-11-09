/// Root widget of the desktop app.
library;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'dev_snapshots.dart';
import 'diagnostics.dart';
import 'shell/desk_nav.dart';
import 'shell/desk_shell.dart';
import 'theme/desk_theme.dart';
import 'widgets/toast.dart';

class DesktopApp extends ConsumerStatefulWidget {
  const DesktopApp({super.key, required this.launched});

  /// When main() started, for the startup timing in the log.
  final Stopwatch launched;

  @override
  ConsumerState<DesktopApp> createState() => _DesktopAppState();
}

class _DesktopAppState extends ConsumerState<DesktopApp> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Diagnostics.log(
        'startup: first frame at ${widget.launched.elapsedMilliseconds} ms',
      );
    });
    // Restore the last model and resume the server after the first frame, so
    // the window is on screen before any disk or socket work.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      ref
          .read(appBootstrapProvider.future)
          .then(
            (_) => Diagnostics.log(
              'startup: restored session at ${widget.launched.elapsedMilliseconds} ms',
            ),
            onError: (Object e) =>
                Diagnostics.log('startup: restore failed: $e'),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final tamil = ref.watch(isTamilUiProvider);
    return MaterialApp(
      title: 'Thinai',
      debugShowCheckedModeBanner: false,
      locale: ref.watch(appLocaleProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildDeskTheme(Brightness.light, tamil: tamil),
      darkTheme: buildDeskTheme(Brightness.dark, tamil: tamil),
      themeMode: themeMode,
      themeAnimationDuration: DeskMotion.slow,
      shortcuts: {...WidgetsApp.defaultShortcuts, ...deskShortcuts()},
      home: RepaintBoundary(
        key: snapshotBoundaryKey,
        child: const DeskToastLayer(child: DeskShell()),
      ),
    );
  }
}
