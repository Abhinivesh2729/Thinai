import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:local_llm/server/quick_tunnel.dart';

/// Answers the trycloudflare API with a fixed tunnel.
class _FakeApi implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode({
      'result': {
        'hostname': 'calm-river.trycloudflare.com',
        'id': 'tid',
        'account_tag': 'acct',
        'secret': 'c2VjcmV0',
      },
    }),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

/// A cloudflared stand-in that prints [lines] to stderr.
class _FakeProcess implements Process {
  _FakeProcess(List<String> lines, {bool exits = false}) {
    _stderr = Stream.fromIterable(lines.map((l) => utf8.encode('$l\n')));
    if (exits) _exit.complete(1);
  }

  late final Stream<List<int>> _stderr;
  final _exit = Completer<int>();
  bool killed = false;

  @override
  Stream<List<int>> get stderr => _stderr;
  @override
  Stream<List<int>> get stdout => const Stream.empty();
  @override
  Future<int> get exitCode => _exit.future;
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killed = true;
    if (!_exit.isCompleted) _exit.complete(-15);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('runToken encodes account, tunnel id and secret', () {
    final token = runToken({
      'account_tag': 'acct',
      'id': 'tid',
      'secret': 'c2VjcmV0',
    });
    expect(jsonDecode(utf8.decode(base64Decode(token))), {
      'a': 'acct',
      't': 'tid',
      's': 'c2VjcmV0',
    });
  });

  group('QuickTunnel', () {
    late List<String> args;

    QuickTunnel tunnel(_FakeProcess process) => QuickTunnel(
      dio: Dio()..httpClientAdapter = _FakeApi(),
      binaryPath: () async => '/lib/libcloudflared.so',
      lookup: (host) async => [
        InternetAddress(host.startsWith('region1') ? '1.1.1.1' : '2.2.2.2'),
      ],
      startProcess: (exe, a) async {
        args = a;
        return process;
      },
    );

    test('returns the public URL once a connection registers', () async {
      final t = tunnel(
        _FakeProcess([
          'INF Starting tunnel',
          'ERR Failed to fetch features', // DNS noise on Android; harmless
          'INF Registered tunnel connection connIndex=0',
        ]),
      );
      expect(await t.start(11434), 'https://calm-river.trycloudflare.com');
      expect(t.url, 'https://calm-river.trycloudflare.com');
      expect(args, containsAllInOrder(['--edge', '1.1.1.1:7844']));
      expect(args, containsAllInOrder(['--edge', '2.2.2.2:7844']));
      expect(args, containsAllInOrder(['--url', 'http://127.0.0.1:11434']));
    });

    test('stop kills cloudflared and clears the URL', () async {
      final process = _FakeProcess(['INF Registered tunnel connection']);
      final t = tunnel(process);
      await t.start(11434);
      await t.stop();
      expect(process.killed, isTrue);
      expect(t.url, isNull);
    });

    test('fails with the last error when cloudflared exits early', () async {
      final t = tunnel(
        _FakeProcess([
          '2026 ERR Unauthorized: Failed to get tunnel',
        ], exits: true),
      );
      await expectLater(
        t.start(11434),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Unauthorized'),
          ),
        ),
      );
      expect(t.url, isNull);
    });

    test('times out and kills cloudflared when nothing registers', () async {
      final process = _FakeProcess(['INF Starting tunnel']);
      final t = tunnel(process);
      await expectLater(
        t.start(11434, timeout: const Duration(milliseconds: 50)),
        throwsA(isA<TimeoutException>()),
      );
      expect(process.killed, isTrue);
    });
  });
}
