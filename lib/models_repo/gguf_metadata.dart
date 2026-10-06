/// What a GGUF file says about the model inside it, read straight from the
/// header.
///
/// Only the handful of keys that decide how large a context the model can take
/// — its trained window, and the shape that sizes the KV cache — and read in
/// Dart rather than through the native side: loading a model to ask it these
/// questions costs seconds and hundreds of megabytes, while the answers sit in
/// the first few kilobytes of the file. Reading the header also works for a
/// model that was imported or downloaded by URL, which the catalogue knows
/// nothing about.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

/// The parts of a GGUF header that matter for sizing a context.
class GgufModelInfo {
  /// `general.architecture`, e.g. `llama`, `qwen3`, `gemma3`.
  final String? architecture;

  /// `general.name`, when the converter wrote one.
  final String? name;

  /// The context window the model was trained for (`{arch}.context_length`).
  final int? trainedContext;

  /// Transformer blocks (`{arch}.block_count`).
  final int? layers;

  /// Attention heads (`{arch}.attention.head_count`).
  final int? heads;

  /// Key/value heads (`{arch}.attention.head_count_kv`); fewer than [heads]
  /// under grouped-query attention, which is what makes long contexts cheap.
  final int? kvHeads;

  /// Hidden size (`{arch}.embedding_length`).
  final int? embeddingLength;

  /// Per-head key and value widths, when the model does not derive them from
  /// [embeddingLength] / [heads].
  final int? keyLength;
  final int? valueLength;

  const GgufModelInfo({
    this.architecture,
    this.name,
    this.trainedContext,
    this.layers,
    this.heads,
    this.kvHeads,
    this.embeddingLength,
    this.keyLength,
    this.valueLength,
  });

  /// Bytes of KV cache one token of context costs at llama.cpp's default f16
  /// cache, or null when the header does not carry enough to say.
  ///
  /// `layers × kvHeads × (keyWidth + valueWidth) × 2 bytes`. It overestimates
  /// for models that interleave sliding-window or recurrent layers, which only
  /// ever errs towards a smaller, safer cap.
  int? get kvBytesPerToken {
    final layers = this.layers;
    final heads = this.heads;
    if (layers == null || layers <= 0) return null;
    final kv = kvHeads ?? heads;
    if (kv == null || kv <= 0) return null;

    final derived = (embeddingLength != null && heads != null && heads > 0)
        ? embeddingLength! ~/ heads
        : null;
    final k = keyLength ?? derived;
    final v = valueLength ?? derived;
    if (k == null || v == null || k <= 0 || v <= 0) return null;
    return layers * kv * (k + v) * 2;
  }

  Map<String, dynamic> toJson() => {
        if (architecture != null) 'architecture': architecture,
        if (name != null) 'name': name,
        if (trainedContext != null) 'trainedContext': trainedContext,
        if (layers != null) 'layers': layers,
        if (heads != null) 'heads': heads,
        if (kvHeads != null) 'kvHeads': kvHeads,
        if (embeddingLength != null) 'embeddingLength': embeddingLength,
        if (keyLength != null) 'keyLength': keyLength,
        if (valueLength != null) 'valueLength': valueLength,
      };

  factory GgufModelInfo.fromJson(Map<String, dynamic> json) => GgufModelInfo(
        architecture: json['architecture'] as String?,
        name: json['name'] as String?,
        trainedContext: json['trainedContext'] as int?,
        layers: json['layers'] as int?,
        heads: json['heads'] as int?,
        kvHeads: json['kvHeads'] as int?,
        embeddingLength: json['embeddingLength'] as int?,
        keyLength: json['keyLength'] as int?,
        valueLength: json['valueLength'] as int?,
      );
}

/// Thrown when a file is not a GGUF this reader understands.
class GgufFormatException implements Exception {
  final String message;
  const GgufFormatException(this.message);
  @override
  String toString() => 'GgufFormatException: $message';
}

final Map<String, GgufModelInfo?> _cache = {};

