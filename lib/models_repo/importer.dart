import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'model_store.dart';

class ModelImporter {
  const ModelImporter();

  Future<LocalModel?> pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: false,
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.single;
    final sourcePath = picked.path;
    // Distinct from a cancelled pick, which returned above: a file was chosen
    // but the picker could not give a readable path for it. Reported rather
    // than swallowed, since silently doing nothing reads as a broken button.
    if (sourcePath == null) {
      throw StateError('Could not read the selected file.');
    }
    if (!sourcePath.toLowerCase().endsWith('.gguf')) {
      throw const FormatException('Selected file is not a .gguf model.');
    }

    final store = ModelStore.instance;
    final destPath = await store.pathForNewFile(picked.name);
    final source = File(sourcePath);

    final dest = File(destPath);
    if (await dest.exists()) {
      throw StateError('A model named ${picked.name} already exists.');
    }

    await _putInPlace(source, destPath);
    store.notifyChanged();
    return store.findById(_idFrom(picked.name));
  }

  /// Puts the picked file where the store expects it, moving rather than
  /// copying when that is safe.
  ///
  /// The picker hands back a copy it has already written into the app's cache,
  /// which is app-private and on the same filesystem as the models directory,
  /// so renaming it is instant. Copying instead would write a second full copy
  /// of a model that routinely runs to several gigabytes and leave the first
  /// sitting in the cache — double the disk for the duration, on a device that
  /// may not have it.
  ///
  /// A path from anywhere else belongs to the user, so it is copied. Moving it
  /// would take the original out from under them.
  Future<void> _putInPlace(File source, String destPath) async {
    if (await _isInAppCache(source.path)) {
      try {
        await source.rename(destPath);
        return;
      } on FileSystemException {
        // rename cannot cross filesystems; fall through and copy instead.
      }
    }
    await source.copy(destPath);
  }

  Future<bool> _isInAppCache(String filePath) async {
    try {
      final cache = await getTemporaryDirectory();
      var prefix = cache.path.replaceAll(r'\', '/');
      if (!prefix.endsWith('/')) prefix = '$prefix/';
      return filePath.replaceAll(r'\', '/').startsWith(prefix);
    } on Object {
      // Without a known cache root, copying is the safe assumption.
      return false;
    }
  }

  String _idFrom(String filename) {
    var name = filename;
    if (name.toLowerCase().endsWith('.gguf')) {
      name = name.substring(0, name.length - 5);
    }
    return name.toLowerCase();
  }
}
