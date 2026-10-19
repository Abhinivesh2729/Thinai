/// Searches the Hugging Face Hub for GGUF models and describes their files.
///
/// The only part of the Models page that goes online on its own initiative,
/// so it does so only when the user searches or opens a result: no
/// prefetching, no background refresh, no account. Public repos only; gated
/// and private repos need a token, which is out of scope.
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show Color;

import 'catalog.dart';
import 'model_store.dart';

const _hubBase = 'https://huggingface.co';

/// One search result: a repo, not yet a file.
class HfRepo {
  final String id;
  final int downloads;
  final int likes;
  final DateTime? lastModified;
  final String? pipelineTag;

  const HfRepo({
    required this.id,
    this.downloads = 0,
    this.likes = 0,
    this.lastModified,
    this.pipelineTag,
  });

  String get author => id.contains('/') ? id.split('/').first : '';
  String get name => id.contains('/') ? id.substring(id.indexOf('/') + 1) : id;

  static HfRepo? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'] ?? json['modelId'];
    if (id is! String || id.isEmpty) return null;
    // Gated is `false` when open, otherwise "auto" or "manual". Either way it
    // needs a signed-in account to download.
    if (json['gated'] != null && json['gated'] != false) return null;
    if (json['private'] == true) return null;
    return HfRepo(
      id: id,
      downloads: _int(json['downloads']),
      likes: _int(json['likes']),
      lastModified: DateTime.tryParse('${json['lastModified'] ?? ''}'),
      pipelineTag: json['pipeline_tag'] as String?,
    );
  }
}

/// A single GGUF file in a repo that Thinai can download and load.
class HfFile {
  /// Path inside the repo, which may include a folder (`Q4/x.gguf`).
  final String path;
  final int size;

  const HfFile({required this.path, required this.size});

  /// The name it is stored under on the phone.
  String get filename => path.split('/').last;

  /// Quantisation read from the file name, e.g. `Q4_K_M`, or null.
  String? get quant => quantFromFilename(filename);
}

/// What the repo page shows: the card, and the files worth offering.
class HfRepoDetail {
  final String id;

  /// Commit the files were listed at. Downloads are pinned to it so a resume
  /// can never stitch together bytes from two different uploads.
  final String sha;
  final String? license;
  final int? contextLength;
  final int? parameterCount;
  final String? architecture;
  final String? description;
  final int downloads;
  final int likes;
  final bool gated;

  /// Loadable files, smallest first.
  final List<HfFile> files;

  /// Files left out because Thinai cannot load them on their own (split
  /// shards, image encoders, draft heads). Counted so the page can say so
  /// rather than look like the repo is missing files.
  final int skippedFiles;

  const HfRepoDetail({
    required this.id,
    required this.sha,
    required this.files,
    this.license,
    this.contextLength,
    this.parameterCount,
    this.architecture,
    this.description,
    this.downloads = 0,
    this.likes = 0,
    this.gated = false,
    this.skippedFiles = 0,
  });

  String get author => id.contains('/') ? id.split('/').first : '';
  String get name => id.contains('/') ? id.substring(id.indexOf('/') + 1) : id;

  /// Parameter count as a short label (`1.2B`, `270M`), or empty.
  String get parametersLabel {
    final n = parameterCount;
    if (n == null || n <= 0) return '';
    if (n >= 1000000000) return '${_short(n / 1e9)}B';
    return '${_short(n / 1e6)}M';
  }

