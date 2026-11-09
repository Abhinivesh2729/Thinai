/// Self-test the desktop build runs on itself in CI:
/// `thinai.exe --smoke --model=model.gguf --out=report.json`.
///
/// The founder tests desktop builds by installing them, with no debugger on
/// the machine, so CI is where native problems have to show up. This runs the
/// real release bundle (fllama.dll, its delay-loaded Vulkan, the bundled C++
/// runtime) through the paths a user hits first: probe the GPU, load a model,
/// stream a reply, serve the API. It writes what happened to `--out` and exits
/// non-zero on any failure.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../llm/gpu_support.dart';
import '../llm/llm_engine.dart';
import '../platform/platform_info.dart';
import '../server/api_server.dart';

/// Parsed `--smoke` arguments, or null when the app should start normally.
class SmokeArgs {
  const SmokeArgs({required this.modelPath, required this.outPath});

  final String modelPath;
  final String outPath;

  static SmokeArgs? parse(List<String> args) {
    if (!args.contains('--smoke')) return null;
    String? value(String name) {
      for (final a in args) {
        if (a.startsWith('--$name=')) return a.substring(name.length + 3);
      }
      return null;
    }

    final model = value('model');
    final out = value('out');
    if (model == null || out == null) {
      throw ArgumentError('--smoke needs --model=<gguf> and --out=<json>');
    }
    return SmokeArgs(modelPath: model, outPath: out);
  }
}

/// Runs every check, writes the report, and returns the process exit code.
Future<int> runSmokeTest(SmokeArgs args) async {
  final report = <String, Object?>{
    'os': Platform.operatingSystemVersion,
    'cores': Platform.numberOfProcessors,
  };
  final failures = <String>[];
  final total = Stopwatch()..start();

  Future<void> step(String name, Future<void> Function() body) async {
    final sw = Stopwatch()..start();
    try {
      await body().timeout(const Duration(minutes: 3));
      report['${name}_ms'] = sw.elapsedMilliseconds;
    } catch (e, st) {
      failures.add('$name: $e');
      report['${name}_error'] = '$e\n$st';
    }
  }

  // 1. GPU probe. On a runner with no Vulkan driver this must come back empty,
  //    not take the process down: that is the delay-load guard in fllama.
  await step('gpu_probe', () async {
    final devices = await probeGpuDevices();
    report['gpu_devices'] = [
      for (final d in devices) '${d.backend.name}: ${d.name}',
    ];
  });

  // 2. Load the model and stream a short reply on the CPU.
  await step('generate', () async {
    final buffer = StringBuffer();
    LlmToken? last;
    await for (final token in LlmEngine.instance.chat(
      [const ChatMessage(role: 'user', content: 'Say hello in five words.')],
      modelPath: args.modelPath,
      options: const GenerationOptions(maxTokens: 24, contextSize: 2048),
    )) {
      if (token.isError) throw StateError(token.full);
      buffer.write(token.delta);
      last = token;
    }
    final text = buffer.toString();
    if (text.trim().isEmpty) throw StateError('empty reply');
    report['reply'] = text;
    report['tokens'] = last?.stats.tokens;
    report['tok_per_s'] = last?.stats.tokensPerSecond;
    report['ttft_ms'] = last?.stats.timeToFirstToken?.inMilliseconds;
  });

  // 3. API server on the desktop port, loopback only.
  await step('server', () async {
    final server = ApiServer();
    await server.start(const ApiServerConfig(port: kDesktopServerPort));
    try {
      final client = HttpClient();
      try {
        for (final path in ['/', '/v1/models', '/api/tags']) {
          final req = await client.get('127.0.0.1', kDesktopServerPort, path);
          final res = await req.close();
          final body = await res.transform(utf8.decoder).join();
          report['server $path'] = res.statusCode;
          if (res.statusCode != 200) {
            throw StateError('$path -> ${res.statusCode}: $body');
          }
        }
      } finally {
        client.close(force: true);
      }
    } finally {
      await server.stop();
    }
  });

  report['total_ms'] = total.elapsedMilliseconds;
  report['ok'] = failures.isEmpty;
  report['failures'] = failures;
  await File(
    args.outPath,
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(report));
  return failures.isEmpty ? 0 : 1;
}
