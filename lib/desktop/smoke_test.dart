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

import 'package:thinai_tamil_evals/thinai_tamil_evals.dart' show kOptionGrammar;

import '../llm/generation_settings.dart';
import '../llm/gpu_support.dart';
import '../llm/llm_engine.dart';
import '../models_repo/model_store.dart';
import '../platform/platform_info.dart';
import '../server/api_server.dart';
import '../state/providers.dart';
import 'storage/sqlite_chat_store.dart';

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

  Future<void> write() => File(
    args.outPath,
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(report));

  Future<void> step(String name, Future<void> Function() body) async {
    // Written before and after each step: if native code takes the process
    // down, the report still says which step it was in.
    report['running'] = name;
    await write();
    final sw = Stopwatch()..start();
    try {
      await body().timeout(const Duration(minutes: 3));
      report['${name}_ms'] = sw.elapsedMilliseconds;
    } catch (e, st) {
      failures.add('$name: $e');
      report['${name}_error'] = '$e\n$st';
    }
    report.remove('running');
    await write();
  }

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

  // 1b. GPU probe, after the first request: probing initialises the backend,
  //     and running it first hid a crash in requests that came before any
  //     init (ggml's Windows clock). On a runner with no Vulkan driver this must come back empty,
  //    not take the process down: that is the delay-load guard in fllama.
  await step('gpu_probe', () async {
    final devices = await probeGpuDevices();
    report['gpu_devices'] = [
      for (final d in devices) '${d.backend.name}: ${d.name}',
    ];
  });

  // 2b. The Lab's speed benchmark, exactly as the page calls it: settings
  //     from the store (context fitted to free RAM), 128 tokens, and the
  //     listener leaving on the done token.
  final file = File(args.modelPath);
  final model = LocalModel(
    id: 'smoke',
    displayName: 'smoke',
    path: args.modelPath,
    sizeBytes: file.existsSync() ? file.lengthSync() : 0,
    modifiedAt: DateTime.now(),
  );
  await GenerationSettingsStore.instance.ensureLoaded();
  await step('benchmark', () async {
    final options = await GenerationSettingsStore.instance.optionsFor(
      model,
      requestedTemperature: 0.2,
      maxTokens: 128,
    );
    report['benchmark_ctx'] = options.contextSize;
    LlmToken? last;
    await for (final token in LlmEngine.instance.generate(
      'Explain how neural networks learn, in one paragraph.',
      modelPath: model.path,
      options: options,
    )) {
      if (token.isError) throw StateError(token.full);
      last = token;
      if (token.done) break;
    }
    report['benchmark_tokens'] = last?.stats.tokens;
    report['benchmark_tok_per_s'] = last?.stats.tokensPerSecond;
  });

  // 2b'. The same benchmark at the 8K window the Lab uses on a PC with free
  //      RAM (the CI run that crashed in the UI had ctx=8192 max=128).
  await step('benchmark_8k', () async {
    LlmToken? last;
    await for (final token in LlmEngine.instance.generate(
      'Explain how neural networks learn, in one paragraph.',
      modelPath: model.path,
      options: const GenerationOptions(
        temperature: 0.2,
        maxTokens: 128,
        contextSize: 8192,
      ),
    )) {
      if (token.isError) throw StateError(token.full);
      last = token;
      if (token.done) break;
    }
    report['benchmark_8k_tokens'] = last?.stats.tokens;
  });

  // 2c. The Tamil eval's multiple-choice call: 4K window, temperature 0,
  //     thinking off, a grammar allowing one letter.
  await step('eval_grammar', () async {
    final options = await GenerationSettingsStore.instance.optionsFor(
      model,
      requestedContext: 4096,
      requestedTemperature: 0,
      requestedThinking: false,
      maxTokens: 4,
      grammar: kOptionGrammar,
    );
    final buffer = StringBuffer();
    await for (final token in LlmEngine.instance.chat(
      [
        const ChatMessage(
          role: 'user',
          content:
              'Which is a colour? A) dog B) red C) run D) ten. '
              'Answer with one letter.',
        ),
      ],
      modelPath: model.path,
      options: options,
    )) {
      if (token.isError) throw StateError(token.full);
      buffer.write(token.delta);
    }
    report['eval_answer'] = buffer.toString();
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

  // 4. Chat history store: the bundled SQLite loads, writes and finds text.
  await step('sqlite', () async {
    final dir = await Directory.systemTemp.createTemp('thinai_smoke');
    try {
      final store = await SqliteChatStore.open(
        path: '${dir.path}${Platform.pathSeparator}chats.sqlite3',
      );
      store.upsert(
        ChatConversation(
          id: 'smoke',
          turns: const [
            ChatTurn(role: 'user', content: 'Where is Erode?'),
            ChatTurn(role: 'assistant', content: 'Erode is in Tamil Nadu.'),
          ],
          updatedAt: DateTime.now(),
        ),
      );
      final hits = store.search('tamil');
      final loaded = store.loadAll();
      store.dispose();
      report['sqlite_hits'] = hits.length;
      if (hits.isEmpty || loaded.length != 1) {
        throw StateError('search ${hits.length}, loaded ${loaded.length}');
      }
    } finally {
      await dir.delete(recursive: true);
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