/// Reads [path]'s header off the UI isolate, memoised per path, size and
/// modification time so a replaced file is read again.
///
/// Never throws: a file that cannot be read yields null, and callers fall back
/// to the catalogue's figure or to no cap at all.
Future<GgufModelInfo?> readGgufInfo(String path) async {
  try {
    final stat = await File(path).stat();
    final key = '$path|${stat.size}|${stat.modified.millisecondsSinceEpoch}';
    if (_cache.containsKey(key)) return _cache[key];
    final info = await Isolate.run(() => readGgufInfoSync(path));
    _cache[key] = info;
    return info;
  } on Object {
    return null;
  }
}

/// Synchronous header read. Exposed for tests and for callers already off
/// the UI isolate.
GgufModelInfo readGgufInfoSync(String path) {
  final file = File(path).openSync();
  try {
    return parseGgufHeader(_FileSource(file));
  } finally {
    file.closeSync();
  }
}

/// Parses header key/values from [source], stopping as soon as everything
/// worth having has been seen.
///
/// Converters write `general.*` and the architecture's own keys before the
/// tokenizer, whose vocabulary array is most of the header's bytes, so the
/// read usually ends inside the first few kilobytes. Arrays that are not
/// wanted are skipped by seeking rather than decoded.
GgufModelInfo parseGgufHeader(GgufByteSource source) {
  final r = _Reader(source);
  if (r.u32() != 0x46554747) {
    // "GGUF" little-endian.
    throw const GgufFormatException('not a GGUF file');
  }
  final version = r.u32();
  if (version < 2) {
    throw GgufFormatException('GGUF v$version is not supported');
  }
  r.u64(); // tensor count
  final kvCount = r.u64();

  String? arch;
  String? name;
  final ints = <String, int>{};

  bool complete() {
    if (arch == null) return false;
    const needed = [
      'context_length',
      'block_count',
      'attention.head_count',
      'attention.head_count_kv',
      'embedding_length',
    ];
    return needed.every((k) => ints.containsKey('$arch.$k'));
  }

  for (var i = 0; i < kvCount; i++) {
    final key = r.string();
    final type = r.u32();

    if (key == 'general.architecture' && type == _tString) {
      arch = r.string();
    } else if (key == 'general.name' && type == _tString) {
      name = r.string();
    } else if (type == _tArray) {
      final elementType = r.u32();
      final count = r.u64();
      if (_isInteger(elementType) && _wantsInt(key)) {
        // Per-layer head counts: the widest layer sizes the cache.
        var widest = 0;
        for (var j = 0; j < count; j++) {
          final v = _readInt(r, elementType);
          if (v > widest) widest = v;
        }
        ints[key] = widest;
      } else {
        _skipArray(r, elementType, count);
      }
    } else if (_isInteger(type) && _wantsInt(key)) {
      ints[key] = _readInt(r, type);
    } else {
      _skipValue(r, type);
    }

    // Keys before the architecture is known can't be checked yet, so only
    // stop once it is.
    if (complete() && ints.containsKey('$arch.attention.key_length')) break;
    if (complete() && key.startsWith('tokenizer.')) break;
  }

  int? get(String suffix) => arch == null ? null : ints['$arch.$suffix'];

  return GgufModelInfo(
    architecture: arch,
    name: name,
    trainedContext: get('context_length'),
    layers: get('block_count'),
    heads: get('attention.head_count'),
    kvHeads: get('attention.head_count_kv'),
    embeddingLength: get('embedding_length'),
    keyLength: get('attention.key_length'),
    valueLength: get('attention.value_length'),
  );
}

bool _wantsInt(String key) =>
    key.endsWith('.context_length') ||
    key.endsWith('.block_count') ||
    key.endsWith('.attention.head_count') ||
    key.endsWith('.attention.head_count_kv') ||
    key.endsWith('.embedding_length') ||
    key.endsWith('.attention.key_length') ||
    key.endsWith('.attention.value_length');

// GGUF value types.
const _tU8 = 0, _tI8 = 1, _tU16 = 2, _tI16 = 3, _tU32 = 4, _tI32 = 5;
const _tF32 = 6, _tBool = 7, _tString = 8, _tArray = 9;
const _tU64 = 10, _tI64 = 11, _tF64 = 12;

