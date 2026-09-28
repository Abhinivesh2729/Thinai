import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:fllama/fllama.dart';

import 'gpu_support.dart';

import 'chat_message.dart';

export 'chat_message.dart';
export 'gpu_support.dart' show GpuBackend;

/// A function the model may call, in OpenAI's `tools[].function` shape.
///
/// llama.cpp handles tool calling itself: given these, it picks the template's
/// tool syntax and constrains sampling to it, so the model can only emit a
/// well-formed call.
class ToolSpec {
  final String name;
  final String description;

  /// JSON Schema for the arguments object.
  final Map<String, dynamic> parameters;

  const ToolSpec({
    required this.name,
    this.description = '',
    this.parameters = const {'type': 'object', 'properties': {}},
  });
}

/// Default context window (n_ctx) when a caller doesn't specify one. Large
/// enough for long prompts on the small models this app targets, while staying
/// memory-safe on phones. Callers can request more via `num_ctx` up to the
/// model's trained maximum.
const int kDefaultContextSize = 8192;

class GenerationOptions {
  final double temperature;
  final double topP;

  /// Max tokens to generate. `-1` means "until the model stops" (llama.cpp
  /// `n_predict = -1`), i.e. no artificial output cap. A positive value caps
  /// the response length.
  final int maxTokens;

  /// Context window (n_ctx). Inputs + output share this budget. `0`/negative
  /// is treated as [kDefaultContextSize] since a 0 context breaks native batch
  /// sizing.
  final int contextSize;
  final int numGpuLayers;

  /// Which GPU backend runs the offloaded layers. [GpuBackend.none] keeps the
  /// whole model on the CPU whatever [numGpuLayers] says: on Android the
  /// native side needs both before it touches a GPU.
  final GpuBackend gpuBackend;

  /// Strings that end generation. Output is cut before the match and the match
  /// itself is never emitted, so a caller using a delimiter as a stop does not
  /// have to strip it back off.
  ///
  /// Enforced here rather than natively: llama.cpp takes stop words on its
  /// server params, but fllama's request struct has no field for them.
  final List<String> stop;

  const GenerationOptions({
    this.temperature = 0.7,
    this.topP = 1.0,
    this.maxTokens = -1,
    this.contextSize = kDefaultContextSize,
    this.numGpuLayers = 0,
    this.gpuBackend = GpuBackend.none,
    this.stop = const [],
  });
}

/// Timing for one generation, carried on every [LlmToken] so the UI can show
/// throughput live rather than only at the end.
///
/// [tokens] counts native decode callbacks, which llama.cpp fires once per
/// emitted token, so it is the model's own token count and not a character
/// estimate.
class LlmStats {
  /// Tokens emitted so far.
  final int tokens;

  /// Wall time since the request was handed to the engine. Includes model
  /// load, so it is larger than the decode window.
  final Duration elapsed;

  /// Time from request to the first token: model load plus prompt processing.
  /// Null until the first token arrives.
  final Duration? timeToFirstToken;

  /// Wall time spent decoding, measured from the first token.
  final Duration decodeTime;

  /// Prompt tokens llama.cpp reported for this request, from the timings it
  /// sends beside each token. 0 until the first timings payload arrives.
  final int promptTokens;

  /// Tokens llama.cpp reported decoding. Null until reported; [tokens] is the
  /// locally counted equivalent and is available sooner.
  final int? predictedTokens;

  const LlmStats({
    this.tokens = 0,
    this.elapsed = Duration.zero,
    this.timeToFirstToken,
    this.decodeTime = Duration.zero,
    this.promptTokens = 0,
    this.predictedTokens,
  });

  /// Decode throughput in tokens per second.
  ///
  /// Measured across the gaps *between* tokens (hence `tokens - 1`), which is
  /// what llama.cpp and Ollama report as eval rate: the first token's cost is
  /// prompt processing, not decoding, and is reported as
  /// [timeToFirstToken] instead. Null until there are two tokens to measure
  /// between.
  double? get tokensPerSecond {
    if (tokens < 2) return null;
    final seconds = decodeTime.inMicroseconds / 1e6;
    if (seconds <= 0) return null;
    return (tokens - 1) / seconds;
  }
}

