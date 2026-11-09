/// Dev-only visual check: with THINAI_SNAPSHOT_DIR set, the app renders each
/// page to a PNG and quits. Lets a build be inspected on a machine where
/// screen recording is not allowed (CI, a headless Mac). Inert otherwise.
library;

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import 'chat/desk_chat_controller.dart';
import 'pages/lab/lab_common.dart';
import 'pages/lab_page.dart';
import 'shell/desk_nav.dart';

final snapshotBoundaryKey = GlobalKey();

String? get snapshotDir => Platform.environment['THINAI_SNAPSHOT_DIR'];

Future<void> runSnapshots(ProviderContainer container) async {
  final dir = snapshotDir;
  if (dir == null) return;
  await Directory(dir).create(recursive: true);
  final dark = Platform.environment['THINAI_SNAPSHOT_THEME'] != 'light';
  Future<void> shot(String name) async {
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    final boundary =
        snapshotBoundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      '$dir/${dark ? 'dark' : 'light'}_$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
  }

  // Optional scripted chat: load the first installed model, ask, and shoot
  // the reply once it has finished streaming.
  final prompt = Platform.environment['THINAI_SNAPSHOT_PROMPT'];
  if (prompt != null) {
    await shot('chat_empty');
    final models = await container.read(modelListProvider.future);
    if (models.isNotEmpty) {
      await container.read(activeModelIdProvider.notifier).set(models.first);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await shot('chat_ready');
      unawaited(container.read(deskChatProvider.notifier).send(prompt));
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      await shot('chat_streaming');
      for (var i = 0; i < 240; i++) {
        if (!container.read(deskChatProvider).generating) break;
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      await shot('chat_reply');
    }
  }

  for (final page in DeskPage.values) {
    container.read(deskPageProvider.notifier).state = page;
    await shot(page.name);
  }
  container.read(deskPageProvider.notifier).state = DeskPage.lab;
  for (final tab in LabTab.values) {
    container.read(labTabProvider.notifier).state = tab;
    await shot('lab_${tab.name}');
  }
  // Optional: press Run on the speed benchmark and the Tamil eval, the way a
  // person would, and shoot each mid-run. CI uses this to catch crashes in
  // what the Lab draws while a run is going.
  if (Platform.environment['THINAI_SNAPSHOT_LAB_RUN'] != null) {
    final models = await container.read(modelListProvider.future);
    if (models.isNotEmpty) {
      await container.read(activeModelIdProvider.notifier).set(models.first);
      container.read(labTabProvider.notifier).state = LabTab.speed;
      await Future<void>.delayed(const Duration(milliseconds: 800));
      container.read(labRunRequestProvider.notifier).state = LabJob.speed;
      await _waitFor(() => container.read(labBusyProvider) != null, 10);
      await shot('lab_speed_running');
      await _waitFor(() => container.read(labBusyProvider) == null, 180);
      await shot('lab_speed_done');

      container.read(labTabProvider.notifier).state = LabTab.tamil;
      await Future<void>.delayed(const Duration(milliseconds: 800));
      container.read(labRunRequestProvider.notifier).state = LabJob.tamil;
      await _waitFor(() => container.read(labBusyProvider) != null, 10);
      await Future<void>.delayed(const Duration(seconds: 25));
      await shot('lab_tamil_running');

      container.read(labTabProvider.notifier).state = LabTab.load;
      await shot('lab_load_running');
    }
  }

  container.read(deskPageProvider.notifier).state = DeskPage.chat;
  exit(0);
}

Future<void> _waitFor(bool Function() done, int seconds) async {
  for (var i = 0; i < seconds * 4; i++) {
    if (done()) return;
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
}
