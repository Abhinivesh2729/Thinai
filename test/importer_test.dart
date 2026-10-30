import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:local_llm/models_repo/importer.dart';

/// Tests for [ModelImporter] against a fake picker, so the import rules run
/// without a platform dialog.
///
/// path_provider is mocked to one temp directory for both the app-support and
/// the cache root, so a file picked from inside it counts as the picker's own
/// cache copy, and one picked from anywhere else as the user's original.

late Directory _support;

Directory get _modelsDir => Directory('${_support.path}/models');

class _FakePicker extends FilePickerPlatform {
  PlatformFile? next;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => next;
}

final class _PickedFile extends PlatformFile {
  _PickedFile(this.name, this.uri);

  @override
  final String name;

  @override
  final Uri uri;

  @override
  get xFile => throw UnimplementedError();

  @override
  int? lengthSync() => null;

  @override
  Future<int?> length() async => null;

  @override
  Future<Uint8List> readAsBytes() => throw UnimplementedError();

  @override
  Stream<Uint8List> readAsByteStream() => throw UnimplementedError();
}

late _FakePicker _picker;

Future<File> _fileAt(String path) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  return file.writeAsBytes([1, 2, 3]);
}

void main() {
  setUpAll(() async {
    _support = await Directory.systemTemp.createTemp('thinai_importer_');
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => _support.path,
        );
    _picker = _FakePicker();
    FilePickerPlatform.instance = _picker;
  });

  tearDownAll(() async {
    if (await _support.exists()) await _support.delete(recursive: true);
  });

  setUp(() async {
    // ModelStore caches its directory, so empty it rather than replace it.
    if (await _modelsDir.exists()) await _modelsDir.delete(recursive: true);
    await _modelsDir.create(recursive: true);
    _picker.next = null;
  });

  test('a cancelled pick imports nothing', () async {
    expect(await const ModelImporter().pickAndImport(), isNull);
  });

  test('a file with no readable path is reported, not ignored', () async {
    _picker.next = _PickedFile(
      'model.gguf',
      Uri.parse('content://media/model.gguf'),
    );
    expect(const ModelImporter().pickAndImport(), throwsA(isA<StateError>()));
  });

  test('rejects a file that is not a .gguf', () async {
    final file = await _fileAt('${_support.path}/picker/notes.txt');
    _picker.next = _PickedFile('notes.txt', file.uri);
    expect(
      const ModelImporter().pickAndImport(),
      throwsA(isA<FormatException>()),
    );
  });

  test('moves the picker\'s cache copy into the models folder', () async {
    final file = await _fileAt('${_support.path}/picker/Tiny-Model.gguf');
    _picker.next = _PickedFile('Tiny-Model.gguf', file.uri);

    final model = await const ModelImporter().pickAndImport();

    expect(model?.id, 'tiny-model');
    expect(await File('${_modelsDir.path}/Tiny-Model.gguf').exists(), isTrue);
    expect(await file.exists(), isFalse);
  });

  test('copies a file from outside the cache and leaves it in place', () async {
    final outside = await Directory.systemTemp.createTemp('thinai_user_');
    addTearDown(() => outside.delete(recursive: true));
    final file = await _fileAt('${outside.path}/Mine.gguf');
    _picker.next = _PickedFile('Mine.gguf', file.uri);

    final model = await const ModelImporter().pickAndImport();

    expect(model?.id, 'mine');
    expect(await File('${_modelsDir.path}/Mine.gguf').exists(), isTrue);
    expect(await file.exists(), isTrue);
  });

  test('refuses to overwrite a model with the same name', () async {
    await _fileAt('${_modelsDir.path}/Same.gguf');
    final file = await _fileAt('${_support.path}/picker/Same.gguf');
    _picker.next = _PickedFile('Same.gguf', file.uri);

    expect(const ModelImporter().pickAndImport(), throwsA(isA<StateError>()));
  });
}
