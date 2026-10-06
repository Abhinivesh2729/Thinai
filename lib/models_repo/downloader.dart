import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../server/foreground_handler.dart';
import 'model_store.dart';

class DownloadProgress {
  final int received;
  final int? total;
  final bool done;
  final String? error;

  /// The user stopped this download. Not a failure, and not worth an alarming
  /// message: they know, they did it.
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
    try {
      await _dio.download(
        url,
        tempPath,
        cancelToken: cancelToken,
        options: Options(followRedirects: true, receiveTimeout: null),
        onReceiveProgress: (received, total) {
          if (!controller.isClosed) {
            controller.add(DownloadProgress(
              received: received,
              total: total > 0 ? total : null,
              done: false,
            ));
          }
        },
      );

      final temp = File(tempPath);
      if (await temp.exists()) {
        await temp.rename(destPath);
      }
      store.notifyChanged();
      if (!controller.isClosed) {
        final size = await File(destPath).length();
        controller.add(DownloadProgress(
          received: size,
          total: size,
          done: true,
        ));
        await controller.close();
      }
    } catch (e) {
      final temp = File(tempPath);
      if (await temp.exists()) {
        await temp.delete().catchError((_) => temp);
      }
      if (!controller.isClosed) {
        final cancelled = e is DioException &&
            e.type == DioExceptionType.cancel;
        controller.add(DownloadProgress(
          received: 0,
          total: null,
          done: true,
          error: cancelled ? null : describeDownloadError(e),
          cancelled: cancelled,
        ));
        await controller.close();
      }
    } finally {
      await ForegroundServiceManager.downloadFinished(label);
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
  if (text.contains('SocketException') || text.contains('Failed host lookup')) {
    return 'No internet connection';
  }
  // Last resort: the first line, without the class name Dart prefixes.
  final firstLine = text.split('\n').first.trim();
  final colon = firstLine.indexOf(': ');
  return colon >= 0 && colon < 40
      ? firstLine.substring(colon + 2)
      : firstLine;
}
