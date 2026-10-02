import 'package:flutter/services.dart';

/// Hands [text] to Android's share sheet.
///
/// A ten-line platform channel rather than a plugin: sharing plain text is one
/// intent, and the app keeps its dependency list short on purpose. Returns
/// false when there is no native side to answer (tests, other platforms), so
/// the caller can fall back to copying.
Future<bool> shareText(String text, {String? subject}) async {
  try {
    await _channel.invokeMethod<void>('shareText', {
      'text': text,
      'subject': ?subject,
    });
    return true;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
}

const _channel = MethodChannel('in.atmega.thinai/share');
