import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_llm/server/api_server.dart';
import 'package:local_llm/server/quick_tunnel.dart';
import 'package:local_llm/state/providers.dart';

/// Opens instantly on a fixed URL; [drop] plays cloudflared dying.
class _FakeTunnel extends QuickTunnel {
  @override
  Future<String> start(int port, {Duration timeout = Duration.zero}) async =>
      'https://calm-river.trycloudflare.com';

  @override
  Future<void> stop() async {}

  void drop() => onExit?.call();
}

void main() {
  test('a tunnel that dies on its own switches off with an error', () async {
    SharedPreferences.setMockInitialValues({});
    final server = ApiServer();
    final tunnel = _FakeTunnel();
    final c = ServerController(
      server,
      tokens: () async => {'a'},
      tunnel: tunnel,
    );
    addTearDown(server.stop);

    await c.start(port: 0);
    await c.startTunnel();
    expect(c.state.publicUrl, isNotNull);

    tunnel.drop();
    expect(c.state.publicUrl, isNull);
    expect(c.state.error, ServerController.tunnelDroppedError);
    expect(c.state.running, isTrue);
    // Tunnel auth is reset along with the URL.
    final forwarded = Request(
      'GET',
      Uri.parse('http://localhost/'),
      headers: {'cf-connecting-ip': '203.0.113.7'},
    );
    expect(server.authRequired(forwarded), isFalse);
  });
}
