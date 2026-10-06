import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/web/web_search.dart';

/// Stands in for the network, so the fallback chain and the failure messages
/// can be tested without one. Every request is recorded, which is how "the
/// second endpoint was never asked" becomes something a test can say.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handle);

  final Future<ResponseBody> Function(RequestOptions options) handle;
  final requested = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requested.add(options.uri.toString());
    return handle(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _html(String body, {int status = 200}) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.textPlainContentType],
  },
);

/// A results page in the Lite surface's shape.
String _page(List<(String, String, String)> results) {
  final buffer = StringBuffer('<table>');
  for (final (title, url, snippet) in results) {
    buffer
      ..write("<tr><td><a href='$url' class='result-link'>$title</a></td></tr>")
      ..write("<tr><td class='result-snippet'>$snippet</td></tr>");
  }
  return (buffer..write('</table>')).toString();
}

WebSearch _searchWith(_FakeAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return WebSearch(dio: dio);
}

bool _isSearchEndpoint(RequestOptions options) =>
    WebSearch.endpoints.any((e) => options.uri.toString().startsWith(e.url));

/// The endpoints an adapter was actually asked, in order, without the query
/// strings the GET ones carry.
List<String> _asked(_FakeAdapter adapter) => [
  for (final url in adapter.requested)
    WebSearch.endpoints
        .firstWhere(
          (e) => url.startsWith(e.url),
          orElse: () => SearchEndpoint(url: url, parse: (_) => const []),
        )
        .url,
];

