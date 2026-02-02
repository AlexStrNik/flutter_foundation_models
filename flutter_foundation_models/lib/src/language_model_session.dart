import 'dart:async';

import 'package:flutter_foundation_models/flutter_foundation_models.dart';
import 'package:flutter_foundation_models/src/generated/foundation_models_api.g.dart';
import 'package:flutter_foundation_models/src/pigeon_impl/flutter_api_impl.dart';

final class LanguageModelSession {
  final List<Tool> tools;

  static final FlutterApiImpl _flutterApiImpl = FlutterApiImpl();
  static bool _flutterApiSetUp = false;

  static final FoundationModelsHostApi _hostApi = FoundationModelsHostApi();

  LanguageModelSession({
    this.tools = const [],
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

      final sessionId = await _hostApi.createSession(toolMessages);
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

  Future<String> respond({required String to}) async {
    if (_isDisposed) {
      throw Exception('Cannot respond with a disposed LanguageModelSession');
    }

    try {
      final sessionId = await _initCompleter.future;
      final response = await _hostApi.respond(sessionId, to);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<GeneratedContent> respondWithSchema({
    required String to,
    required GenerationSchema schema,
  }) async {
    if (_isDisposed) {
      throw Exception('Cannot respond with a disposed LanguageModelSession');
    }

    try {
      final sessionId = await _initCompleter.future;
      final schemaJson = _convertToNullableKeys(schema.toJson());
      final response = await _hostApi.respondWithSchema(sessionId, to, schemaJson);
      return GeneratedContent(_cleanMapKeys(response));
    } catch (e) {
      rethrow;
    }
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