class LlmToken {
  final String delta;
  final String full;
  final bool done;
  final LlmStats stats;

  /// True when [full] is a failure message rather than model output.
  ///
  /// The native side reports failures through the same callback as ordinary
  /// text, so without this a caller cannot tell a reply from an error and will
  /// happily store "request exceeds the available context size" as something
  /// the assistant said. Reported as a flag rather than a stream error because
  /// the HTTP routes deliberately pass the message through to their clients.
  final bool isError;

  /// Why generation ended: `stop`, `length`, or `tool_calls`. Set only on the
  /// final token, and only when llama.cpp reported one (or a stop word hit).
  final String? finishReason;

  /// Tool calls the model made, assembled from the streamed fragments. Set
  /// only on the final token, and only when there were any.
  final List<Map<String, dynamic>>? toolCalls;

  /// The raw OpenAI `tool_calls` delta entries that arrived with this token,
  /// so a streaming route can forward them chunk by chunk instead of waiting
  /// for the assembled call.
  final List<Map<String, dynamic>> toolCallDeltas;

  const LlmToken({
    required this.delta,
    required this.full,
    required this.done,
    this.stats = const LlmStats(),
    this.isError = false,
    this.finishReason,
    this.toolCalls,
    this.toolCallDeltas = const [],
  });
}

/// Decides how much of a reply is safe to emit while stop words are in play.
///
/// llama.cpp hands back the whole reply so far on every callback, and a stop
/// word can straddle two of them: emitting each token the moment it arrives
/// would send the first half of a stop word before the match is visible, and
/// no amount of trimming afterwards takes it back off a client that already
/// streamed it. So the tail is held back by one character less than the
/// longest stop word — enough that a match is always seen whole, and never
/// more than a few characters of latency.
class StopWordFilter {
  final List<String> _stops;
  final int _holdBack;

  var _visible = '';
  var _hit = false;

  StopWordFilter(List<String> stops)
      : _stops = [
          for (final s in stops)
            if (s.isNotEmpty) s
        ],
        _holdBack =
            stops.fold<int>(0, (m, s) => math.max(m, s.length)) - 1;

  /// The reply as the client has seen it: everything before the stop word.
  String get visible => _visible;

  /// True once a stop word has been matched. Generation should end here.
  bool get hit => _hit;

  /// Folds the cumulative [response] in and returns the text to emit now.
  ///
  /// [done] releases the held-back tail, since nothing more is coming that
  /// could complete a stop word.
  String consume(String response, {required bool done}) {
    if (_hit) return '';

    var visible = response;
    if (_stops.isNotEmpty) {
      var cut = -1;
      for (final stop in _stops) {
        final at = response.indexOf(stop);
        if (at >= 0 && (cut < 0 || at < cut)) cut = at;
      }
      if (cut >= 0) {
        visible = response.substring(0, cut);
        _hit = true;
      } else if (!done && _holdBack > 0) {
        final safe = _safeCut(response, response.length - _holdBack);
        visible = response.substring(
          0,
          safe > _visible.length ? safe : _visible.length,
        );
      }
    }

    final delta =
        visible.length > _visible.length ? visible.substring(_visible.length) : '';
    _visible = visible;
    return delta;
  }

  /// Never cuts between the halves of a surrogate pair — an emoji split across
  /// two deltas encodes as two lone surrogates, which is not valid JSON.
  int _safeCut(String response, int at) {
    if (at <= 0 || at >= response.length) return at;
    final unit = response.codeUnitAt(at - 1);
    final isHighSurrogate = unit >= 0xD800 && unit <= 0xDBFF;
    return isHighSurrogate ? at - 1 : at;
  }
}

class EmbeddingResult {
  /// One vector per input, in request order.
  final List<List<double>> embeddings;

  /// Dimensionality of each vector (ex. 768 for nomic-embed-text).
  final int dimensions;

