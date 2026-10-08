import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../server/foreground_handler.dart';
import '../state/providers.dart';
import '../update/app_updater.dart';
import 'pages/chat_page.dart';
import 'pages/models_page.dart';
import 'pages/server_page.dart';
import 'pages/settings_page.dart';
import 'pages/splash_page.dart';
import 'widgets/chat_drawer.dart';
import 'widgets/coach_mark_targets.dart';
import 'widgets/app_tour_dialog.dart';
import 'widgets/onboarding_tour_screen.dart';

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
  final isDark = brightness == Brightness.dark;
  // Official Thinai logo leaf green and crisp error red
  const logoGreen = Color(0xFF2CA048);
  const errorRed = Color(0xFFDC2626);

  final baseScheme = ColorScheme.fromSeed(
    seedColor: logoGreen,
    brightness: brightness,
    error: errorRed,
  );

  final scheme = baseScheme.copyWith(
    primary: isDark ? logoGreen : const Color(0xFF1B8738),
    onPrimary: Colors.white,
    primaryContainer: isDark
        ? const Color(0x282CA048)
        : const Color(0x181B8738),
    onPrimaryContainer: isDark
        ? const Color(0xFF4ADE80)
        : const Color(0xFF14532D),
    error: errorRed,
    errorContainer: isDark
        ? const Color(0x28DC2626)
        : const Color(0x15DC2626),
    onErrorContainer: isDark
        ? const Color(0xFFFCA5A5)
        : const Color(0xFF991B1B),
    surface: isDark
        ? const Color(0xFF0B0E14)
        : const Color(0xFFFFFFFF),
    surfaceContainerLow: isDark
        ? const Color(0xFF121620)
        : const Color(0xFFF8FAFC),
    surfaceContainer: isDark
        ? const Color(0xFF171C28)
        : const Color(0xFFF1F5F9),
    surfaceContainerHigh: isDark
        ? const Color(0xFF1E2533)
        : const Color(0xFFE8EDF5),
    surfaceContainerHighest: isDark
        ? const Color(0xFF273142)
        : const Color(0xFFDCE3ED),
    onSurface: isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF0F172A),
    onSurfaceVariant: isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF475569),
    outline: isDark
        ? const Color(0xFF273242)
        : const Color(0xFFCBD5E1),
    outlineVariant: isDark
        ? const Color(0xFF344256)
        : const Color(0xFFE2E8F0),
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 21,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outline, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: logoGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outline, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: logoGreen.withValues(alpha: 0.14),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.25,
          color: selected
              ? (isDark ? Colors.white : const Color(0xFF090A0C))
              : scheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? logoGreen : scheme.onSurfaceVariant,
          size: 23,
        );
      }),
      height: 68,
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? const Color(0xFF1E252E) : const Color(0xFF0F172A),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class _Shell extends ConsumerStatefulWidget {
  const _Shell();

  @override
  ConsumerState<_Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<_Shell> {
  static const _tourSeenKey = 'app_tour_seen_v2';
  bool _booted = false;
  bool _needsOnboarding = false;

  @override
  void initState() {
    super.initState();
    FlutterForegroundTask.addTaskDataCallback(_onServiceData);
    _boot();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-warm the splash logos so the very first frame paints immediately without decode blanking.
    precacheImage(const AssetImage('assets/images/logo_dark.png'), context);
    precacheImage(const AssetImage('assets/images/logo_transparent.png'), context);
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

  /// Performs a fast, non-blocking splash transition into onboarding or the main shell.
  Future<void> _boot() async {
    // Kick off state restoration concurrently in the background so it never
    // blocks the UI shell or welcome sheet from rendering immediately.
    unawaited(ref.read(appBootstrapProvider.future).catchError((Object _) {}));

    // Pre-check whether this is the first launch while splash is displaying
    final prefs = await SharedPreferences.getInstance();
    _needsOnboarding = !(prefs.getBool(_tourSeenKey) ?? false);

    // Show the logo and brand presence for ~2.8s (~3s as requested: "likely 3s")
    // while all heavy database & model checks finish in the background.
    await Future<void>.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    setState(() => _booted = true);
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (!_booted) {
      child = const SplashPage(key: ValueKey('splash'));
    } else if (_needsOnboarding) {
      child = OnboardingTourScreen(
        key: const ValueKey('onboarding'),
        onComplete: () {
          if (mounted) setState(() => _needsOnboarding = false);
        },
        onNavigateTab: (tabIndex) {
          ref.read(shellTabIndexProvider.notifier).state = tabIndex;
          if (mounted) setState(() => _needsOnboarding = false);
        },
      );
    } else {
      child = const _MainShell(key: ValueKey('shell'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: child,
    );
  }
}

class _MainShell extends ConsumerStatefulWidget {
  const _MainShell({super.key});

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  static const _tourSeenKey = 'app_tour_seen_v2';
  bool _liveTourActive = false;
  int _liveTourStep = 0;
  int _lastTourRequest = 0;
  bool _logosPrecached = false;

  /// Tracks initialized tabs so inactive pages (e.g. Models with 30+ items,
  /// Server with docs) are constructed lazily only when visited, avoiding
  /// heavy multi-page widget trees during cold startup.
  final Set<int> _loadedTabs = {};

  List<Widget> _buildPages(int activeIndex) {
    _loadedTabs.add(activeIndex);
    return [
      _loadedTabs.contains(0) ? const ChatPage() : const SizedBox.shrink(),
      _loadedTabs.contains(1) ? const ModelsPage() : const SizedBox.shrink(),
      _loadedTabs.contains(2) ? const ServerPage() : const SizedBox.shrink(),
      _loadedTabs.contains(3) ? const SettingsPage() : const SizedBox.shrink(),
    ];
  }

  /// Set once Play answers with something newer than the running build. Null
  /// while up to date, while the check is in flight, and after the user
  /// dismisses the banner.
  UpdateStatus? _update;
  bool _updateCheckStarted = false;
  bool _updateBusy = false;
  StreamSubscription<InstallStatus>? _installSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_logosPrecached) {
      _logosPrecached = true;
      // Defer pre-warming logos by 2.5s so cold boot paints the initial UI
      // and welcome sheet with zero decode/GC stalls on the UI thread.
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) _precacheModelLogos();
      });
    }
  }

  /// Warms up real brand logo textures into Flutter's image cache in the background
  /// so visiting the Models page or chatting displays brand logos without decode stutter.
  void _precacheModelLogos() {
    const logos = [
      'assets/logos/baai.png',
      'assets/logos/deepseek.png',
      'assets/logos/gemma.png',
      'assets/logos/google.png',
      'assets/logos/huggingface.png',
      'assets/logos/ibm.png',
      'assets/logos/liquid.png',
      'assets/logos/meta.png',
      'assets/logos/microsoft.png',
      'assets/logos/mistral.png',
      'assets/logos/nomic.png',
      'assets/logos/qwen.png',
    ];
    for (final path in logos) {
      precacheImage(AssetImage(path), context);
    }
  }

  @override
  void initState() {
    super.initState();
    final startPage = ref.read(startPageProvider);
    ref.read(shellTabIndexProvider.notifier).state = startPage;
    _loadedTabs.add(startPage);
    // Defer Google Play store update check by 4s so cold boot has zero network/IPC overhead
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _checkForUpdate();
    });
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

  Future<void> _startAppTour({required bool markSeen}) async {
    if (!mounted) return;
    if (markSeen) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tourSeenKey, true);
    }
    if (!mounted) return;
    await OnboardingTourScreen.show(
      context: context,
      onNavigateTab: (tabIndex) {
        ref.read(shellTabIndexProvider.notifier).state = tabIndex;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(shellTabIndexProvider);
    final tourRequest = ref.watch(coachTourRequestProvider);

    if (tourRequest != _lastTourRequest) {
      _lastTourRequest = tourRequest;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startAppTour(markSeen: true);
      });
    }

    final update = _update;
    return Scaffold(
      key: shellScaffoldKey,
      drawer: const ChatDrawer(),
      body: Stack(
        children: [
          IndexedStack(index: index, children: _buildPages(index)),
          if (_liveTourActive)
            LiveGuidedTourDock(
              step: _liveTourStep,
              onStepChanged: (s) {
                setState(() => _liveTourStep = s);
                // Step 0 & 1 -> Models tab (1)
                // Step 2 -> Chat tab (0)
                // Step 3 -> Server tab (2)
                final targetTab = (s == 0 || s == 1) ? 1 : (s == 2 ? 0 : 2);
                ref.read(shellTabIndexProvider.notifier).state = targetTab;
              },
              onDismiss: () async {
                setState(() => _liveTourActive = false);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(_tourSeenKey, true);
              },
            ),
        ],
      ),
      // The banner rides above the navigation bar rather than above the body:
      // every page brings its own AppBar, and a notice pushed in over those
      // would sit in the status bar. Hidden while the coach tour runs, because
      // the spotlight measures its targets by where they are on screen.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (update != null && !_liveTourActive)
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
                icon: const Icon(Icons.memory_outlined),
                selectedIcon: const Icon(Icons.memory_rounded),
                label: 'Models',
              ),
              const NavigationDestination(
                icon: Icon(Icons.dns_outlined),
                selectedIcon: Icon(Icons.dns_rounded),
                label: 'Server',
              ),
              const NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Settings',
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