bool _isInteger(int type) =>
    type == _tU8 ||
    type == _tI8 ||
    type == _tU16 ||
    type == _tI16 ||
    type == _tU32 ||
    type == _tI32 ||
    type == _tU64 ||
    type == _tI64;

int _fixedSize(int type) => switch (type) {
      _tU8 || _tI8 || _tBool => 1,
      _tU16 || _tI16 => 2,
      _tU32 || _tI32 || _tF32 => 4,
      _tU64 || _tI64 || _tF64 => 8,
      _ => -1,
    };

int _readInt(_Reader r, int type) => switch (type) {
      _tU8 => r.bytes(1).getUint8(0),
      _tI8 => r.bytes(1).getInt8(0),
      _tU16 => r.bytes(2).getUint16(0, Endian.little),
      _tI16 => r.bytes(2).getInt16(0, Endian.little),
      _tU32 => r.u32(),
      _tI32 => r.bytes(4).getInt32(0, Endian.little),
      _tU64 => r.u64(),
      _tI64 => r.bytes(8).getInt64(0, Endian.little),
      _ => throw GgufFormatException('type $type is not an integer'),
    };

void _skipValue(_Reader r, int type) {
  if (type == _tString) {
    r.skip(r.u64());
  } else if (type == _tArray) {
    final elementType = r.u32();
    _skipArray(r, elementType, r.u64());
  } else {
    final size = _fixedSize(type);
    if (size < 0) throw GgufFormatException('unknown value type $type');
    r.skip(size);
  }
}

void _skipArray(_Reader r, int elementType, int count) {
  final size = _fixedSize(elementType);
  if (size > 0) {
    r.skip(size * count);
    return;
  }
  for (var i = 0; i < count; i++) {
    _skipValue(r, elementType);
  }
}

/// Where header bytes come from: a file on the phone, or a buffer in tests.
abstract class GgufByteSource {
  /// Reads exactly [length] bytes from [offset], or fewer at end of input.
  Uint8List read(int offset, int length);
}

/// A [GgufByteSource] over bytes already in memory.
class GgufBytes implements GgufByteSource {
  final Uint8List bytes;
  const GgufBytes(this.bytes);

  @override
  Uint8List read(int offset, int length) {
    if (offset >= bytes.length) return Uint8List(0);
    final end = offset + length > bytes.length ? bytes.length : offset + length;
    return Uint8List.sublistView(bytes, offset, end);
  }
}

class _FileSource implements GgufByteSource {
  final RandomAccessFile file;
  _FileSource(this.file);

  @override
  Uint8List read(int offset, int length) {
    file.setPositionSync(offset);
    return file.readSync(length);
  }
}

/// Little-endian cursor with a read-ahead buffer, so the thousands of short
/// reads a header takes do not each become a syscall.
class _Reader {
  final GgufByteSource source;
  _Reader(this.source);

  static const _chunk = 1 << 16;
  static const _maxString = 1 << 24;

  var _pos = 0;
  var _bufStart = 0;
  var _buf = Uint8List(0);

  ByteData bytes(int n) {
    if (_pos < _bufStart || _pos + n > _bufStart + _buf.length) {
      _bufStart = _pos;
      _buf = source.read(_pos, n > _chunk ? n : _chunk);
      if (_buf.length < n) {
        throw const GgufFormatException('unexpected end of file');
      }
    }
    final view = ByteData.sublistView(
      _buf,
      _pos - _bufStart,
      _pos - _bufStart + n,
    );
    _pos += n;
    return view;
  }

  int u32() => bytes(4).getUint32(0, Endian.little);
  int u64() => bytes(8).getUint64(0, Endian.little);

  void skip(int n) {
    if (n < 0) throw const GgufFormatException('negative length');
    _pos += n;
  }

  String string() {
    final length = u64();
    if (length > _maxString) {
      throw GgufFormatException('string of $length bytes');
    }
    if (length == 0) return '';
    final view = bytes(length);
    return utf8.decode(
      Uint8List.sublistView(view),
      allowMalformed: true,
    );
  }
}