  /// Prompt token count per input.
  final List<int> tokenCounts;

  const EmbeddingResult({
    required this.embeddings,
    required this.dimensions,
    required this.tokenCounts,
  });

  int get totalTokens => tokenCounts.fold(0, (sum, n) => sum + n);
}

/// Thrown when embedding fails, e.g. the model has no pooling layer.
class EmbeddingException implements Exception {
  final String message;
  const EmbeddingException(this.message);
  @override
  String toString() => message;
}

class LlmEngine {
  LlmEngine._();
  static final LlmEngine instance = LlmEngine._();

  String? _activeModelPath;
  String? get activeModelPath => _activeModelPath;

  /// Image encoder for the active model, when one has been downloaded.
  /// Without it a vision model is text-only.
  String? _activeProjectorPath;
  String? get activeProjectorPath => _activeProjectorPath;

  /// True when the loaded model can be shown an image.
  bool get visionReady => _activeProjectorPath != null;

  int? _currentRequestId;

  /// Set when [cancelCurrent] runs before the in-flight request has an id yet.
  /// Handing a request to the native side is asynchronous, so a stop tapped in
  /// that window would otherwise be dropped on the floor.
  bool _cancelPending = false;

  final _queue = <_QueuedJob>[];
  bool _busy = false;

  /// Consecutive GPU load failures; a rested backend is served on the CPU.
  final gpuFailures = GpuFailureTracker();

  void setActiveModel(String? path, {String? projectorPath}) {
    _activeModelPath = path;
    _activeProjectorPath = projectorPath;
  }

  /// Runs a chat completion.
  ///
  /// [tools], when non-empty, lets the model answer with a tool call instead of
  /// prose. [toolChoice] is `auto`, `none`, or `required`; anything else is
  /// treated as `auto`.
  Stream<LlmToken> chat(
    List<ChatMessage> messages, {
    String? modelPath,
    GenerationOptions options = const GenerationOptions(),
    List<ToolSpec> tools = const [],
    String? toolChoice,
    String? mmprojPath,
  }) {
    final path = modelPath ?? _activeModelPath;
    if (path == null) {
      return Stream.error(StateError('No model loaded'));
    }

    final controller = StreamController<LlmToken>();
    final job = _QueuedJob(
      messages: messages,
      modelPath: path,
      options: options,
      controller: controller,
      tools: tools,
      toolChoice: toolChoice,
      mmprojPath: mmprojPath ?? _activeProjectorPath,
    );
    _queue.add(job);
    _drain();
    return controller.stream;
  }

  Stream<LlmToken> generate(
    String prompt, {
    String? modelPath,
    GenerationOptions options = const GenerationOptions(),
  }) {
    return chat(
      [ChatMessage(role: 'user', content: prompt)],
      modelPath: modelPath,
      options: options,
    );
  }

  void cancelCurrent() {
    final id = _currentRequestId;
    if (id == null) {
      _cancelPending = true;
      return;
    }
    fllamaCancelInference(id);
  }

  /// Embeds [inputs], returning one vector per input in the same order.
  ///
  /// [modelPath] must point at an embedding model (ex. nomic-embed-text).
  /// Chat models have no pooling layer; those are rejected natively rather
  /// than returning meaningless vectors, and surface here as an
  /// [EmbeddingException].
  ///
  /// Embeddings use their own llama context, so this does not disturb (or
  /// queue behind) in-flight chat generation.
  Future<EmbeddingResult> embedBatch(
    List<String> inputs, {
    String? modelPath,
    int contextSize = 2048,
    int numGpuLayers = 0,
  }) async {
    final path = modelPath ?? _activeModelPath;
    if (path == null) {
      throw const EmbeddingException('No model loaded');
    }
    if (inputs.isEmpty) {
      throw const EmbeddingException('input must not be empty');
    }

    try {
      final result = await fllamaEmbed(
        FllamaEmbedRequest(
          inputs: inputs,
          modelPath: path,
          contextSize: contextSize,
          numGpuLayers: numGpuLayers,
        ),
      );
      return EmbeddingResult(
        embeddings: result.embeddings,
        dimensions: result.nEmbd,
        tokenCounts: result.nTokens,
      );
    } on FllamaEmbedException catch (e) {
      throw EmbeddingException(e.message);
    }
  }

