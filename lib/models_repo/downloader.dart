import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../server/foreground_handler.dart';
import 'model_store.dart';

class DownloadProgress {
  /// Bytes on disk so far, including any part kept from an earlier attempt.
  /// On a stopped download this is what was saved for a resume.
  final int received;
  final int? total;
  final bool done;
  final String? error;

  /// The user paused this download. Not a failure, and not worth an alarming
  /// message: they know, they did it. The part file is kept for a resume.
  final bool cancelled;

  const DownloadProgress({
    required this.received,
    required this.total,
    required this.done,
    this.error,
    this.cancelled = false,
  });

  double? get fraction {
    final t = total;
    if (t == null || t <= 0) return null;
    return received / t;
  }
}

class DownloadHandle {
  final String url;
  final String destPath;
  final CancelToken cancelToken;
  final Stream<DownloadProgress> progress;

  /// What this transfer is called where a person can see it — the model's
  /// display name, or its file name when there is nothing better. The
  /// background notification and the Models page both show it, so it lives on
  /// the handle rather than being rebuilt from an id at each call site.
  final String label;

  const DownloadHandle({
    required this.url,
    required this.destPath,
    required this.cancelToken,
    required this.progress,
    required this.label,
  });

  void cancel() {
    if (!cancelToken.isCancelled) {
      cancelToken.cancel('Cancelled by user');
    }
  }
}

class ModelDownloader {
  final Dio _dio;

  ModelDownloader({Dio? dio}) : _dio = dio ?? Dio();

  Future<DownloadHandle> start(
    String url, {
    String? filename,
    String? displayName,
  }) async {
    final name = filename ?? _filenameFromUrl(url);
    if (!name.toLowerCase().endsWith('.gguf')) {
      throw const FormatException(
        'URL does not point to a .gguf file. Provide a filename ending in .gguf.',
      );
    }

    final store = ModelStore.instance;
    final destPath = await store.pathForNewFile(name);
    final tempPath = '$destPath.part';

    final cancelToken = CancelToken();
    final controller = StreamController<DownloadProgress>.broadcast();

    // Label the download by its model name so the background notification can
    // show it. Falls back to the file name (minus .gguf).
    final label = displayName != null && displayName.trim().isNotEmpty
        ? displayName.trim()
        : _prettyName(name);

    // Hold the foreground service for the life of this download so the OS
    // keeps the isolate alive (and the transfer flowing) when the app is
    // backgrounded or the screen is locked.
    await ForegroundServiceManager.downloadStarted(label);
    unawaited(
      _download(url, tempPath, destPath, cancelToken, controller, store, label),
    );

    return DownloadHandle(
      url: url,
      destPath: destPath,
      cancelToken: cancelToken,
      progress: controller.stream,
      label: label,
    );
  }

  Future<void> _download(
    String url,
    String tempPath,
    String destPath,
    CancelToken cancelToken,
    StreamController<DownloadProgress> controller,
    ModelStore store,
    String label,
  ) async {
    bool succeeded = false;
    var received = 0;
    int? total;
    try {
      await fetchResumable(
        dio: _dio,
        url: url,
        partPath: tempPath,
        label: label,
        cancelToken: cancelToken,
        onProgress: (r, t) {
          received = r;
          total = t;
          ForegroundServiceManager.downloadProgress(label, r, t);
          if (!controller.isClosed) {
            controller.add(
              DownloadProgress(received: r, total: t, done: false),
            );
          }
        },
      );

      final temp = File(tempPath);
      if (await temp.exists()) {
        await temp.rename(destPath);
      }
      await deletePartialMeta(tempPath);
      store.notifyChanged();
      succeeded = true;
      await ForegroundServiceManager.downloadCompleted(label);

      if (!controller.isClosed) {
        final size = await File(destPath).length();
        controller.add(
          DownloadProgress(received: size, total: size, done: true),
        );
        await controller.close();
      }
    } catch (e) {
      // The part file stays where it is. Whether the user paused, the network
      // dropped or the disk filled up, the bytes already on the phone are
      // still good, and the next start picks up from them.
      store.notifyChanged();
      if (!controller.isClosed) {
        final cancelled =
            cancelToken.isCancelled ||
            (e is DioException && e.type == DioExceptionType.cancel);
        controller.add(
          DownloadProgress(
            received: received,
            total: total,
            done: true,
            error: cancelled ? null : describeDownloadError(e),
            cancelled: cancelled,
          ),
        );
        await controller.close();
      }
    } finally {
      if (!succeeded) {
        await ForegroundServiceManager.downloadFinished(label);
      }
    }
  }

