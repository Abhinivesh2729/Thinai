/// Attaching an image to a conversation.
///
/// llama.cpp reads images through a projector loaded beside the weights, and
/// fllama's bridge finds them by scanning the prompt for
/// `<img src="data:image/…;base64,…">` tags, which it swaps for the media
/// marker before tokenising. So "showing the model a photo" comes down to
/// getting the bytes into the prompt in that exact shape.
library;

import 'dart:convert';
import 'dart:typed_data';

/// Formats llama.cpp's image loader handles.
const kImageExtensions = <String>{
  'png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif',
};

/// Largest image accepted, in bytes.
///
/// Not a limit of the encoder but of the phone: the bytes are base64'd into
/// the prompt string, which costs a third again in memory, and a 20 MP camera
/// original buys no accuracy over something far smaller — the projector
/// downsamples to a few hundred pixels a side regardless.
const int kMaxImageBytes = 8 * 1024 * 1024;

class ImageAttachment {
  final String name;

  /// Raw file bytes, kept so the picture can be shown in the composer.
  final Uint8List bytes;

  /// MIME type, from the extension.
  final String mimeType;

  const ImageAttachment({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });

  String get sizeLabel {
    final kb = bytes.length / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  /// The tag fllama's native side looks for. Everything before the base64 has
  /// to match, so this is not a place to be creative with the formatting.
  String get promptTag =>
      '<img src="data:$mimeType;base64,${base64Encode(bytes)}">';
}

String? mimeTypeForImage(String filename) {
  final dot = filename.lastIndexOf('.');
  if (dot < 0) return null;
  return switch (filename.substring(dot + 1).toLowerCase()) {
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'webp' => 'image/webp',
    'bmp' => 'image/bmp',
    'gif' => 'image/gif',
    _ => null,
  };
}

/// Builds an attachment, or throws [FormatException] with a message worth
/// showing.
ImageAttachment readImage(String filename, Uint8List bytes) {
  final mimeType = mimeTypeForImage(filename);
  if (mimeType == null) {
    throw const FormatException(
      'That image format is not supported. Use PNG, JPEG, WebP, BMP or GIF.',
    );
  }
  if (bytes.isEmpty) {
    throw const FormatException('That image is empty.');
  }
  if (bytes.length > kMaxImageBytes) {
    throw FormatException(
      'That image is ${(bytes.length / (1024 * 1024)).toStringAsFixed(1)} MB. '
      'Images up to ${kMaxImageBytes ~/ (1024 * 1024)} MB can be attached.',
    );
  }
  return ImageAttachment(name: filename, bytes: bytes, mimeType: mimeType);
}

/// Puts [image] in front of the model alongside [text].
///
/// The tag leads: a chat template renders the message as one block, and the
/// models here were trained with the image ahead of the question about it.
///
/// This is the only place a genuine `<img>` tag is allowed into a prompt.
/// Third-party text in [text] — web results, recalled sources — has already
/// been through `neutralizeUntrusted`, which breaks any `<img` it carries so a
/// page cannot slip the model a picture. The tag added here is applied after
/// that, and must stay that way round: neutralizing the finished prompt would
/// blind the model to the photo the user actually attached.
String promptWithImage(ImageAttachment? image, String text) {
  if (image == null) return text;
  return text.isEmpty
      ? image.promptTag
      : '${image.promptTag}\n\n$text';
}