  /// Convenience wrapper over [embedBatch] for a single string.
  Future<List<double>> embed(String text, {String? modelPath}) async {
    final result = await embedBatch([text], modelPath: modelPath);
    return result.embeddings.first;
  }

  Future<void> _drain() async {
    if (_busy) return;
    _busy = true;
    while (_queue.isNotEmpty) {
      final job = _queue.removeAt(0);
      try {
        await _run(job);
      } catch (e, st) {
        if (!job.controller.isClosed) {
          job.controller.addError(e, st);
          await job.controller.close();
        }
      }
    }
    _busy = false;
  }

  Future<void> _run(_QueuedJob job) async {
    var onGpu = job.options.gpuBackend != GpuBackend.none &&
        job.options.numGpuLayers > 0;
    // A backend that keeps failing loads rests for a while and the request
    // runs on the CPU; the saved setting is left alone.
    if (onGpu && gpuFailures.isRested(job.options.gpuBackend)) {
      onGpu = false;
    }
    final request = OpenAiRequest(
      messages: job.messages
          .map((m) => Message(
                _roleFromString(m.role),
                m.content,
                toolCalls: m.toolCalls,
                toolResponseName: m.toolName,
              ))
          .toList(),
      tools: [
        for (final t in job.tools)
          Tool(
            name: t.name,
            description: t.description,
            jsonSchema: jsonEncode(t.parameters),
          ),
      ],
      toolChoice: _toolChoiceFromString(job.toolChoice),
      modelPath: job.modelPath,
      // llama.cpp loads this beside the weights and uses it to turn any
      // <img src="data:..."> in the prompt into image tokens.
      mmprojPath: job.mmprojPath,
      temperature: job.options.temperature,
      topP: job.options.topP,
      maxTokens: job.options.maxTokens,
      // Guard: a non-positive n_ctx collapses native batch sizing (n_batch =
      // min(n_ctx, 2048) → 0), so fall back to the default window.
      contextSize: job.options.contextSize > 0
          ? job.options.contextSize
          : kDefaultContextSize,
      numGpuLayers: onGpu ? job.options.numGpuLayers : 0,
      gpuBackend: onGpu ? job.options.gpuBackend.ffiValue : 0,
    );

    // A vendor GPU driver that crashes takes the whole process with it, and
    // nothing in Dart gets to react. So the attempt is written down first and
    // crossed off once a token proves the driver works: a flag still standing
    // at the next launch means this phone's GPU killed the app, and GPU is
    // turned off before it can do so again.
    if (onGpu) await markGpuTrialPending(job.options.gpuBackend);
    var gpuProven = !onGpu;

    final completer = Completer<void>();
    var lastRaw = '';
    var loadFailed = false;

    // A cancel from a previous request must not carry over into this one.
    _cancelPending = false;

    // Throughput bookkeeping. The native callback fires once per decoded
    // token, so counting non-empty deltas counts tokens; the final done
    // callback repeats the full text with an empty delta and must not count.
    final startedAt = DateTime.now();
    DateTime? firstTokenAt;
    DateTime? lastTokenAt;
    var tokens = 0;
    var callbacks = 0;

    final chunks = _OaiChunks();

    final stopWords = StopWordFilter(job.options.stop);
    var stopped = false;

    _currentRequestId = await fllamaChat(request, (response, openAiJson, done) {
      if (job.controller.isClosed) return;

      // Once a stop word has been served the reply is over. Later callbacks
      // are the tail of a cancel in flight: drop them, but still let the real
      // final one release the queue.
      if (stopped) {
        if (done && !completer.isCompleted) completer.complete();
        return;
      }

      callbacks++;
      chunks.consume(openAiJson);

      // Any callback, error or token, means the load came back alive.
      if (!gpuProven) {
        gpuProven = true;
        unawaited(clearGpuTrialPending());
      }

      // A failure arrives as the very first callback, already final, carrying
      // the message where the reply would go and with no OpenAI payload beside
      // it. A stop before the first token looks similar but carries no text,
      // so requiring a non-empty response keeps the two apart.
      final isError =
          callbacks == 1 && done && openAiJson.isEmpty && response.isNotEmpty;
      if (isError && onGpu && !gpuProven) loadFailed = true;

      // Throughput counts raw tokens, not visible ones, so holding text back
      // for stop-word matching does not make the live tok/s sag.
      final now = DateTime.now();
      if (response.length != lastRaw.length) {
        tokens++;
        firstTokenAt ??= now;
        lastTokenAt = now;
      }
      lastRaw = response;

      // A failure message is not model output, so stop words have no business
      // truncating it.
      final String delta;
      final String visible;
      if (isError) {
        delta = response;
        visible = response;
      } else {
        delta = stopWords.consume(response, done: done);
        visible = stopWords.visible;
      }
      final hitStop = stopWords.hit;

      final first = firstTokenAt;
      final last = lastTokenAt;
      final isFinal = done || hitStop;
      final stats = LlmStats(
        tokens: tokens,
        elapsed: now.difference(startedAt),
        timeToFirstToken: first?.difference(startedAt),
        decodeTime: first == null || last == null
            ? Duration.zero
            : last.difference(first),
        promptTokens: chunks.promptTokens,
        predictedTokens: chunks.predictedTokens,
      );

      job.controller.add(
        LlmToken(
          delta: delta,
          full: visible,
          done: isFinal,
          isError: isError,
          stats: stats,
          finishReason: isFinal
              ? (hitStop ? 'stop' : _finishReason(chunks, job, tokens))
              : null,
          toolCalls: isFinal ? chunks.toolCalls : null,
          toolCallDeltas: chunks.deltas,
        ),
      );

      if (hitStop) {
        // Tell llama.cpp to quit decoding text nobody will ever see. The real
        // final callback still arrives and completes the job.
        stopped = true;
        cancelCurrent();
        return;
      }
      if (done && !completer.isCompleted) {
        completer.complete();
      }
    });

    if (_cancelPending) {
      _cancelPending = false;
      fllamaCancelInference(_currentRequestId!);
    }

    await completer.future;
    _currentRequestId = null;
    // A load that never produced a token counts towards resting the backend;
    // the first token clears the count (gpuProven doubles as the success mark).
    if (onGpu) {
      if (loadFailed) {
        gpuFailures.recordFailure(job.options.gpuBackend);
      } else if (gpuProven) {
        gpuFailures.recordSuccess(job.options.gpuBackend);
      }
    }
    if (!job.controller.isClosed) {
      await job.controller.close();
    }
  }

