/// How each model generates: its context window and temperature, as the user
/// set them, applied the same way in the Chat tab and by the API server.
///
/// One store behind both on purpose. A model tuned in chat and then served to
/// a laptop should behave the same on the laptop; two settings screens that
/// could disagree would make "why is the API answer different" unanswerable.
///
/// A plain singleton rather than only a Riverpod notifier because the HTTP
/// routes live outside the widget tree and already reach the engine and the
/// model store the same way.
library;

import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models_repo/catalog.dart';
import '../models_repo/device_profile.dart';
import '../models_repo/gguf_metadata.dart';
import '../models_repo/model_store.dart';
import 'context_limits.dart';
import 'llm_engine.dart';

/// Temperature when nobody has chosen one: enough variety to read naturally,
/// low enough that the small models this app runs stay on topic.
const double kDefaultTemperature = 0.7;

/// Highest temperature offered. Past 2 every model this app runs produces
/// noise.
const double kMaxTemperature = 2.0;

/// "All layers", as Ollama and llama.cpp spell it.
const int kAllGpuLayers = 999;

/// One model's settings. Null fields mean "never set": the default applies,
/// and follows any change to the default rather than freezing it.
class ModelGenerationSettings {
  final int? contextSize;
  final double? temperature;

  const ModelGenerationSettings({this.contextSize, this.temperature});

  bool get isDefault => contextSize == null && temperature == null;

  Map<String, dynamic> toJson() => {
        if (contextSize != null) 'contextSize': contextSize,
        if (temperature != null) 'temperature': temperature,
      };

  factory ModelGenerationSettings.fromJson(Map<String, dynamic> json) =>
      ModelGenerationSettings(
        contextSize: (json['contextSize'] as num?)?.toInt(),
        temperature: (json['temperature'] as num?)?.toDouble(),
      );
}

/// Everything the store holds. Immutable, so a Riverpod listener sees a new
/// value on every change.
class GenerationSettings {
  final Map<String, ModelGenerationSettings> perModel;

  /// GPU acceleration, for every model. Off unless chosen: a phone's GPU
  /// driver is the least tested code on it, and for small models the CPU is
  /// often just as fast.
  final GpuBackend gpu;

  const GenerationSettings({
    this.perModel = const {},
    this.gpu = GpuBackend.none,
  });

  ModelGenerationSettings forModel(String id) =>
      perModel[id] ?? const ModelGenerationSettings();

  Map<String, dynamic> toJson() => {
        'gpu': gpu.storageKey,
        'perModel': {
          for (final e in perModel.entries)
            if (!e.value.isDefault) e.key: e.value.toJson(),
        },
      };

  factory GenerationSettings.fromJson(Map<String, dynamic> json) {
    final raw = json['perModel'];
    return GenerationSettings(
      gpu: GpuBackend.fromStorageKey(json['gpu'] as String?) ?? GpuBackend.none,
      perModel: {
        if (raw is Map)
          for (final e in raw.entries)
            if (e.value is Map)
              e.key as String: ModelGenerationSettings.fromJson(
                (e.value as Map).cast<String, dynamic>(),
              ),
      },
    );
  }
}

/// What a model is running with, resolved against its limits — what the
/// settings sheet shows and what a request is sent with.
class ResolvedGeneration {
  final ContextLimit limit;
  final int contextSize;
  final double temperature;

  const ResolvedGeneration({
    required this.limit,
    required this.contextSize,
    required this.temperature,
  });
}

class GenerationSettingsStore {
  GenerationSettingsStore._();
  static final GenerationSettingsStore instance = GenerationSettingsStore._();

  static const _key = 'generation_settings_v1';

  GenerationSettings _settings = const GenerationSettings();
  GenerationSettings get settings => _settings;

  final _changes = StreamController<GenerationSettings>.broadcast();
  Stream<GenerationSettings> get changes => _changes.stream;

  Future<void>? _loading;
  DeviceProfile? _device;

