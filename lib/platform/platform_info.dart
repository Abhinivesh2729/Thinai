/// What kind of machine Thinai is running on, for the few decisions that
/// differ between the phone and desktop builds.
library;

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
