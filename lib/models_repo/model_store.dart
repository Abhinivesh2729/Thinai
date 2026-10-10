import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocalModel {
  final String id;
  final String displayName;
  final String path;
  final int sizeBytes;
  final DateTime modifiedAt;

  const LocalModel({
    required this.id,
    required this.displayName,
    required this.path,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class ModelStore {
  ModelStore._();
  static final ModelStore instance = ModelStore._();

  Directory? _dir;
  final _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  Future<Directory> modelsDir() async {
    final cached = _dir;
    if (cached != null) return cached;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/models');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _dir = dir;
    return dir;
  }

  Future<List<LocalModel>> list() async {
    final dir = await modelsDir();
    final entries = await dir.list().toList();
    final models = <LocalModel>[];
    for (final entry in entries) {
      if (entry is! File) continue;
      if (!entry.path.toLowerCase().endsWith('.gguf')) continue;
      final stat = await entry.stat();
      final filename = entry.uri.pathSegments.last;
      // Projectors are GGUFs living beside the weights they belong to, but
      // they are not models: one loaded as a chat model would fail on the
      // first message, and listing it invites exactly that.
      if (isProjectorFilename(filename)) continue;
      final id = _idFromFilename(filename);
      models.add(
        LocalModel(
          id: id,
          displayName: filename,
          path: entry.path,
          sizeBytes: stat.size,
          modifiedAt: stat.modified,
        ),
      );
    }
    models.sort((a, b) => a.displayName.compareTo(b.displayName));
    return models;
  }

  /// Path to the image encoder that belongs to [filename], or null when it
  /// has not been downloaded.
  ///
  /// Matching is by the model's own name rather than a stored association:
  /// the projector arrives as `mmproj-<model>.gguf`, and a file on disk is the
  /// only state that survives a reinstall.
  Future<String?> projectorPathFor(String? projectorFilename) async {
    if (projectorFilename == null || projectorFilename.isEmpty) return null;
    final dir = await modelsDir();
    final file = File('${dir.path}/$projectorFilename');
    return await file.exists() ? file.path : null;
  }

  Future<LocalModel?> findById(String id) async {
    final all = await list();
    for (final m in all) {
      if (m.id == id) return m;
    }
    return null;
  }

  Future<String> pathForNewFile(String filename) async {
    final dir = await modelsDir();
    return '${dir.path}/${_sanitizeFilename(filename)}';
  }

  Future<void> delete(LocalModel model) async {
    final file = File(model.path);
    if (await file.exists()) {
      await file.delete();
    }
    _changes.add(null);
  }

  Future<int> clearAllDownloads() async {
    final dir = await modelsDir();
    final entries = await dir.list().toList();
    var removed = 0;
    for (final entry in entries) {
      if (entry is! File) continue;
      final path = entry.path.toLowerCase();
      if (!path.endsWith('.gguf') && !path.endsWith('.part')) continue;
      if (await entry.exists()) {
        await entry.delete();
        removed++;
      }
    }
    _changes.add(null);
    return removed;
  }

  void notifyChanged() => _changes.add(null);

  String _idFromFilename(String filename) {
    var name = filename;
    if (name.toLowerCase().endsWith('.gguf')) {
      name = name.substring(0, name.length - 5);
    }
    return name.toLowerCase();
  }

  String _sanitizeFilename(String filename) {
    return filename.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }
}

/// True when [filename] is an image encoder rather than a model.
///
/// Every projector published for the catalogue's vision models is named
/// `mmproj-…`, which llama.cpp's own tooling also assumes.
bool isProjectorFilename(String filename) =>
    filename.toLowerCase().startsWith('mmproj');
