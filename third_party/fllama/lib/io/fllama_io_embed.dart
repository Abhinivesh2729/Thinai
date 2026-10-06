// ignore_for_file: non_constant_identifier_names
// Field names mirror the C struct in src/fllama_embed.h on purpose.
// Embedding FFI. Pairs with src/fllama_embed.{h,cpp}.
//
// The bindings are hand-written rather than generated: fllama_bindings_generated.dart
// comes from ffigen, and regenerating it would mean an LLVM toolchain on every
// machine that builds this fork for the sake of two functions.

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:fllama/fllama_io.dart';
import 'package:fllama/fllama_universal.dart';
import 'package:fllama/io/fllama_io_helpers.dart';

// ── Native layout — must match src/fllama_embed.h exactly ───────────────────

final class _FllamaEmbedRequestNative extends Struct {
  external Pointer<Char> model_path;
  external Pointer<Pointer<Char>> inputs;
  @Int32()
  external int n_inputs;
  @Int32()
  external int context_size;
  @Int32()
  external int num_gpu_layers;
}

final class _FllamaEmbedResultNative extends Struct {
  external Pointer<Float> embeddings;
  @Int32()
  external int n_seq;
  @Int32()
  external int n_embd;
  external Pointer<Int32> n_tokens;
  external Pointer<Char> error;
}

typedef _FllamaEmbedC = Pointer<_FllamaEmbedResultNative> Function(
    Pointer<_FllamaEmbedRequestNative>);
typedef _FllamaEmbedDart = Pointer<_FllamaEmbedResultNative> Function(
    Pointer<_FllamaEmbedRequestNative>);

typedef _FllamaEmbedFreeC = Void Function(Pointer<_FllamaEmbedResultNative>);
typedef _FllamaEmbedFreeDart = void Function(
    Pointer<_FllamaEmbedResultNative>);

// ── Isolate plumbing ────────────────────────────────────────────────────────
//
// Embedding blocks for as long as the forward pass takes, so it cannot run on
// the main isolate. Same shape as fllama_io_tokenize.dart.

class _IsolateEmbedRequest {
  final int id;
  final FllamaEmbedRequest request;
  const _IsolateEmbedRequest(this.id, this.request);
}

class _IsolateEmbedResponse {
  final int id;
  final FllamaEmbedResult? result;
  final String? error;
  const _IsolateEmbedResponse(this.id, this.result, this.error);
}

int _nextEmbedRequestId = 0;
final Map<int, Completer<FllamaEmbedResult>> _isolateEmbedRequests =
    <int, Completer<FllamaEmbedResult>>{};

Future<SendPort> _helperEmbedIsolateSendPort = (() async {
  final completer = Completer<SendPort>();
  final receivePort = ReceivePort();

  await Isolate.spawn(_fllamaEmbedIsolate, receivePort.sendPort);

  receivePort.listen((dynamic data) {
    if (data is SendPort) {
      completer.complete(data);
      return;
    }
    if (data is _IsolateEmbedResponse) {
      final requestCompleter = _isolateEmbedRequests.remove(data.id);
      if (requestCompleter == null) {
        return;
      }
      final result = data.result;
      if (result != null) {
        requestCompleter.complete(result);
      } else {
        requestCompleter.completeError(
          FllamaEmbedException(data.error ?? 'Unknown embedding error'),
        );
      }
    }
  });

  return completer.future;
}());

/// Embeds [request.inputs], returning one vector per input, in order.
///
/// Throws [FllamaEmbedException] when the model cannot embed — most often
/// because it is a chat model, which has no pooling layer.
Future<FllamaEmbedResult> fllamaEmbed(FllamaEmbedRequest request) async {
  final SendPort helperIsolateSendPort = await _helperEmbedIsolateSendPort;

  final requestId = _nextEmbedRequestId++;
  final completer = Completer<FllamaEmbedResult>();
  _isolateEmbedRequests[requestId] = completer;
  helperIsolateSendPort.send(_IsolateEmbedRequest(requestId, request));
  return completer.future;
}

void _fllamaEmbedIsolate(SendPort mainIsolateSendPort) {
  final helperReceivePort = ReceivePort();
  mainIsolateSendPort.send(helperReceivePort.sendPort);

  final embed = fllamaDylib
      .lookupFunction<_FllamaEmbedC, _FllamaEmbedDart>('fllama_embed');
  final embedFree = fllamaDylib
      .lookupFunction<_FllamaEmbedFreeC, _FllamaEmbedFreeDart>(
          'fllama_embed_free');

  helperReceivePort.listen((dynamic data) {
    if (data is! _IsolateEmbedRequest) {
      return;
    }

    final req = calloc<_FllamaEmbedRequestNative>();
    final inputs = calloc<Pointer<Char>>(data.request.inputs.length);
    for (var i = 0; i < data.request.inputs.length; i++) {
      inputs[i] = stringToPointerChar(data.request.inputs[i]);
    }
    req.ref.model_path = stringToPointerChar(data.request.modelPath);
    req.ref.inputs = inputs;
    req.ref.n_inputs = data.request.inputs.length;
    req.ref.context_size = data.request.contextSize;
    req.ref.num_gpu_layers = data.request.numGpuLayers;

    Pointer<_FllamaEmbedResultNative> res = nullptr;
    try {
      res = embed(req);

      if (res == nullptr) {
        mainIsolateSendPort.send(_IsolateEmbedResponse(
            data.id, null, 'Out of memory while embedding'));
        return;
      }

      final error = pointerCharToString(res.ref.error);
      if (error.isNotEmpty) {
        mainIsolateSendPort.send(_IsolateEmbedResponse(data.id, null, error));
        return;
      }

      final nSeq = res.ref.n_seq;
      final nEmbd = res.ref.n_embd;
      // Copy out before the native buffer is freed below.
      final flat = res.ref.embeddings.asTypedList(nSeq * nEmbd);
      final tokens = res.ref.n_tokens.asTypedList(nSeq);
      final embeddings = <List<double>>[
        for (var i = 0; i < nSeq; i++)
          List<double>.from(flat.sublist(i * nEmbd, (i + 1) * nEmbd)),
      ];

      mainIsolateSendPort.send(_IsolateEmbedResponse(
        data.id,
        FllamaEmbedResult(
          embeddings: embeddings,
          nEmbd: nEmbd,
          nTokens: List<int>.from(tokens),
        ),
        null,
      ));
    } catch (e) {
      mainIsolateSendPort
          .send(_IsolateEmbedResponse(data.id, null, e.toString()));
    } finally {
      if (res != nullptr) {
        embedFree(res);
      }
      for (var i = 0; i < data.request.inputs.length; i++) {
        calloc.free(inputs[i]);
      }
      calloc.free(inputs);
      calloc.free(req.ref.model_path);
      calloc.free(req);
    }
  });
}
