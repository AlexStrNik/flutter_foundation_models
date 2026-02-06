import 'dart:async';

import 'package:flutter_foundation_models/flutter_foundation_models.dart';
import 'package:flutter_foundation_models/src/generated/foundation_models_api.g.dart';
import 'package:flutter_foundation_models/src/pigeon_impl/flutter_api_impl.dart';

/// A session for interacting with Apple's on-device Foundation Models.
///
/// Create a session using [LanguageModelSession.create].
///
/// Example:
/// ```dart
/// if (await SystemLanguageModel.isAvailable) {
///   final session = await LanguageModelSession.create();
///   final response = await session.respondTo("What is Flutter?");
///   session.dispose();
/// }
/// ```
final class LanguageModelSession {
  final String _sessionId;
  final SystemLanguageModel _model;
  final List<Tool> _tools;

  bool _isDisposed = false;
  final Set<String> _activeStreams = {};

  static final FlutterApiImpl _flutterApiImpl = FlutterApiImpl();
  static bool _flutterApiSetUp = false;
  static final FoundationModelsHostApi _hostApi = FoundationModelsHostApi();

  LanguageModelSession._(this._sessionId, this._model, this._tools);

  /// The language model used by this session.
  SystemLanguageModel get model => _model;

  /// Tools available for the model to use.
  List<Tool> get tools => _tools;

  /// Creates a new language model session.
  ///
  /// [model] - The language model to use. Defaults to [SystemLanguageModel.defaultModel].
  /// [tools] - Optional list of tools the model can use.
  /// [instructions] - Optional system instructions for the model.
  static Future<LanguageModelSession> create({
    SystemLanguageModel? model,
    List<Tool> tools = const [],
    String? instructions,
  }) async {
    if (!_flutterApiSetUp) {
      FoundationModelsFlutterApi.setUp(_flutterApiImpl);
      _flutterApiSetUp = true;
    }

    final effectiveModel = model ?? SystemLanguageModel.defaultModel;

    final toolMessages = tools.map((tool) {
      return ToolDefinitionMessage(
        name: tool.name,
        description: tool.description,
        parameters: _convertToNullableKeys(tool.parameters.toJson()),
      );
    }).toList();

    final sessionId = await _hostApi.createSession(
      effectiveModel.modelId,
      toolMessages,
      instructions,
    );

    _flutterApiImpl.registerSession(sessionId, tools);
    return LanguageModelSession._(sessionId, effectiveModel, tools);
  }

  /// Creates a new language model session with an existing transcript.
  ///
  /// Use this to continue a previous conversation.
  ///
  /// [model] - The language model to use. Defaults to [SystemLanguageModel.defaultModel].
  /// [tools] - Optional list of tools the model can use.
  /// [transcript] - The transcript to continue from.
  static Future<LanguageModelSession> createWithTranscript({
    SystemLanguageModel? model,
    List<Tool> tools = const [],
    required Transcript transcript,
  }) async {
    if (!_flutterApiSetUp) {
      FoundationModelsFlutterApi.setUp(_flutterApiImpl);
      _flutterApiSetUp = true;
    }

    final effectiveModel = model ?? SystemLanguageModel.defaultModel;

    final toolMessages = tools.map((tool) {
      return ToolDefinitionMessage(
        name: tool.name,
        description: tool.description,
        parameters: _convertToNullableKeys(tool.parameters.toJson()),
      );
    }).toList();

    final sessionId = await _hostApi.createSessionWithTranscript(
      effectiveModel.modelId,
      toolMessages,
      transcript.toJson(),
    );

    _flutterApiImpl.registerSession(sessionId, tools);
    return LanguageModelSession._(sessionId, effectiveModel, tools);
  }