  static HfRepoDetail fromJson(Map<String, dynamic> json, {String? readme}) {
    final card = json['cardData'];
    final gguf = json['gguf'];
    final siblings = json['siblings'];

    final files = <HfFile>[];
    var skipped = 0;
    if (siblings is List) {
      for (final s in siblings) {
        if (s is! Map) continue;
        final path = s['rfilename'];
        if (path is! String || !path.toLowerCase().endsWith('.gguf')) continue;
        final lfs = s['lfs'];
        final size = _int(s['size'] ?? (lfs is Map ? lfs['size'] : null));
        final file = HfFile(path: path, size: size);
        if (isLoadableGguf(file.filename) && size > 0) {
          files.add(file);
        } else {
          skipped++;
        }
      }
    }
    files.sort((a, b) => a.size.compareTo(b.size));

    String? license;
    if (card is Map && card['license'] is String) {
      license = card['license'] as String;
    }

    return HfRepoDetail(
      id: '${json['id'] ?? json['modelId'] ?? ''}',
      sha: '${json['sha'] ?? 'main'}',
      license: license,
      contextLength: gguf is Map ? _intOrNull(gguf['context_length']) : null,
      parameterCount: gguf is Map ? _intOrNull(gguf['total']) : null,
      architecture: gguf is Map ? gguf['architecture'] as String? : null,
      description: readme == null ? null : describeFromReadme(readme),
      downloads: _int(json['downloads']),
      likes: _int(json['likes']),
      gated: json['gated'] != null && json['gated'] != false,
      files: files,
      skippedFiles: skipped,
    );
  }

  /// [file] as a catalog entry, so the existing download flow, fit check and
  /// installed-model registration all apply to it unchanged.
  CatalogModel toCatalogModel(HfFile file) {
    final quant = file.quant;
    return CatalogModel(
      id: fileModelId(file.filename),
      displayName: quant == null ? name : '$name $quant',
      author: author,
      url: '$_hubBase/$id/resolve/$sha/${Uri.encodeFull(file.path)}',
      filename: file.filename,
      approxBytes: file.size,
      parameters: parametersLabel,
      contextTokens: contextLength ?? 4096,
      description: description ?? '',
      accent: const Color(0xFFFFB000),
      emoji: '',
    );
  }
}

/// Why a Hub request did not work, phrased for the person holding the phone.
class HfHubException implements Exception {
  final String message;
  const HfHubException(this.message);

  @override
  String toString() => message;
}

