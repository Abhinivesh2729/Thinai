import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

/// A free Cloudflare quick tunnel (random *.trycloudflare.com URL, no
/// account) from the internet to the local API, run by the bundled
/// open-source `cloudflared`.
///
/// cloudflared is a static Go binary, and Go's resolver finds no
/// /etc/resolv.conf on Android, so every lookup it makes fails. This class
/// does both lookups cloudflared needs in Dart instead: it requests the
/// tunnel from the trycloudflare API itself, and resolves the edge servers
/// and passes their IPs with --edge.
class QuickTunnel {
  QuickTunnel({
    Dio? dio,
    Future<String> Function()? binaryPath,
    Future<List<InternetAddress>> Function(String host)? lookup,
    Future<Process> Function(
      String exe,
      List<String> args, {
      Map<String, String>? environment,
    })?
    startProcess,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 10),
             ),
           ),
       _binaryPath = binaryPath ?? _bundledBinary,
       _lookup = lookup ?? _lookupIpv4,
       _startProcess = startProcess ?? Process.start;

  final Dio _dio;
  final Future<String> Function() _binaryPath;
  final Future<List<InternetAddress>> Function(String host) _lookup;
  final Future<Process> Function(
    String exe,
    List<String> args, {
    Map<String, String>? environment,
  })
  _startProcess;

  Process? _process;
  String? _url;

  /// Called when an open tunnel dies on its own (e.g. the network changed),
  /// not when [stop] closes it.
  void Function()? onExit;

  /// The public https URL while the tunnel is up.
  String? get url => _url;

  /// Opens a tunnel to `http://127.0.0.1:[port]` and returns its public URL
  /// once cloudflared has registered with the edge.
  Future<String> start(
    int port, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    await stop();

    final res = await _dio.post<Map<String, dynamic>>(
      'https://api.trycloudflare.com/tunnel',
      options: Options(headers: {'User-Agent': 'cloudflared/thinai'}),
    );
    final result = res.data!['result'] as Map<String, dynamic>;
    final hostname = result['hostname'] as String;

    final edges = <String>[];
    for (final host in _edgeHosts) {
      final ips = await _lookup(host);
      if (ips.isNotEmpty) edges.add('${ips.first.address}:7844');
    }
    if (edges.isEmpty) {
      throw StateError('Could not resolve the Cloudflare tunnel edge.');
    }

    // The token goes in the environment, not argv, so it stays out of `ps`.
    final process = await _startProcess(
      await _binaryPath(),
      [
        'tunnel',
        '--no-autoupdate',
        for (final e in edges) ...['--edge', e],
        '--protocol',
        'http2',
        'run',
        '--url',
        'http://127.0.0.1:$port',
      ],
      environment: {'TUNNEL_TOKEN': runToken(result)},
    );
    _process = process;
    process.stdout.drain<void>();

    final ready = Completer<void>();
    String? lastError;
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (line.contains('Registered tunnel connection')) {
            if (!ready.isCompleted) ready.complete();
          } else if (line.contains(' ERR ')) {
            lastError = line;
          }
        });
    process.exitCode.then((code) {
      if (_process == process) {
        _process = null;
        _url = null;
        if (ready.isCompleted) onExit?.call();
      }
      if (!ready.isCompleted) {
        ready.completeError(
          StateError('cloudflared exited ($code): ${lastError ?? ''}'),
        );
      }
    });

    try {
      await ready.future.timeout(timeout);
    } catch (_) {
      await stop();
      rethrow;
    }
    return _url = 'https://$hostname';
  }

  /// Closes the tunnel; its URL stops working at once.
  Future<void> stop() async {
    final process = _process;
    _process = null;
    _url = null;
    process?.kill();
  }

  /// Stops the tunnel and opens a new one on a fresh random URL.
  Future<String> rotate(int port) => start(port);
}

const _edgeHosts = ['region1.v2.argotunnel.com', 'region2.v2.argotunnel.com'];

/// The token `cloudflared tunnel run` takes: base64 JSON of the account tag,
/// tunnel id and secret the trycloudflare API hands out.
String runToken(Map<String, dynamic> result) => base64Encode(
  utf8.encode(
    jsonEncode({
      'a': result['account_tag'],
      't': result['id'],
      's': result['secret'],
    }),
  ),
);

Future<List<InternetAddress>> _lookupIpv4(String host) =>
    InternetAddress.lookup(host, type: InternetAddressType.IPv4);

const _native = MethodChannel('thinai/native');

/// cloudflared ships as lib/arm64-v8a/libcloudflared.so: Android only lets an
/// app execute files from its native library directory.
Future<String> _bundledBinary() async {
  final dir = await _native.invokeMethod<String>('nativeLibraryDir');
  return '$dir/libcloudflared.so';
}
