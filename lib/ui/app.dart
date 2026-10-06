import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models_repo/catalog.dart';
import '../server/foreground_handler.dart';
import '../state/providers.dart';
import '../update/app_updater.dart';
import 'pages/chat_page.dart';
import 'pages/models_page.dart';
import 'pages/server_page.dart';
import 'pages/splash_page.dart';
import 'widgets/coach_mark_targets.dart';
import 'widgets/spotlight_coach_marks.dart';

class LocalLlmApp extends ConsumerWidget {
  const LocalLlmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Thinai',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: themeMode,
      home: WithForegroundTask(child: const _Shell()),
    );
  }
}

/// Builds the app theme for the given brightness. Light and dark share the
/// same shape and component styling. Only the seeded [ColorScheme] differs,
/// so every screen adapts automatically.
ThemeData _buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0E4B75),
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: scheme.surface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      height: 72,
    ),
  );
}

class _Shell extends ConsumerStatefulWidget {
  const _Shell();

  @override
  ConsumerState<_Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<_Shell> {
  bool _showMainApp = false;

  @override
  void initState() {
    super.initState();
    FlutterForegroundTask.addTaskDataCallback(_onServiceData);
    _boot();
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onServiceData);
    super.dispose();
  }

  /// Handles the notification's Stop button. The tap arrives in the service's
  /// task isolate and is forwarded here, because this is the isolate holding
  /// the HTTP server.
  void _onServiceData(Object data) {
    if (data != kStopServerAction) return;
    () async {
      await ForegroundServiceManager.serverStopped();
      await ref.read(serverControllerProvider.notifier).stop();
    }();
  }

  /// Holds the splash until session state is restored, so the first frame of
  /// the app already shows the right model and server state instead of
  /// flashing "Stopped" and correcting itself.
  Future<void> _boot() async {
    await Future.wait([
      Future<void>.delayed(const Duration(seconds: 3)),
      // Bounded on purpose. Restoring state reads preferences, lists the
      // models directory, and may bind a socket; if any of that ever stalls,
      // the app should still open rather than sit on the splash forever.
      ref
          .read(appBootstrapProvider.future)
          .catchError((Object _) {})
          .timeout(const Duration(seconds: 10), onTimeout: () {}),
    ]);
    if (!mounted) return;
    setState(() => _showMainApp = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_showMainApp) {
      return const SplashPage();
    }
    return const _MainShell();
  }
}

class _MainShell extends ConsumerStatefulWidget {
  const _MainShell();

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  static const _tourSeenKey = 'app_tour_seen_v2';
  bool _tourCheckStarted = false;
  bool _tourRunning = false;
  int _lastTourRequest = 0;

  /// Set once Play answers with something newer than the running build. Null
  /// while up to date, while the check is in flight, and after the user
  /// dismisses the banner.
  UpdateStatus? _update;
  bool _updateCheckStarted = false;
  bool _updateBusy = false;
  StreamSubscription<InstallStatus>? _installSub;

  final _pages = const [ChatPage(), ModelsPage(), ServerPage()];

  @override
  void initState() {
    super.initState();
    _maybeShowInitialTour();
    _checkForUpdate();
  }

  @override
  void dispose() {
    _installSub?.cancel();
    super.dispose();
  }

  /// Asks Play, once per launch, whether a newer build is published. Silent
  /// when there is nothing: the only visible outcome is the banner in [build].
  Future<void> _checkForUpdate() async {
    if (_updateCheckStarted) return;
    _updateCheckStarted = true;
    final updater = ref.read(appUpdaterProvider);
    final status = await updater.check();
    if (!mounted || !status.hasUpdate) return;
    // A release published at priority 4+ (or one this device has ignored for a
    // fortnight) is not worth a banner someone can scroll past. Play takes the
    // screen, installs, and restarts; if the user backs out we fall through to
    // the banner rather than nag again.
    if (status.isCritical) {
      await updater.updateNow();
      if (!mounted) return;
    }
    setState(() => _update = status);
  }

