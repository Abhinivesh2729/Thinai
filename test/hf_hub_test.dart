import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/models_repo/hf_hub.dart';
import 'package:local_llm/ui/pages/models_page.dart';
import 'package:local_llm/state/providers.dart';

/// Stands in for huggingface.co. Each request is recorded so a test can say
/// what was (and was not) asked.
class _FakeHub implements HttpClientAdapter {
  _FakeHub(this.handle);

  final ResponseBody Function(RequestOptions options) handle;
  final requested = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requested.add(options);
    return handle(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, {int status = 200, Map<String, String>? h}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        for (final e in (h ?? const {}).entries) e.key: [e.value],
      },
    );

ResponseBody _text(String body) => ResponseBody.fromString(
  body,
  200,
  headers: {
    Headers.contentTypeHeader: ['text/plain'],
  },
);

const _searchReply = [
  {
    'id': 'unsloth/Qwen3-1.7B-GGUF',
    'gated': false,
    'private': false,
    'downloads': 1200000,
    'likes': 340,
    'lastModified': '2026-08-20T12:04:25.000Z',
    'pipeline_tag': 'text-generation',
  },
  {'id': 'meta/Llama-Gated-GGUF', 'gated': 'manual', 'downloads': 9},
  {'id': 'someone/private-GGUF', 'private': true},
  {'id': 'bartowski/gemma-3-1b-it-GGUF', 'downloads': 50},
];

final _detailReply = {
  'id': 'unsloth/Qwen3-1.7B-GGUF',
  'sha': 'abc123',
  'downloads': 1200000,
  'likes': 340,
  'gated': false,
  'cardData': {'license': 'apache-2.0'},
  'gguf': {
    'total': 1720000000,
    'architecture': 'qwen3',
    'context_length': 40960,
  },
  'siblings': [
    {'rfilename': '.gitattributes', 'size': 10},
    {'rfilename': 'README.md', 'size': 2000},
    {'rfilename': 'Qwen3-1.7B-Q8_0.gguf', 'size': 1830000000},
    {'rfilename': 'Qwen3-1.7B-Q4_K_M.gguf', 'size': 1110000000},
    {
      'rfilename': 'BF16/Qwen3-1.7B-BF16-00001-of-00002.gguf',
      'size': 2000000000,
    },
    {'rfilename': 'mmproj-F16.gguf', 'size': 800000000},
    {'rfilename': 'imatrix_unsloth.gguf', 'size': 4000000},
    {
      'rfilename': 'UD/Qwen3-1.7B-UD-IQ2_XXS.gguf',
      'lfs': {'size': 600000000},
    },
  ],
};

const _readme = '''---
license: apache-2.0
---

# Qwen3 1.7B GGUF

<div><img src="x.png"></div>

![banner](https://x/y.png)

Qwen3 is the latest generation of **Qwen** models, with [thinking](https://q.ai/think) and non-thinking modes in one model.

## Usage
''';

HfHub _hubWith(_FakeHub fake) => HfHub(dio: Dio()..httpClientAdapter = fake);

