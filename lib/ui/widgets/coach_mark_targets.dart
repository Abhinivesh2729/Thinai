import 'package:flutter/material.dart';

class CoachMarkTargets {
  CoachMarkTargets._();

  static final chatTab = GlobalKey(debugLabel: 'coach_chat_tab');
  static final modelsTab = GlobalKey(debugLabel: 'coach_models_tab');
  static final modelsTourButton = GlobalKey(
    debugLabel: 'coach_models_tour_button',
  );
  static final firstCatalogAction = GlobalKey(
    debugLabel: 'coach_first_catalog_action',
  );
  static final chatComposer = GlobalKey(debugLabel: 'coach_chat_composer');
  static final benchmarkButton = GlobalKey(debugLabel: 'coach_benchmark');

  /// The Models page's list, so the tour can scroll to a target that is not on
  /// screen when the step begins.
  ///
  /// Held here rather than inside the page because the tour is driven from the
  /// app shell and has no other handle on it.
  static final modelsScroll = ScrollController();
}

/// Scrolls [controller] until [key]'s widget exists and is in view.
///
/// Two problems, and only the second is what `Scrollable.ensureVisible`
/// solves. A list builds lazily, so a target far enough down has no element at
/// all — no context, nothing to make visible, and the tour step silently
/// skips. Stepping through the list a screen at a time is what brings the
/// widget into existence; only then is there something to align.
///
/// Gives up after [maxSteps] screens so a target that never appears (a
/// filtered list, an empty catalogue) costs a moment rather than a hang.
Future<void> revealCoachTarget(
  GlobalKey key,
  ScrollController controller, {
  int maxSteps = 12,
  double alignment = 0.35,
}) async {
  if (!controller.hasClients) return;

  for (var step = 0; step < maxSteps; step++) {
    final context = key.currentContext;
    if (context != null) {
      if (context.mounted && Scrollable.maybeOf(context) != null) {
        await Scrollable.ensureVisible(
          context,
          alignment: alignment,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }

    final position = controller.position;
    if (position.pixels >= position.maxScrollExtent) return;

    final next = (position.pixels + position.viewportDimension * 0.85)
        .clamp(0.0, position.maxScrollExtent);
    await controller.animateTo(
      next,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
    // Let the newly scrolled-in children build before looking again.
    await Future<void>.delayed(const Duration(milliseconds: 40));
  }
}