  static Map<String?, Object?> _convertToNullableKeys(Map<String, dynamic> map) {
    final result = <String?, Object?>{};
    for (final entry in map.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        result[entry.key] = _convertToNullableKeys(value);
      } else if (value is List) {
        result[entry.key] = value.map((e) {
          if (e is Map<String, dynamic>) {
            return _convertToNullableKeys(e);
          }
          return e;
        }).toList();
      } else {
        result[entry.key] = value;
      }
    }
    return result;
  }

  /// Whether the session is currently responding.
  Future<bool> get isResponding async {
    if (_isDisposed) return false;
    try {
      return await _hostApi.isSessionResponding(_sessionId);
    } catch (_) {
      return false;
    }
  }

  /// Gets the current transcript of this session.
  ///
  /// The transcript contains the full conversation history including
  /// prompts, responses, tool calls, and tool outputs.
  Future<Transcript> get transcript async {
    if (_isDisposed) {
      throw Exception('Cannot get transcript from a disposed LanguageModelSession');
    }
    final jsonString = await _hostApi.getSessionTranscript(_sessionId);
    return Transcript.fromJson(jsonString);
  }

  /// Prewarms the session to reduce latency on the first request.
  Future<void> prewarm({String? promptPrefix}) async {
    if (_isDisposed) {
      throw Exception('Cannot prewarm a disposed LanguageModelSession');
    }
    await _hostApi.prewarmSession(_sessionId, promptPrefix);
  }

  /// Disposes the session and releases resources.
  Future<void> dispose() async {
    if (_isDisposed) return;

    for (final streamId in _activeStreams.toList()) {
      try {
        await _hostApi.cancelStream(streamId);
      } catch (_) {}
      _flutterApiImpl.unregisterStream(streamId);
      _flutterApiImpl.unregisterTextStream(streamId);
    }
    _activeStreams.clear();

    _flutterApiImpl.unregisterSession(_sessionId);
    await _hostApi.destroySession(_sessionId);
    _isDisposed = true;
  }

  /// Generates a text response for the given prompt.
  Future<String> respondTo(
    String prompt, {
    GenerationOptions? options,
  }) async {
    if (_isDisposed) {
      throw Exception('Cannot respond with a disposed LanguageModelSession');
    }
    return await _hostApi.respondTo(_sessionId, prompt, _convertOptions(options));
  }

  /// Streams a text response for the given prompt.
  Stream<String> streamResponseTo(
    String prompt, {
    GenerationOptions? options,
  }) {
    if (_isDisposed) {
      throw Exception('Cannot stream with a disposed LanguageModelSession');
    }

    late StreamController<String> controller;

    controller = StreamController<String>(
      onCancel: () async {
        final streamId = controller.hashCode.toString();
        if (_activeStreams.contains(streamId)) {
          try {
            await _hostApi.cancelStream(streamId);
          } catch (_) {}
          _flutterApiImpl.unregisterTextStream(streamId);
          _activeStreams.remove(streamId);
        }
      },
    );

    _startTextStream(controller, prompt, options);
    return controller.stream;
  }

  Future<void> _startTextStream(
    StreamController<String> controller,
    String prompt,
    GenerationOptions? options,
  ) async {
    try {
      final streamId = await _hostApi.streamResponseTo(
        _sessionId,
        prompt,
        _convertOptions(options),
      );

      _activeStreams.add(streamId);

      _flutterApiImpl.registerTextStream(
        streamId,
        onUpdate: (text) {
          if (!controller.isClosed) controller.add(text);
        },
        onComplete: (finalText) {
          if (!controller.isClosed) {
            controller.add(finalText);
            controller.close();
          }
          _activeStreams.remove(streamId);
        },
        onError: (errorCode, errorMessage) {
          if (!controller.isClosed) {
            controller.addError(Exception('$errorCode: $errorMessage'));
            controller.close();
          }
          _activeStreams.remove(streamId);
        },
      );
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
        controller.close();
      }
    }
  }

  /// Generates structured content according to a schema.
  Future<GeneratedContent> respondToWithSchema(
    String prompt, {
    required GenerationSchema schema,
    bool includeSchemaInPrompt = true,
    GenerationOptions? options,
  }) async {
    if (_isDisposed) {
      throw Exception('Cannot respond with a disposed LanguageModelSession');
    }

    final schemaJson = _convertToNullableKeys(schema.toJson());
    final response = await _hostApi.respondToWithSchema(
      _sessionId,
      prompt,
      schemaJson,
      includeSchemaInPrompt,
      _convertOptions(options),
    );
    return GeneratedContent(_cleanMapKeys(response));
  }

  /// Streams structured content as it's generated.
  Stream<GeneratedContent> streamResponseToWithSchema(
    String prompt, {
    required GenerationSchema schema,
    bool includeSchemaInPrompt = true,
    GenerationOptions? options,
  }) {
    if (_isDisposed) {
      throw Exception('Cannot stream with a disposed LanguageModelSession');
    }

    late StreamController<GeneratedContent> controller;

    controller = StreamController<GeneratedContent>(
      onCancel: () async {
        final streamId = controller.hashCode.toString();
        if (_activeStreams.contains(streamId)) {
          try {
            await _hostApi.cancelStream(streamId);
          } catch (_) {}
          _flutterApiImpl.unregisterStream(streamId);
          _activeStreams.remove(streamId);
        }
      },
    );

    _startStream(controller, prompt, schema, includeSchemaInPrompt, options);
    return controller.stream;
  }

  Future<void> _startStream(
    StreamController<GeneratedContent> controller,
    String prompt,
    GenerationSchema schema,
    bool includeSchemaInPrompt,
    GenerationOptions? options,
  ) async {
    try {
      final schemaJson = _convertToNullableKeys(schema.toJson());

      final streamId = await _hostApi.streamResponseToWithSchema(
        _sessionId,
        prompt,
        schemaJson,
        includeSchemaInPrompt,
        _convertOptions(options),
      );

      _activeStreams.add(streamId);

      _flutterApiImpl.registerStream(
        streamId,
        onSnapshot: (partialContent) {
          if (!controller.isClosed) controller.add(partialContent);
        },
        onComplete: (finalContent) {
          if (!controller.isClosed) {
            controller.add(finalContent);
            controller.close();
          }
          _activeStreams.remove(streamId);
        },
        onError: (errorCode, errorMessage) {
          if (!controller.isClosed) {
            controller.addError(Exception('$errorCode: $errorMessage'));
            controller.close();
          }
          _activeStreams.remove(streamId);
        },
      );
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
        controller.close();
      }
    }
  }

  GenerationOptionsMessage? _convertOptions(GenerationOptions? options) {
    if (options == null) return null;

    SamplingModeMessage? samplingMessage;
    final sampling = options.sampling;
    if (sampling != null) {
      samplingMessage = switch (sampling) {
        GreedySamplingMode() => SamplingModeMessage(type: SamplingModeType.greedy),
        TopKSamplingMode(:final k, :final seed) => SamplingModeMessage(
            type: SamplingModeType.topK,
            topK: k,
            seed: seed,
          ),
        TopPSamplingMode(:final probabilityThreshold, :final seed) => SamplingModeMessage(
            type: SamplingModeType.topP,
            probabilityThreshold: probabilityThreshold,
            seed: seed,
          ),
      };
    }

    return GenerationOptionsMessage(
      sampling: samplingMessage,
      temperature: options.temperature,
      maximumResponseTokens: options.maximumResponseTokens,
    );
  }

  Map<String, dynamic> _cleanMapKeys(Map<String?, Object?> map) {
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.key != null) {
        final value = entry.value;
        if (value is Map<String?, Object?>) {
          result[entry.key!] = _cleanMapKeys(value);
        } else if (value is List) {
          result[entry.key!] = value.map((e) {
            if (e is Map<String?, Object?>) {
              return _cleanMapKeys(e);
            }
            return e;
          }).toList();
        } else {
          result[entry.key!] = value;
        }
      }
    }
    return result;
  }
}
