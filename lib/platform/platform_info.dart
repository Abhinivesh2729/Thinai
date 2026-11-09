/// What kind of machine Thinai is running on, for the few decisions that
/// differ between the phone and desktop builds.
library;

import 'dart:ffi' show Abi;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// True on Windows, macOS and Linux.
bool get isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux);

/// Ollama's port, used by the phone build where nothing else claims it.
const int kMobileServerPort = 11434;

/// Desktop default. Ollama usually already owns 11434 on a PC, so the
/// desktop build starts elsewhere; clients pick the port from the Server page.
const int kDesktopServerPort = 2727;

/// The API port used until the user picks one.
int get defaultServerPort => isDesktop ? kDesktopServerPort : kMobileServerPort;

/// CPU threads for inference. Phones stay at 2: more cores there means
/// efficiency cores and thermal throttling, and 2 measured fastest. On a PC
/// token speed scales with physical cores; x86 reports hyper-threads as cores
/// and llama.cpp gets slower when it oversubscribes them, so use half.
int inferenceThreads() {
  if (!isDesktop) return 2;
  final logical = Platform.numberOfProcessors;
  final physical =
      Abi.current() == Abi.windowsX64 ||
          Abi.current() == Abi.macosX64 ||
          Abi.current() == Abi.linuxX64
      ? logical ~/ 2
      : logical;
  return physical.clamp(2, 16);
}