class HfHub {
  HfHub({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const searchLimit = 30;

  /// Public repos matching [query] that contain GGUF files, most downloaded
  /// first.
  Future<List<HfRepo>> search(String query, {CancelToken? cancelToken}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final data = await _get(
      '$_hubBase/api/models',
      query: {
        'search': q,
        'filter': 'gguf',
        'sort': 'downloads',
        'direction': '-1',
        'limit': '$searchLimit',
        'expand[]': [
          'downloads',
          'likes',
          'gated',
          'private',
          'pipeline_tag',
          'lastModified',
        ],
      },
      cancelToken: cancelToken,
    );
    if (data is! List) return const [];
    return [for (final item in data) ?HfRepo.fromJson(item)];
  }

  /// The repo's card and its loadable GGUF files.
  Future<HfRepoDetail> detail(String repoId, {CancelToken? cancelToken}) async {
    final data = await _get(
      '$_hubBase/api/models/$repoId',
      query: {'blobs': 'true'},
      cancelToken: cancelToken,
    );
    if (data is! Map<String, dynamic>) {
      throw const HfHubException('Hugging Face sent an unexpected reply');
    }
    final readme = await _readme(repoId, '${data['sha'] ?? 'main'}');
    return HfRepoDetail.fromJson(data, readme: readme);
  }

  /// The start of the model card, for its description. Optional: a repo with
  /// no README, or a slow one, still shows its files.
  Future<String?> _readme(String repoId, String sha) async {
    try {
      final response = await _dio.get<String>(
        '$_hubBase/$repoId/resolve/$sha/README.md',
        options: Options(
          responseType: ResponseType.plain,
          headers: {'range': 'bytes=0-16383'},
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      return response.data;
    } catch (_) {
      return null;
    }
  }

  Future<Object?> _get(
    String url, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        url,
        queryParameters: query,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw HfHubException(describeHubError(e));
    }
  }
}

/// Turns a failed Hub request into something worth showing a user.
String describeHubError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionError:
      return 'No internet connection. Searching Hugging Face needs one.';
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Hugging Face is taking too long to answer. Try again.';
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      if (status == 429) {
        final wait = retryAfterSeconds(e.response?.headers);
        return wait == null
            ? 'Too many searches for now. Try again in a minute.'
            : 'Too many searches for now. Try again in ${_waitLabel(wait)}.';
      }
      if (status == 401 || status == 403) {
        return 'This model needs a Hugging Face sign-in, which Thinai does not support yet.';
      }
      if (status == 404) return 'That model is no longer on Hugging Face.';
      return 'Hugging Face had a problem${status == null ? '' : ' ($status)'}. Try again later.';
    case DioExceptionType.cancel:
      return 'Cancelled';
    default:
      final text = '${e.error ?? e.message ?? ''}';
      if (text.contains('SocketException') ||
          text.contains('Failed host lookup')) {
        return 'No internet connection. Searching Hugging Face needs one.';
      }
      return 'Could not reach Hugging Face. Try again.';
  }
}

/// Seconds to wait, from `Retry-After` or Hugging Face's
/// `RateLimit: "api";r=0;t=57` header.
int? retryAfterSeconds(Headers? headers) {
  if (headers == null) return null;
  final retry = int.tryParse(headers.value('retry-after') ?? '');
  if (retry != null) return retry;
  final rate = headers.value('ratelimit');
  if (rate == null) return null;
  final match = RegExp(r'\bt=(\d+)').firstMatch(rate);
  return match == null ? null : int.parse(match.group(1)!);
}

String _waitLabel(int seconds) {
  if (seconds < 60) return '$seconds seconds';
  final minutes = (seconds / 60).ceil();
  return minutes == 1 ? 'a minute' : '$minutes minutes';
}

/// Catalog-style id for a model known only by its file, shared by Hub
/// downloads and resumed downloads so both refer to the same transfer.
String fileModelId(String filename) => 'file:${filename.toLowerCase()}';

/// True for a GGUF Thinai can load by itself. Split shards need their
/// siblings, image encoders and draft heads are not chat models, and imatrix
/// files are calibration data.
bool isLoadableGguf(String filename) {
  final name = filename.toLowerCase();
  if (!name.endsWith('.gguf')) return false;
  if (RegExp(r'-\d{5}-of-\d{5}\.gguf$').hasMatch(name)) return false;
  if (isProjectorFilename(name)) return false;
  if (name.startsWith('mtp-')) return false;
  if (name.contains('imatrix')) return false;
  return true;
}

final _quantPattern = RegExp(
  r'(?:^|[-_.])((?:UD-)?(?:I?Q\d(?:_[A-Z0-9]+)*|BF16|F16|F32|MXFP4(?:_MOE)?))(?=[-_.]|$)',
  caseSensitive: false,
);

/// The quantisation in a GGUF file name, upper-cased, or null.
String? quantFromFilename(String filename) {
  var name = filename;
  if (name.toLowerCase().endsWith('.gguf')) {
    name = name.substring(0, name.length - 5);
  }
  String? last;
  for (final m in _quantPattern.allMatches(name)) {
    last = m.group(1);
  }
  return last?.toUpperCase();
}

/// The first real paragraph of a model card: no front matter, headings,
/// HTML, images, tables or code. Links keep their text. Null when there is
/// nothing readable.
String? describeFromReadme(String readme, {int maxLength = 320}) {
  var text = readme.replaceAll('\r\n', '\n');
  if (text.startsWith('---')) {
    final end = text.indexOf('\n---', 3);
    if (end >= 0) text = text.substring(end + 4);
  }
  text = text.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
  text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '');

  for (final block in text.split(RegExp(r'\n\s*\n'))) {
    final lines = block
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) continue;
    final first = lines.first;
    if (first.startsWith('#') ||
        first.startsWith('<') ||
        first.startsWith('|') ||
        first.startsWith('>') ||
        first.startsWith('!') ||
        first.startsWith('[!') ||
        first.startsWith('- ') ||
        first.startsWith('* ')) {
      continue;
    }
    var para = lines.join(' ');
    para = para
        .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '')
        .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]*\)'), (m) => m[1]!)
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'[*_`]{1,3}'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (para.length < 40) continue;
    if (para.length > maxLength) {
      final cut = para.lastIndexOf(' ', maxLength);
      para = '${para.substring(0, cut > 0 ? cut : maxLength)}...';
    }
    return para;
  }
  return null;
}

int _int(Object? v) => v is int ? v : (v is num ? v.toInt() : 0);
int? _intOrNull(Object? v) => v is int ? v : (v is num ? v.toInt() : null);

String _short(double value) => value >= 10 || value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);