  /// Loads the saved settings once. Safe to call from anywhere, any number of
  /// times; later calls wait on the first.
  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        _settings = GenerationSettings.fromJson(
          (jsonDecode(raw) as Map).cast<String, dynamic>(),
        );
        _changes.add(_settings);
      }
    } on Object {
      // Corrupt settings are not worth a crash: defaults apply.
    }
  }

  Future<void> _save(GenerationSettings next) async {
    _settings = next;
    _changes.add(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(next.toJson()));
  }

  Future<void> update(
    String modelId, {
    int? contextSize,
    double? temperature,
  }) async {
    await ensureLoaded();
    final current = _settings.forModel(modelId);
    final next = ModelGenerationSettings(
      contextSize: contextSize ?? current.contextSize,
      temperature: temperature ?? current.temperature,
    );
    await _save(GenerationSettings(
      gpu: _settings.gpu,
      perModel: {..._settings.perModel, modelId: next},
    ));
  }

  Future<void> reset(String modelId) async {
    await ensureLoaded();
    await _save(GenerationSettings(
      gpu: _settings.gpu,
      perModel: {..._settings.perModel}..remove(modelId),
    ));
  }

  Future<void> setGpu(GpuBackend gpu) async {
    await ensureLoaded();
    await _save(GenerationSettings(gpu: gpu, perModel: _settings.perModel));
  }

  /// The context cap for [model] on this phone.
  Future<ContextLimit> limitFor(LocalModel model) async {
    final device = _device ??= await DeviceProfile.read();
    final info = await readGgufInfo(model.path);
    int? catalogTrained;
    for (final entry in modelCatalog) {
      if (entry.servedId == model.id) {
        catalogTrained = entry.contextTokens;
        break;
      }
    }
    return contextLimitFor(
      info: info,
      catalogTrained: catalogTrained,
      fileBytes: model.sizeBytes,
      device: device,
    );
  }

  /// [model]'s settings, with any per-request values layered on top and the
  /// window clamped to what the model and phone can take.
  ///
  /// A request naming its own temperature or `num_ctx` wins over the saved
  /// setting — that is what an API client expects — but never past the cap.
  Future<ResolvedGeneration> resolve(
    LocalModel model, {
    int? requestedContext,
    double? requestedTemperature,
  }) async {
    await ensureLoaded();
    final limit = await limitFor(model);
    final saved = _settings.forModel(model.id);

    final wanted = requestedContext ??
        saved.contextSize ??
        (kDefaultContextSize < limit.cap ? kDefaultContextSize : limit.cap);
    final temperature =
        (requestedTemperature ?? saved.temperature ?? kDefaultTemperature)
            .clamp(0.0, kMaxTemperature)
            .toDouble();

    return ResolvedGeneration(
      limit: limit,
      contextSize: limit.clamp(wanted),
      temperature: temperature,
    );
  }

  /// [GenerationOptions] for [model], ready to hand to the engine.
  ///
  /// [gpu] overrides the saved GPU choice for this request, e.g. the speed
  /// test running the same prompt on CPU and GPU.
  Future<GenerationOptions> optionsFor(
    LocalModel model, {
    int? requestedContext,
    double? requestedTemperature,
    double topP = 1.0,
    int maxTokens = -1,
    List<String> stop = const [],
    GpuBackend? gpu,
  }) async {
    final resolved = await resolve(
      model,
      requestedContext: requestedContext,
      requestedTemperature: requestedTemperature,
    );
    var backend = gpu ?? _settings.gpu;
    // A backend that keeps failing loads is rested and the request runs on
    // the CPU; an explicit `gpu` argument (the speed test) still tries it.
    if (gpu == null &&
        backend != GpuBackend.none &&
        LlmEngine.instance.gpuFailures.isRested(backend)) {
      backend = GpuBackend.none;
    }
    return GenerationOptions(
      temperature: resolved.temperature,
      topP: topP,
      maxTokens: maxTokens,
      contextSize: resolved.contextSize,
      // Every layer: llama.cpp caps this at the model's layer count, and a
      // partial offload on a phone's shared memory only adds copying.
      numGpuLayers: backend == GpuBackend.none ? 0 : kAllGpuLayers,
      gpuBackend: backend,
      stop: stop,
    );
  }
}