  String _prettyName(String filename) {
    return filename.toLowerCase().endsWith('.gguf')
        ? filename.substring(0, filename.length - 5)
        : filename;
  }

  String _filenameFromUrl(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return 'model.gguf';
    return segments.last;
  }
}

/// Turns a download failure into something worth showing a user.
///
/// `DioException [connection error]: The connection errored...` names the
/// library that failed, which is not what the reader needs; they need to know
/// whether to check their signal, free some space, or try again later.
String describeDownloadError(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.cancel:
        return 'Cancelled';
      case DioExceptionType.connectionError:
        return 'No internet connection';
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'Connection timed out - check your signal and try again';
      case DioExceptionType.badCertificate:
        return 'Could not verify the download server';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        if (status == 404) return 'That model is no longer available';
        if (status == 401 || status == 403) {
          return 'That model needs sign-in to download';
        }
        return 'Download server error${status == null ? '' : ' ($status)'}';
      case DioExceptionType.unknown:
        return _describeCause(error.error ?? error);
    }
  }
  return _describeCause(error);
}

String _describeCause(Object error) {
  final text = error.toString();
  if (error is FileSystemException || text.contains('No space left')) {
    return 'Not enough storage on this phone';
  }
  if (text.contains('SocketException') ||
      text.contains('Failed host lookup') ||
      text.contains('Connection closed')) {
    return 'No internet connection';
  }
  // Last resort: the first line, without the class name Dart prefixes.
  final firstLine = text.split('\n').first.trim();
  final colon = firstLine.indexOf(': ');
  return colon >= 0 && colon < 40 ? firstLine.substring(colon + 2) : firstLine;
}

/// What is known about a `.part` file, stored beside it as `<part>.json`.
///
/// The part file alone says how many bytes arrived, but not where they came
/// from or how many to expect. Without this a paused download could not show
/// a percentage, could not be resumed from the Model Manager, and could not
/// tell that the file upstream had changed under it.
class PartialMeta {
  final String url;
  final String? label;
  final int? total;

  /// The server's strong ETag for the file, sent back as `If-Range` so a file
  /// replaced upstream restarts cleanly instead of being stitched together
  /// from two different uploads.
  final String? etag;

  const PartialMeta({required this.url, this.label, this.total, this.etag});

  Map<String, dynamic> toJson() => {
    'url': url,
    if (label != null) 'label': label,
    if (total != null) 'total': total,
    if (etag != null) 'etag': etag,
  };

  static PartialMeta? fromJson(Object? json) {
    if (json is! Map) return null;
    final url = json['url'];
    if (url is! String || url.isEmpty) return null;
    final total = json['total'];
    final label = json['label'];
    final etag = json['etag'];
    return PartialMeta(
      url: url,
      label: label is String ? label : null,
      total: total is int ? total : null,
      etag: etag is String ? etag : null,
    );
  }
}

String partialMetaPath(String partPath) => '$partPath.json';

Future<PartialMeta?> readPartialMeta(String partPath) async {
  final file = File(partialMetaPath(partPath));
  try {
    if (!await file.exists()) return null;
    return PartialMeta.fromJson(jsonDecode(await file.readAsString()));
  } catch (_) {
    return null;
  }
}

Future<void> _writePartialMeta(String partPath, PartialMeta meta) async {
  await File(partialMetaPath(partPath)).writeAsString(jsonEncode(meta));
}

Future<void> deletePartialMeta(String partPath) async {
  final file = File(partialMetaPath(partPath));
  if (await file.exists()) {
    await file.delete().catchError((_) => file);
  }
}

/// `Content-Range: bytes <start>-<end>/<total>`, or null when it does not
/// parse. The total may be `*` (unknown), which comes back as null.
({int start, int? total})? parseContentRange(String? header) {
  if (header == null) return null;
  final match = RegExp(
    r'^bytes\s+(\d+)-(\d+)/(\d+|\*)$',
  ).firstMatch(header.trim());
  if (match == null) return null;
  final start = int.parse(match.group(1)!);
  final rawTotal = match.group(3)!;
  return (start: start, total: rawTotal == '*' ? null : int.parse(rawTotal));
}