  /// Downloads in the background. Play shows a consent sheet of its own first,
  /// which is why this hangs off a tap rather than the check above.
  Future<void> _downloadUpdate() async {
    if (_updateBusy) return;
    setState(() => _updateBusy = true);
    final updater = ref.read(appUpdaterProvider);
    // Two signals for the same event, on purpose: the future below resolves on
    // a clean download, and Play's listener still reports DOWNLOADED if the
    // download finished while the app was backgrounded.
    _installSub ??= updater.installProgress.listen((status) {
      if (!mounted || status != InstallStatus.downloaded) return;
      setState(() {
        _update = const UpdateStatus(UpdateState.readyToInstall);
        _updateBusy = false;
      });
    });
    final result = await updater.download();
    if (!mounted) return;
    setState(() {
      _updateBusy = false;
      switch (result) {
        case AppUpdateResult.success:
          _update = const UpdateStatus(UpdateState.readyToInstall);
        case AppUpdateResult.userDeniedUpdate:
          _update = null;
        case AppUpdateResult.inAppUpdateFailed:
          break;
      }
    });
  }

  /// Applies the downloaded build. Play restarts the app to install, which
  /// takes the process down with it — and a model download has no resume, so
  /// one in flight would start over from zero. Worth a question first.
  Future<void> _installUpdate() async {
    if (_updateBusy) return;
    if (ref.read(downloadsProvider).isNotEmpty) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restart now?'),
          content: const Text(
            'A model is still downloading. Restarting cancels it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restart'),
            ),
          ],
        ),
      );
      if (go != true || !mounted) return;
    }
    setState(() => _updateBusy = true);
    await ref.read(appUpdaterProvider).install();
    if (mounted) setState(() => _updateBusy = false);
  }

  Future<void> _maybeShowInitialTour() async {
    if (_tourCheckStarted) return;
    _tourCheckStarted = true;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_tourSeenKey) ?? false;
    if (!mounted || seen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startCoachTour(markSeen: true);
    });
  }

  /// Wording for the download step. Points at the icon on any card, and
  /// names the smallest model for anyone who would rather not choose.
  String _starterModelAdvice() {
    final starter = starterModel;
    if (starter == null) {
      return 'Tap the download icon on any model. Smaller ones run faster.';
    }
    return 'Tap the download icon. ${starter.displayName} '
        '(${starter.approxSize}) is the smallest, a safe first pick.';
  }

  Future<void> _switchTabAndWait(int index) async {
    ref.read(shellTabIndexProvider.notifier).state = index;
    await Future<void>.delayed(const Duration(milliseconds: 260));
  }

  List<SpotlightCoachStep> _buildCoachSteps() {
    return [
      SpotlightCoachStep(
        targetKey: CoachMarkTargets.modelsTab,
        title: 'Step 1: Open Models',
        message:
            'Thinai runs models on your phone. Download one before you chat.',
        borderRadius: 24,
        beforeShow: () => _switchTabAndWait(1),
      ),
      SpotlightCoachStep(
        targetKey: CoachMarkTargets.modelsTourButton,
        title: 'Settings and tools',
        message: 'Open Settings here for import, downloads, and support.',
        borderRadius: 24,
        beforeShow: () => _switchTabAndWait(1),
      ),
      SpotlightCoachStep(
        targetKey: CoachMarkTargets.firstCatalogAction,
        title: 'Step 2: Download a model',
        // Names the smallest model and its size: this step stands in for the
        // first-run auto-download that used to happen, so it has to answer
        // "which one" and "how big" rather than leave someone staring at 22
        // chat models.
        message: _starterModelAdvice(),
        borderRadius: 20,
        // The catalogue sits below the advisor and the installed models, far
        // enough down that the card is not built yet. Scrolling to it is what
        // brings it into existence for the spotlight to find.
        beforeShow: () async {
          await _switchTabAndWait(1);
          await revealCoachTarget(
            CoachMarkTargets.firstCatalogAction,
            CoachMarkTargets.modelsScroll,
          );
        },
      ),
      SpotlightCoachStep(
        targetKey: CoachMarkTargets.chatTab,
        title: 'Step 3: Go to Chat',
        message: 'With a model active, go to Chat to start talking.',
        borderRadius: 24,
        beforeShow: () => _switchTabAndWait(1),
      ),
      SpotlightCoachStep(
        targetKey: CoachMarkTargets.chatComposer,
        title: 'Step 4: Type and send',
        message: 'Type your prompt and send. Responses generate on-device.',
        borderRadius: 22,
        beforeShow: () => _switchTabAndWait(0),
      ),
      SpotlightCoachStep(
        targetKey: CoachMarkTargets.benchmarkButton,
        title: 'Measure your phone',
        // Last, because it only means something once a model is running: the
        // measurement it takes is also what replaces the estimated speeds on
        // the Models page with real ones for this device.
        message:
            'Tap Benchmark to measure real speed on your phone, replacing '
            'the estimates.',
        borderRadius: 24,
        beforeShow: () => _switchTabAndWait(1),
      ),
    ];
  }

  Future<void> _startCoachTour({required bool markSeen}) async {
    if (_tourRunning || !mounted) return;
    _tourRunning = true;
    try {
      await SpotlightCoachMarks.show(
        context: context,
        steps: _buildCoachSteps(),
      );
    } finally {
      _tourRunning = false;
      // The update banner is suppressed while the tour runs; this is what
      // brings it back once the spotlight is gone.
      if (mounted) setState(() {});
      if (markSeen) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_tourSeenKey, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(shellTabIndexProvider);
    final tourRequest = ref.watch(coachTourRequestProvider);

    if (tourRequest != _lastTourRequest) {
      _lastTourRequest = tourRequest;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startCoachTour(markSeen: true);
      });
    }

    final update = _update;
    return Scaffold(
      body: IndexedStack(index: index, children: _pages),
      // The banner rides above the navigation bar rather than above the body:
      // every page brings its own AppBar, and a notice pushed in over those
      // would sit in the status bar. Hidden while the coach tour runs, because
      // the spotlight measures its targets by where they are on screen.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (update != null && !_tourRunning)
            _UpdateBanner(
              status: update,
              busy: _updateBusy,
              onAct: update.state == UpdateState.readyToInstall
                  ? _installUpdate
                  : _downloadUpdate,
              onDismiss: () => setState(() => _update = null),
            ),
          NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) {
              ref.read(shellTabIndexProvider.notifier).state = i;
            },
            destinations: [
              NavigationDestination(
                key: CoachMarkTargets.chatTab,
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                selectedIcon: const Icon(Icons.chat_bubble_rounded),
                label: 'Chat',
              ),
              NavigationDestination(
                key: CoachMarkTargets.modelsTab,
                icon: const Icon(Icons.auto_awesome_outlined),
                selectedIcon: const Icon(Icons.auto_awesome_rounded),
                label: 'Models',
              ),
              const NavigationDestination(
                icon: Icon(Icons.cloud_outlined),
                selectedIcon: Icon(Icons.cloud_rounded),
                label: 'Server',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The one visible piece of the update flow: a strip above the navigation bar
/// saying a newer Thinai exists, then that it is ready to install.
///
/// Deliberately not a dialog. Nothing here is urgent enough to interrupt a
/// conversation for — an update that is urgent goes through Play's own
/// full-screen flow instead, before this ever renders.
class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner({
    required this.status,
    required this.busy,
    required this.onAct,
    required this.onDismiss,
  });

  final UpdateStatus status;
  final bool busy;
  final VoidCallback onAct;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ready = status.state == UpdateState.readyToInstall;

    return Material(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            Icon(
              ready
                  ? Icons.restart_alt_rounded
                  : Icons.system_update_alt_rounded,
              color: scheme.onPrimaryContainer,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ready ? 'Update ready' : 'Update available',
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    busy
                        ? 'Downloading in the background…'
                        : ready
                        ? 'Restart Thinai to finish installing.'
                        : 'A newer version of Thinai is on Play Store.',
                    style: TextStyle(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              )
            else ...[
              TextButton(
                onPressed: onAct,
                child: Text(ready ? 'Restart' : 'Download'),
              ),
              IconButton(
                tooltip: 'Dismiss',
                icon: const Icon(Icons.close_rounded, size: 20),
                color: scheme.onPrimaryContainer,
                onPressed: onDismiss,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