void main() {
  group('search', () {
    test('takes the first surface that answers, and stops there', () async {
      final adapter = _FakeAdapter((options) async {
        return _html(_page([
          ('Tamil Nadu news', 'https://thehindu.com/tamil', 'Rain warning.'),
        ]));
      });
      final results = await _searchWith(adapter).search(
        'news in tamil',
        readTopResult: false,
      );

      expect(results.results, hasLength(1));
      expect(results.results.single.url, 'https://thehindu.com/tamil');
      expect(results.query, 'news in tamil');
      expect(
        _asked(adapter),
        [WebSearch.endpoints.first.url],
        reason: 'the fallback is a fallback, not a second request every time',
      );
    });

    test('falls through to the other surface when one is challenged',
        () async {
      // What a bot check looks like: a 200, and a page with no results on it.
      final adapter = _FakeAdapter((options) async {
        if (options.uri.toString().startsWith(WebSearch.endpoints.first.url)) {
          return _html('<html><body>Please verify you are human</body></html>');
        }
        return _html(_page([
          ('Dinamalar', 'https://dinamalar.com/news', 'Tamil headlines.'),
        ]));
      });
      final results = await _searchWith(adapter).search(
        'tamil news',
        readTopResult: false,
      );

      expect(results.results.single.title, 'Dinamalar');
      expect(_asked(adapter), [
        WebSearch.endpoints[0].url,
        WebSearch.endpoints[1].url,
      ]);
    });

    test('an engine answering about something else counts as nothing',
        () async {
      // A real page, ranked on one word, about nothing that was asked. It
      // moves on to the next surface rather than answering from it.
      final adapter = _FakeAdapter((options) async => _html(_page([
        ('South Korean won - Wikipedia', 'https://en.wikipedia.org/wiki/won',
            'The won is the currency of South Korea.'),
      ])));
      final results = await _searchWith(adapter).search(
        'who won the india australia cricket match',
        readTopResult: false,
      );
      expect(results.isEmpty, isTrue);
      // Every engine was tried once. Bing reads this page as no results at
      // all (it is DuckDuckGo-shaped markup), and with nothing parsed there is
      // no ranking to fix by reordering the words.
      expect(_asked(adapter), hasLength(WebSearch.endpoints.length));
    });

    test('a search with genuinely nothing to show is not a failure', () async {
      // Empty results and a broken search need different words in front of the
      // user, so they are different outcomes here.
      final adapter = _FakeAdapter((options) async => _html(_page(const [])));
      final results = await _searchWith(adapter).search(
        'asdkjhasdkjh qwerty',
        readTopResult: false,
      );
      expect(results.isEmpty, isTrue);
      expect(
        _asked(adapter),
        [for (final e in WebSearch.endpoints) e.url],
        reason: 'every surface was tried before giving up',
      );
    });

    test('says what went wrong when it could not search at all', () async {
      final adapter = _FakeAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });
      await expectLater(
        _searchWith(adapter).search('news'),
        throwsA(isA<WebSearchException>().having(
          (e) => e.message,
          'message',
          contains('internet'),
        )),
      );
    });

    test('a refusal names the status, since that is the actionable part',
        () async {
      final adapter = _FakeAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: 429),
        );
      });
      await expectLater(
        _searchWith(adapter).search('news'),
        throwsA(isA<WebSearchException>().having(
          (e) => e.message,
          'message',
          contains('429'),
        )),
      );
    });

    test('refuses to search for nothing', () async {
      final adapter = _FakeAdapter((options) async => _html(''));
      await expectLater(
        _searchWith(adapter).search('   '),
        throwsA(isA<WebSearchException>()),
      );
      expect(adapter.requested, isEmpty, reason: 'nothing was worth sending');
    });

    test('a cancelled search stays cancelled', () async {
      final token = CancelToken();
      final adapter = _FakeAdapter((options) async {
        throw DioException.requestCancelled(
          requestOptions: options,
          reason: 'stopped',
        );
      });
      await expectLater(
        _searchWith(adapter).search('news', cancelToken: token),
        throwsA(isA<DioException>()),
        reason: 'stopping is the user\'s doing, not a search failure to report',
      );
    });
  });

  group('when the engines push back', () {
    test('a challenge everywhere is reported as blocked, not as no results',
        () async {
      // DuckDuckGo's bot check is a 202 with no results; Bing's is a captcha.
      final adapter = _FakeAdapter((options) async {
        if (options.uri.host.contains('bing.com')) {
          return _html('<html><body><div id="b_captcha">Solve the '
              'challenge</div></body></html>');
        }
        return _html('<html><body>anomaly</body></html>', status: 202);
      });
      final results = await _searchWith(adapter).search(
        'gold price in chennai',
        readTopResult: false,
      );
      expect(results.isEmpty, isTrue);
      expect(results.blocked, isTrue);
      expect(_asked(adapter), hasLength(WebSearch.endpoints.length));
    });

    test('one engine answering is enough to not be blocked', () async {
      final adapter = _FakeAdapter((options) async {
        if (options.uri.host.contains('duckduckgo.com')) {
          return _html('<html><body>anomaly</body></html>', status: 202);
        }
        return _html('<ol><li class="b_algo"><h2><a href="https://example.com/'
            'gold">Gold price in Chennai</a></h2><p>22K gold is ₹14,170 per '
            'gram in Chennai today.</p></li></ol>');
      });
      final results = await _searchWith(adapter).search(
        'gold price in chennai',
        readTopResult: false,
      );
      expect(results.results.single.url, 'https://example.com/gold');
      expect(results.blocked, isFalse);
    });

    test('an honest empty page is not mistaken for a block', () async {
      final adapter = _FakeAdapter((options) async => _html(_page(const [])));
      final results = await _searchWith(adapter).search(
        'asdkjhasdkjh qwerty',
        readTopResult: false,
      );
      expect(results.blocked, isFalse);
    });

    test('an engine that breaks in an unexpected way does not end the search',
        () async {
      // Anything other than a network error used to escape the loop and skip
      // every engine after it.
      final adapter = _FakeAdapter((options) async => _html(_page([
        ('Tamil Nadu news', 'https://thehindu.com/tamil', 'Rain warning.'),
      ])));
      final search = WebSearch(
        dio: Dio()..httpClientAdapter = adapter,
        endpoints: [
          SearchEndpoint(
            url: 'https://broken.example/search',
            parse: (_) => throw const FormatException('layout changed'),
          ),
          WebSearch.endpoints.first,
        ],
      );
      final results = await search.search('tamil news', readTopResult: false);
      expect(results.results.single.title, 'Tamil Nadu news');
    });

    test('only DuckDuckGo is told the request came from DuckDuckGo', () async {
      final referers = <String, Object?>{};
      final adapter = _FakeAdapter((options) async {
        referers[options.uri.host] = options.headers['Referer'];
        if (_isSearchEndpoint(options)) {
          return _html(options.uri.host.contains('bing.com')
              ? '<h2><a href="https://example.com/n">Nvidia CEO Jensen '
                  'Huang</a></h2><p>Jensen Huang is the founder and CEO of '
                  'Nvidia.</p>'
              : '<html><body>anomaly</body></html>');
        }
        return _html('<p>Jensen Huang co-founded Nvidia in 1993 and has led '
            'it as chief executive ever since.</p>');
      });
      await _searchWith(adapter).search('who is the CEO of Nvidia');
      expect(referers['lite.duckduckgo.com'], 'https://duckduckgo.com/');
      expect(referers['www.bing.com'], isNull);
      expect(referers['example.com'], isNull,
          reason: 'a third-party page is not told where the user searched');
    });

    test('Bing is asked in keywords, since a question derails it', () async {
      // Live, "who is the CEO of Nvidia" returned the Delhi Chief Electoral
      // Officer and "Nvidia CEO" returned Jensen Huang.
      final bingQueries = <String>[];
      final adapter = _FakeAdapter((options) async {
        if (options.uri.host.contains('bing.com')) {
          bingQueries.add(options.uri.queryParameters['q'] ?? '');
        }
        return _html('<html><body>anomaly</body></html>', status: 202);
      });
      await _searchWith(adapter).search(
        'who is the CEO of Nvidia?',
        readTopResult: false,
      );
      expect(bingQueries, ['CEO Nvidia']);
    });
  });

  group('engines that turned the app away', () {
    test('are left alone for a while, then asked again', () async {
      // Live, DuckDuckGo stopped accepting connections, and each question
      // waited out two ten-second timeouts before Bing was asked.
      var clock = DateTime(2026, 9, 13, 12);
      final adapter = _FakeAdapter((options) async {
        if (options.uri.host.contains('duckduckgo.com')) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
          );
        }
        return _html('<h2><a href="https://example.com/gold">Gold price in '
            'Chennai</a></h2><p>22K gold is ₹14,170 per gram in Chennai.</p>');
      });
      final search = WebSearch(
        dio: Dio()..httpClientAdapter = adapter,
        now: () => clock,
      );

      await search.search('gold price chennai', readTopResult: false);
      expect(adapter.requested, hasLength(3));

      adapter.requested.clear();
      await search.search('gold price chennai', readTopResult: false);
      expect(_asked(adapter), [WebSearch.endpoints.last.url],
          reason: 'the engines that timed out sit this one out');

      adapter.requested.clear();
      clock = clock.add(WebSearch.cooldown + const Duration(seconds: 1));
      await search.search('gold price chennai', readTopResult: false);
      expect(adapter.requested, hasLength(3), reason: 'and come back later');
    });

    test('are asked anyway when every engine is resting', () async {
      final adapter = _FakeAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: 429),
        );
      });
      final search = _searchWith(adapter);
      await expectLater(search.search('news'), throwsA(isA<WebSearchException>()));
      adapter.requested.clear();
      await expectLater(search.search('news'), throwsA(isA<WebSearchException>()));
      expect(adapter.requested, hasLength(WebSearch.endpoints.length));
    });

    test('no network at all does not put engines to rest', () async {
      final adapter = _FakeAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });
      final search = _searchWith(adapter);
      await expectLater(search.search('news'), throwsA(isA<WebSearchException>()));
      adapter.requested.clear();
      await expectLater(search.search('news'), throwsA(isA<WebSearchException>()));
      expect(adapter.requested, hasLength(WebSearch.endpoints.length));
    });
  });

  group('asking the keyword engine a second way', () {
    test('reorders the words when the first order ranked on the wrong one',
        () async {
      final bingQueries = <String>[];
      final adapter = _FakeAdapter((options) async {
        if (!options.uri.host.contains('bing.com')) {
          return _html('<html><body>anomaly</body></html>', status: 202);
        }
        final q = options.uri.queryParameters['q'] ?? '';
        bingQueries.add(q);
        return _html(q == 'CEO Nvidia'
            ? '<h2><a href="https://investopedia.example/ceo">Chief Executive '
                'Officer (CEO): Roles</a></h2><p>What a CEO does, and how the '
                'role differs from others.</p>'
            : '<h2><a href="https://nvidia.example/jensen">Jensen Huang - '
                'NVIDIA</a></h2><p>Jensen Huang is the founder and CEO of '
                'NVIDIA.</p>');
      });
      final results = await _searchWith(adapter).search(
        'who is the CEO of Nvidia',
        readTopResult: false,
      );
      expect(bingQueries, ['CEO Nvidia', 'Nvidia CEO']);
      expect(results.results.first.url, 'https://nvidia.example/jensen');
    });

    test('keeps the first answer when it already names the whole question',
        () async {
      final bingQueries = <String>[];
      final adapter = _FakeAdapter((options) async {
        if (!options.uri.host.contains('bing.com')) {
          return _html('<html><body>anomaly</body></html>', status: 202);
        }
        bingQueries.add(options.uri.queryParameters['q'] ?? '');
        return _html('<h2><a href="https://iplt20.example/">IPL match '
            'result</a></h2><p>Full scorecard of the IPL match.</p>');
      });
      await _searchWith(adapter).search(
        "who won yesterday's IPL match",
        readTopResult: false,
      );
      expect(bingQueries, ['IPL match yesterday']);
    });
  });

  group('reading the top result', () {
    test('the page behind the first hit comes back with the results',
        () async {
      final adapter = _FakeAdapter((options) async {
        if (_isSearchEndpoint(options)) {
          return _html(_page([
            ('Best models', 'https://benchlm.ai/anthropic', 'Ranked.'),
          ]));
        }
        return _html(
          '<html><body><p>Claude Fable 5.1 leads with a score of 83, ahead '
          'of Claude Opus 5 at 82.4.</p></body></html>',
        );
      });

      final results = await _searchWith(adapter).search('latest model');
      expect(results.leadText, contains('score of 83'));
      expect(adapter.requested.last, 'https://benchlm.ai/anthropic');

      // And it reaches the model, which is the whole point of fetching it.
      expect(
        webSearchPrompt(results, 'latest model'),
        contains('From [1] benchlm.ai:'),
      );
    });

    test('the page is read for the part that answers the question', () async {
      final adapter = _FakeAdapter((options) async {
        if (_isSearchEndpoint(options)) {
          return _html(_page([
            ('Android version history', 'https://android.example/versions',
                'Every Android version.'),
          ]));
        }
        return _html('<p>You are all set to receive the latest tips and '
            'offers.</p>'
            '<p>${'Sign up for the newsletter to hear about everything. ' * 40}</p>'
            '<p>Android 17 is the latest version, released in June 2026.</p>');
      });

      final results = await _searchWith(adapter).search(
        'latest android version',
      );
      expect(results.leadText, contains('Android 17 is the latest version'));
      expect(results.leadText, isNot(contains('newsletter')));
    });

    test('a page that will not load costs detail, not the answer', () async {
      final adapter = _FakeAdapter((options) async {
        if (_isSearchEndpoint(options)) {
          return _html(_page([
            ('Best models', 'https://benchlm.ai/anthropic', 'Ranked.'),
          ]));
        }
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        );
      });

      final results = await _searchWith(adapter).search('latest model');
      expect(results.results, hasLength(1), reason: 'the search still stands');
      expect(results.leadText, isEmpty);
    });
  });
}