/// Downloads [url] into [partPath], continuing from whatever is already there.
///
/// Sends `Range: bytes=<size>-` when a part exists and appends what comes
/// back. Falls back to a full download when the server ignores the range
/// (200), says the file changed (200 to an `If-Range`), or rejects the range
/// (416) for a part that is not already complete. Returns the final size.
///
/// The part file is never deleted on failure: that is the point. Throws on
/// cancel, network loss or an incomplete body, leaving the bytes in place.
Future<int> fetchResumable({
  required Dio dio,
  required String url,
  required String partPath,
  required CancelToken cancelToken,
  required void Function(int received, int? total) onProgress,
  String? label,
  bool allowRestart = true,
}) async {
  final part = File(partPath);
  final meta = await readPartialMeta(partPath);
  var offset = await part.exists() ? await part.length() : 0;
  // A part from a different source is not a head start on this one.
  if (offset > 0 && meta != null && meta.url != url) offset = 0;

  final headers = <String, dynamic>{};
  if (offset > 0) {
    headers['range'] = 'bytes=$offset-';
    final etag = meta?.etag;
    if (etag != null && !etag.startsWith('W/')) headers['if-range'] = etag;
  }

  final response = await dio.get<ResponseBody>(
    url,
    cancelToken: cancelToken,
    options: Options(
      responseType: ResponseType.stream,
      followRedirects: true,
      // Between chunks, not for the whole file: a dead connection fails in
      // seconds instead of hanging, and the part is kept for a resume.
      receiveTimeout: const Duration(seconds: 30),
      headers: headers,
      validateStatus: (s) => s != null && ((s >= 200 && s < 300) || s == 416),
    ),
  );
  final body = response.data!;
  final status = response.statusCode ?? 200;

  Future<int> restart() async {
    await body.stream.listen(null).cancel().catchError((_) {});
    if (await part.exists()) await part.delete();
    await deletePartialMeta(partPath);
    if (!allowRestart) {
      throw const HttpException('The download server rejected the resume');
    }
    return fetchResumable(
      dio: dio,
      url: url,
      partPath: partPath,
      cancelToken: cancelToken,
      onProgress: onProgress,
      label: label,
      allowRestart: false,
    );
  }

  if (status == 416) {
    // Nothing left to send past the end of the file. That is only good news
    // when the part is exactly the size the server reported last time.
    final total = meta?.total;
    if (offset > 0 && total != null && offset == total) {
      await body.stream.listen(null).cancel().catchError((_) {});
      onProgress(offset, total);
      return offset;
    }
    return restart();
  }

  int? total;
  FileMode mode;
  if (status == 206 && offset > 0) {
    final range = parseContentRange(response.headers.value('content-range'));
    if (range == null || range.start != offset) return restart();
    total = range.total;
    mode = FileMode.append;
  } else {
    offset = 0;
    final length = int.tryParse(
      response.headers.value(Headers.contentLengthHeader) ?? '',
    );
    total = length != null && length > 0 ? length : null;
    mode = FileMode.write;
  }

  await _writePartialMeta(
    partPath,
    PartialMeta(
      url: url,
      label: label,
      total: total,
      etag: response.headers.value('etag'),
    ),
  );

  final sink = part.openWrite(mode: mode);
  var received = offset;
  onProgress(received, total);

  final done = Completer<void>();
  late final StreamSubscription<List<int>> sub;
  sub = body.stream.listen(
    (chunk) {
      sink.add(chunk);
      received += chunk.length;
      onProgress(received, total);
    },
    onError: (Object e, StackTrace st) {
      if (!done.isCompleted) done.completeError(e, st);
    },
    onDone: () {
      if (!done.isCompleted) done.complete();
    },
    cancelOnError: true,
  );
  // A stalled stream never errors on its own when the user pauses, so the
  // cancel token ends it directly.
  unawaited(
    cancelToken.whenCancel.then((e) async {
      await sub.cancel();
      if (!done.isCompleted) done.completeError(e);
    }),
  );

  try {
    await done.future;
  } finally {
    await sink.flush().catchError((_) {});
    await sink.close().catchError((_) {});
  }

  if (total != null && received != total) {
    throw HttpException(
      'Connection closed before the download finished '
      '($received of $total bytes)',
    );
  }
  return received;
}