void main() {
  group('search', () {
    test(
      'asks for GGUF repos by downloads and drops gated and private ones',
      () async {
        final fake = _FakeHub((_) => _json(_searchReply));
        final results = await _hubWith(fake).search('  qwen ');

        expect(results.map((r) => r.id), [
          'unsloth/Qwen3-1.7B-GGUF',
          'bartowski/gemma-3-1b-it-GGUF',
        ]);
        final q = fake.requested.single.uri.queryParametersAll;
        expect(q['search'], ['qwen']);
        expect(q['filter'], ['gguf']);
        expect(q['sort'], ['downloads']);

        final first = results.first;
        expect(first.author, 'unsloth');
        expect(first.name, 'Qwen3-1.7B-GGUF');
        expect(first.downloads, 1200000);
        expect(first.lastModified, DateTime.utc(2026, 8, 20, 12, 4, 25));
      },
    );

    test('an empty query never goes online', () async {
      final fake = _FakeHub((_) => _json(_searchReply));
      expect(await _hubWith(fake).search('   '), isEmpty);
      expect(fake.requested, isEmpty);
    });

    test('rate limiting says how long to wait', () async {
      final fake = _FakeHub(
        (_) => _json(
          {'error': 'rate limited'},
          status: 429,
          h: {'ratelimit': '"api";r=0;t=157'},
        ),
      );
      await expectLater(
        _hubWith(fake).search('qwen'),
        throwsA(
          isA<HfHubException>().having(
            (e) => e.message,
            'message',
            'Too many searches for now. Try again in 3 minutes.',
          ),
        ),
      );
    });

    test('offline is reported as offline', () async {
      final fake = _FakeHub(
        (o) => throw DioException.connectionError(
          requestOptions: o,
          reason: 'Failed host lookup',
        ),
      );
      await expectLater(
        _hubWith(fake).search('qwen'),
        throwsA(
          isA<HfHubException>().having(
            (e) => e.message,
            'message',
            contains('No internet connection'),
          ),
        ),
      );
    });
  });

  group('detail', () {
    test('lists loadable files smallest first and counts the rest', () async {
      final fake = _FakeHub(
        (o) => o.uri.path.endsWith('README.md')
            ? _text(_readme)
            : _json(_detailReply),
      );
      final detail = await _hubWith(fake).detail('unsloth/Qwen3-1.7B-GGUF');

      expect(detail.files.map((f) => f.path), [
        'UD/Qwen3-1.7B-UD-IQ2_XXS.gguf',
        'Qwen3-1.7B-Q4_K_M.gguf',
        'Qwen3-1.7B-Q8_0.gguf',
      ]);
      // Split shard, image encoder and imatrix.
      expect(detail.skippedFiles, 3);
      expect(detail.license, 'apache-2.0');
      expect(detail.contextLength, 40960);
      expect(detail.parametersLabel, '1.7B');
      expect(detail.sha, 'abc123');
      expect(
        detail.description,
        'Qwen3 is the latest generation of Qwen models, with thinking and '
        'non-thinking modes in one model.',
      );
      // The README is read at the listed commit, and only its start.
      final readme = fake.requested.last;
      expect(
        readme.uri.path,
        '/unsloth/Qwen3-1.7B-GGUF/resolve/abc123/README.md',
      );
      expect(readme.headers['range'], 'bytes=0-16383');
    });

    test('a missing README still shows the files', () async {
      final fake = _FakeHub(
        (o) => o.uri.path.endsWith('README.md')
            ? _json({'error': 'nope'}, status: 404)
            : _json(_detailReply),
      );
      final detail = await _hubWith(fake).detail('unsloth/Qwen3-1.7B-GGUF');
      expect(detail.description, isNull);
      expect(detail.files, hasLength(3));
    });

    test('a file becomes a catalog entry pinned to the commit', () {
      final detail = HfRepoDetail.fromJson(_detailReply);
      final file = detail.files.firstWhere((f) => f.quant == 'Q4_K_M');
      final model = detail.toCatalogModel(file);

      expect(
        model.url,
        'https://huggingface.co/unsloth/Qwen3-1.7B-GGUF/resolve/abc123/'
        'Qwen3-1.7B-Q4_K_M.gguf',
      );
      expect(model.id, fileModelId('Qwen3-1.7B-Q4_K_M.gguf'));
      expect(model.filename, 'Qwen3-1.7B-Q4_K_M.gguf');
      expect(model.servedId, 'qwen3-1.7b-q4_k_m');
      expect(model.approxBytes, 1110000000);
      expect(model.parameters, '1.7B');
      expect(model.contextTokens, 40960);
      expect(model.displayName, 'Qwen3-1.7B-GGUF Q4_K_M');
    });

    test('files in a folder keep the folder in the URL only', () {
      final detail = HfRepoDetail.fromJson(_detailReply);
      final file = detail.files.firstWhere((f) => f.path.startsWith('UD/'));
      final model = detail.toCatalogModel(file);
      expect(
        model.url,
        endsWith('/resolve/abc123/UD/Qwen3-1.7B-UD-IQ2_XXS.gguf'),
      );
      expect(model.filename, 'Qwen3-1.7B-UD-IQ2_XXS.gguf');
    });
  });

  group('file names', () {
    test('reads the quantisation', () {
      expect(quantFromFilename('Qwen3-1.7B-Q4_K_M.gguf'), 'Q4_K_M');
      expect(quantFromFilename('model.q8_0.gguf'), 'Q8_0');
      expect(quantFromFilename('Qwen3-1.7B-UD-IQ2_XXS.gguf'), 'UD-IQ2_XXS');
      expect(quantFromFilename('gemma-3-1b-it-BF16.gguf'), 'BF16');
      expect(quantFromFilename('gpt-oss-20b-MXFP4.gguf'), 'MXFP4');
      expect(quantFromFilename('Llama-3.2-1B-Instruct-Q4_0.gguf'), 'Q4_0');
      expect(quantFromFilename('tiny.gguf'), isNull);
    });

    test('only offers files that load on their own', () {
      expect(isLoadableGguf('Qwen3-1.7B-Q4_K_M.gguf'), isTrue);
      expect(isLoadableGguf('x-Q4_K_M-00001-of-00003.gguf'), isFalse);
      expect(isLoadableGguf('mmproj-F16.gguf'), isFalse);
      expect(isLoadableGguf('mtp-Qwen3-27B-Q4_0.gguf'), isFalse);
      expect(isLoadableGguf('imatrix_unsloth.gguf'), isFalse);
      expect(isLoadableGguf('README.md'), isFalse);
    });
  });

  group('describeFromReadme', () {
    test('skips headings, HTML, images and short lines', () {
      expect(
        describeFromReadme(
          '# Title\n\nShort.\n\n<p>html</p>\n\n'
          'A proper paragraph that explains what this model is for.',
        ),
        'A proper paragraph that explains what this model is for.',
      );
    });

    test('cuts long paragraphs at a word', () {
      final long = List.filled(100, 'word').join(' ');
      final text = describeFromReadme(long, maxLength: 50)!;
      expect(text.length, lessThanOrEqualTo(53));
      expect(text, endsWith('...'));
    });

    test('nothing readable is null', () {
      expect(describeFromReadme('---\na: b\n---\n# Only a title\n'), isNull);
    });
  });

  group('retryAfterSeconds', () {
    test('prefers Retry-After, then the RateLimit window', () {
      expect(
        retryAfterSeconds(
          Headers.fromMap({
            'retry-after': ['30'],
          }),
        ),
        30,
      );
      expect(
        retryAfterSeconds(
          Headers.fromMap({
            'ratelimit': ['"api";r=0;t=57'],
          }),
        ),
        57,
      );
      expect(retryAfterSeconds(Headers.fromMap({})), isNull);
    });
  });

  group('HfSearchPage', () {
    Widget app(_FakeHub fake, {String query = ''}) => ProviderScope(
      overrides: [hfHubProvider.overrideWithValue(_hubWith(fake))],
      child: MaterialApp(home: HfSearchPage(initialQuery: query)),
    );

    testWidgets('says it uses the internet before anything is searched', (
      tester,
    ) async {
      final fake = _FakeHub((_) => _json(_searchReply));
      await tester.pumpWidget(app(fake));

      expect(find.textContaining('Search uses the internet'), findsOneWidget);
      expect(find.text('Find any GGUF model'), findsOneWidget);
      expect(fake.requested, isEmpty);
    });

    testWidgets('searches the query it was opened with', (tester) async {
      final fake = _FakeHub((_) => _json(_searchReply));
      await tester.pumpWidget(app(fake, query: 'qwen'));
      await tester.pumpAndSettle();

      expect(find.text('Results (2)'), findsOneWidget);
      expect(find.text('Qwen3-1.7B-GGUF'), findsOneWidget);
      expect(find.text('gemma-3-1b-it-GGUF'), findsOneWidget);
      expect(find.text('Llama-Gated-GGUF'), findsNothing);
    });

    testWidgets('waits for typing to stop before searching', (tester) async {
      final fake = _FakeHub((_) => _json(_searchReply));
      await tester.pumpWidget(app(fake));

      await tester.enterText(find.byType(TextField), 'q');
      await tester.enterText(find.byType(TextField), 'qw');
      await tester.enterText(find.byType(TextField), 'qwe');
      await tester.pump(const Duration(milliseconds: 100));
      expect(fake.requested, isEmpty);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(fake.requested, hasLength(1));
      expect(fake.requested.single.uri.queryParameters['search'], 'qwe');
    });

    testWidgets('a failed search offers to try again', (tester) async {
      var fail = true;
      final fake = _FakeHub((o) {
        if (fail) {
          throw DioException.connectionError(requestOptions: o, reason: 'x');
        }
        return _json(_searchReply);
      });
      await tester.pumpWidget(app(fake, query: 'qwen'));
      await tester.pumpAndSettle();

      expect(find.text('Search did not work'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Results (2)'), findsOneWidget);
    });
  });
}
