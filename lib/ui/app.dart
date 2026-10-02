import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'theme/app_theme.dart';
import 'widgets/app_drawer.dart';
import 'widgets/coach_mark_targets.dart';
import 'widgets/spotlight_coach_marks.dart';
import 'widgets/ui_kit.dart';

class LocalLlmApp extends ConsumerWidget {
  const LocalLlmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Thinai',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: themeMode,
      home: const _Shell(),
    );
  }
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
      // A launch lands on a new chat, not on whatever was open when the app
      // was last closed. Done behind the splash so the old conversation never
      // flashes up first. Resuming from the background keeps the open chat,
      // since this only runs when the app starts.
      ref
          .read(chatSessionsProvider.notifier)
          .startFreshSession()
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
      final go = await confirmAction(
        context,
        title: 'Restart now?',
        message: 'A model is still downloading. Restarting cancels it.',
        confirmLabel: 'Restart',
        cancelLabel: 'Later',
      );
      if (!go || !mounted) return;
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
        targetKey: CoachMarkTargets.menuButton,
        title: 'Your menu',
        message:
            'Models, Server, your chats and Settings live here. Thinai runs '
            'models on your phone, so start by downloading one.',
        borderRadius: 24,
        beforeShow: () => _switchTabAndWait(0),
      ),
      SpotlightCoachStep(
        targetKey: CoachMarkTargets.firstCatalogAction,
        title: 'Step 1: Download a model',
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
        targetKey: CoachMarkTargets.benchmarkButton,
        title: 'Measure your phone',
        // Only means something once a model is running: the measurement it
        // takes is also what replaces the estimated speeds on the Models page
        // with real ones for this device.
        message:
            'Tap Benchmark to measure real speed on your phone, replacing '
            'the estimates.',
        borderRadius: 24,
        beforeShow: () => _switchTabAndWait(1),
      ),
      SpotlightCoachStep(
        targetKey: CoachMarkTargets.chatComposer,
        title: 'Step 2: Ask anything',
        message: 'Type your prompt and send. Responses generate on-device.',
        borderRadius: 26,
        beforeShow: () => _switchTabAndWait(0),
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
    // Back from Models or Server returns to the conversation: Chat is home,
    // the others are places visited from it. From Chat, back does what the
    // foreground-service wrapper used to: minimise while the server is
    // running, so the API keeps answering, and leave otherwise. Handled here
    // in one place because that wrapper's handler ran first and would have
    // minimised the app from any section.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (ref.read(shellTabIndexProvider) != 0) {
          ref.read(shellTabIndexProvider.notifier).state = 0;
          return;
        }
        if (await FlutterForegroundTask.isRunningService) {
          FlutterForegroundTask.minimizeApp();
          return;
        }
        await SystemNavigator.pop();
      },
      child: Scaffold(
        key: shellScaffoldKey,
        drawer: const AppDrawer(),
        body: IndexedStack(index: index, children: _pages),
        // Hidden while the coach tour runs, because the spotlight measures
        // its targets by where they are on screen.
        bottomNavigationBar: update != null && !_tourRunning
            ? SafeArea(
                top: false,
                child: _UpdateBanner(
                  status: update,
                  busy: _updateBusy,
                  onAct: update.state == UpdateState.readyToInstall
                      ? _installUpdate
                      : _downloadUpdate,
                  onDismiss: () => setState(() => _update = null),
                ),
              )
            : null,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ready = status.state == UpdateState.readyToInstall;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.sm),
      child: Material(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(Radii.lg),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.lg,
            Space.md,
            Space.xs,
            Space.md,
          ),
          child: Row(
            children: [
              Icon(
                ready
                    ? Icons.restart_alt_rounded
                    : Icons.system_update_alt_rounded,
                color: scheme.onInverseSurface,
                size: 22,
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ready ? 'Update ready' : 'Update available',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onInverseSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      busy
                          ? 'Downloading in the background…'
                          : ready
                          ? 'Restart Thinai to finish installing.'
                          : 'A newer version of Thinai is on Play Store.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onInverseSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              if (busy)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: scheme.onInverseSurface,
                    ),
                  ),
                )
              else ...[
                TextButton(
                  onPressed: onAct,
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.inversePrimary,
                  ),
                  child: Text(ready ? 'Restart' : 'Download'),
                ),
                IconButton(
                  tooltip: 'Dismiss',
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: scheme.onInverseSurface.withValues(alpha: 0.7),
                  onPressed: onDismiss,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