  /// Why generation ended, preferring what llama.cpp reported.
  ///
  /// It only omits one when the request was cancelled or the read loop ended
  /// early, so the fallback distinguishes the one case a caller cares about:
  /// output cut off by [GenerationOptions.maxTokens] rather than by the model
  /// choosing to stop.
  String _finishReason(_OaiChunks chunks, _QueuedJob job, int tokens) {
    final reported = chunks.finishReason;
    if (reported != null && reported.isNotEmpty) return reported;
    if (chunks.toolCalls != null) return 'tool_calls';
    final cap = job.options.maxTokens;
    final decoded = chunks.predictedTokens ?? tokens;
    if (cap > 0 && decoded >= cap) return 'length';
    return 'stop';
  }

  ToolChoice? _toolChoiceFromString(String? choice) {
    switch (choice) {
      case 'none':
        return ToolChoice.none;
      case 'required':
        return ToolChoice.required;
      case 'auto':
        return ToolChoice.auto;
      default:
        return null;
    }
  }

  Role _roleFromString(String role) {
    switch (role) {
      case 'system':
        return Role.system;
      case 'assistant':
        return Role.assistant;
      case 'tool':
        return Role.tool;
      case 'user':
      default:
        return Role.user;
    }
  }
}

class _QueuedJob {
  final List<ChatMessage> messages;
  final String modelPath;
  final GenerationOptions options;
  final StreamController<LlmToken> controller;
  final List<ToolSpec> tools;
  final String? toolChoice;
  final String? mmprojPath;

