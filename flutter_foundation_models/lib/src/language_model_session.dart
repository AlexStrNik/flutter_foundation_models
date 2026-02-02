import 'dart:async';

import 'package:flutter_foundation_models/flutter_foundation_models.dart';
import 'package:flutter_foundation_models/src/generated/foundation_models_api.g.dart';
import 'package:flutter_foundation_models/src/pigeon_impl/flutter_api_impl.dart';

final class LanguageModelSession {
  final List<Tool> tools;
  final String? instructions;

  static final FlutterApiImpl _flutterApiImpl = FlutterApiImpl();
  static bool _flutterApiSetUp = false;

  static final FoundationModelsHostApi _hostApi = FoundationModelsHostApi();

  LanguageModelSession({
    this.tools = const [],
    this.instructions,
  }) {
    if (!_flutterApiSetUp) {
      FoundationModelsFlutterApi.setUp(_flutterApiImpl);
      _flutterApiSetUp = true;
    }

    _initInBackground();
  }

  final Completer<String> _initCompleter = Completer<String>();
  bool _isDisposed = false;

  Future<void> _initInBackground() async {
    try {
      final toolMessages = tools.map((tool) {
        return ToolDefinitionMessage(
          name: tool.name,
          description: tool.description,
          parameters: _convertToNullableKeys(tool.parameters.toJson()),
        );
      }).toList();

      final sessionId = await _hostApi.createSession(toolMessages, instructions);
      _flutterApiImpl.registerSession(sessionId, tools);
      _initCompleter.complete(sessionId);
    } catch (e) {
      _initCompleter.completeError(e);
    }
  }

  Map<String?, Object?> _convertToNullableKeys(Map<String, dynamic> map) {
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

  Future<void> dispose() async {
    if (_isDisposed) return;

    try {
      final sessionId = await _initCompleter.future;
      _flutterApiImpl.unregisterSession(sessionId);
      await _hostApi.destroySession(sessionId);
      _isDisposed = true;
    } catch (e) {
      rethrow;
    }
  }

  /// Respond to a prompt with a text response.
  Future<String> respondTo(
    String prompt, {
    GenerationOptions? options,
  }) async {
    if (_isDisposed) {
      throw Exception('Cannot respond with a disposed LanguageModelSession');
    }

    try {
      final sessionId = await _initCompleter.future;
      final response = await _hostApi.respondTo(
        sessionId,
        prompt,
        _convertOptions(options),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Respond to a prompt with structured output according to the schema.
  Future<GeneratedContent> respondToWithSchema(
    String prompt, {
    required GenerationSchema schema,
    bool includeSchemaInPrompt = true,
    GenerationOptions? options,
  }) async {
    if (_isDisposed) {
      throw Exception('Cannot respond with a disposed LanguageModelSession');
    }

    try {
      final sessionId = await _initCompleter.future;
      final schemaJson = _convertToNullableKeys(schema.toJson());
      final response = await _hostApi.respondToWithSchema(
        sessionId,
        prompt,
        schemaJson,
        includeSchemaInPrompt,
        _convertOptions(options),
      );
      return GeneratedContent(_cleanMapKeys(response));
    } catch (e) {
      rethrow;
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