  _QueuedJob({
    required this.messages,
    required this.modelPath,
    required this.options,
    required this.controller,
    this.tools = const [],
    this.toolChoice,
    this.mmprojPath,
  });
}

/// Reads the OpenAI-shaped JSON llama.cpp hands back beside every token.
///
/// The native side runs the request through llama.cpp's own OpenAI chat path,
/// so each callback carries an array of `chat.completion.chunk` objects: the
/// same wire format an OpenAI client parses. That is where the real token
/// counts, the real finish reason, and tool calls live — everything the routes
/// used to have to fake.
class _OaiChunks {
  final _calls = <int, Map<String, dynamic>>{};

  String? finishReason;
  int promptTokens = 0;
  int? predictedTokens;

  /// Tool-call deltas seen in the most recent [consume], for pass-through to
  /// streaming clients.
  List<Map<String, dynamic>> deltas = const [];

  /// Assembled tool calls, or null when the model made none.
  List<Map<String, dynamic>>? get toolCalls {
    if (_calls.isEmpty) return null;
    final indexes = _calls.keys.toList()..sort();
    return [for (final i in indexes) _calls[i]!];
  }

  void consume(String raw) {
    deltas = const [];
    if (raw.isEmpty) return;
    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      // Partial or unparseable payloads are not worth failing a generation
      // over; the text stream is unaffected.
      return;
    }
    final fresh = <Map<String, dynamic>>[];
    if (decoded is List) {
      for (final chunk in decoded) {
        if (chunk is Map) _chunk(chunk.cast<String, dynamic>(), fresh);
      }
    } else if (decoded is Map) {
      _chunk(decoded.cast<String, dynamic>(), fresh);
    }
    if (fresh.isNotEmpty) deltas = fresh;
  }

  void _chunk(Map<String, dynamic> chunk, List<Map<String, dynamic>> fresh) {
    final timings = chunk['timings'];
    if (timings is Map) {
      final prompt = timings['prompt_n'];
      if (prompt is int && prompt >= 0) promptTokens = prompt;
      final predicted = timings['predicted_n'];
      if (predicted is int && predicted >= 0) predictedTokens = predicted;
    }

    final choices = chunk['choices'];
    if (choices is! List) return;
    for (final choice in choices) {
      if (choice is! Map) continue;
      final reason = choice['finish_reason'];
      if (reason is String && reason.isNotEmpty) finishReason = reason;

      final delta = choice['delta'];
      if (delta is! Map) continue;
      final calls = delta['tool_calls'];
      if (calls is! List) continue;
      for (final call in calls) {
        if (call is! Map) continue;
        final entry = call.cast<String, dynamic>();
        fresh.add(entry);
        _merge(entry);
      }
    }
  }

  /// Folds one delta into the call it belongs to. Arguments arrive as a string
  /// split across tokens, so they concatenate rather than overwrite.
  void _merge(Map<String, dynamic> delta) {
    final index = delta['index'] is int ? delta['index'] as int : 0;
    final target = _calls.putIfAbsent(
      index,
      () => <String, dynamic>{
        'index': index,
        'id': '',
        'type': 'function',
        'function': <String, dynamic>{'name': '', 'arguments': ''},
      },
    );

    final id = delta['id'];
    if (id is String && id.isNotEmpty) target['id'] = id;

    final function = delta['function'];
    if (function is! Map) return;
    final into = target['function'] as Map<String, dynamic>;
    final name = function['name'];
    if (name is String && name.isNotEmpty) into['name'] = name;
    final arguments = function['arguments'];
    if (arguments is String && arguments.isNotEmpty) {
      into['arguments'] = (into['arguments'] as String) + arguments;
    }
  }
}
