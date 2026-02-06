import 'dart:async';
import 'dart:convert';

import 'package:flutter_foundation_models/flutter_foundation_models.dart';
import 'package:flutter_foundation_models/src/generated/foundation_models_api.g.dart';

/// Callback types for structured streaming
typedef StreamSnapshotCallback = void Function(GeneratedContent partialContent);
typedef StreamCompleteCallback = void Function(
  GeneratedContent finalContent,
  GeneratedContent rawContent,
  List<TranscriptEntry> transcriptEntries,
);
typedef StreamErrorCallback = void Function(String errorCode, String errorMessage);

/// Callback types for text streaming
typedef TextStreamUpdateCallback = void Function(String text);
typedef TextStreamCompleteCallback = void Function(
  String finalText,
  List<TranscriptEntry> transcriptEntries,
);

/// Holds callbacks for an active structured stream
class _StreamCallbacks {
  final StreamSnapshotCallback onSnapshot;
  final StreamCompleteCallback onComplete;
  final StreamErrorCallback onError;

  _StreamCallbacks({
    required this.onSnapshot,
    required this.onComplete,
    required this.onError,
  });
}

/// Holds callbacks for an active text stream
class _TextStreamCallbacks {
  final TextStreamUpdateCallback onUpdate;
  final TextStreamCompleteCallback onComplete;
  final StreamErrorCallback onError;

  _TextStreamCallbacks({
    required this.onUpdate,
    required this.onComplete,
    required this.onError,
  });
}

class FlutterApiImpl implements FoundationModelsFlutterApi {
  FlutterApiImpl();

  final Map<String, Map<String, Tool>> _sessionTools = {};
  final Map<String, _StreamCallbacks> _streamCallbacks = {};
  final Map<String, _TextStreamCallbacks> _textStreamCallbacks = {};

  void registerSession(String sessionId, List<Tool> tools) {
    final toolMap = <String, Tool>{};
    for (final tool in tools) {
      toolMap[tool.name] = tool;
    }
    _sessionTools[sessionId] = toolMap;
  }

  void unregisterSession(String sessionId) {
    _sessionTools.remove(sessionId);
  }

  /// Registers callbacks for a structured stream
  void registerStream(
    String streamId, {
    required StreamSnapshotCallback onSnapshot,
    required StreamCompleteCallback onComplete,
    required StreamErrorCallback onError,
  }) {
    _streamCallbacks[streamId] = _StreamCallbacks(
      onSnapshot: onSnapshot,
      onComplete: onComplete,
      onError: onError,
    );
  }

  /// Unregisters callbacks for a structured stream
  void unregisterStream(String streamId) {
    _streamCallbacks.remove(streamId);
  }

  /// Registers callbacks for a text stream
  void registerTextStream(
    String streamId, {
    required TextStreamUpdateCallback onUpdate,
    required TextStreamCompleteCallback onComplete,
    required StreamErrorCallback onError,
  }) {
    _textStreamCallbacks[streamId] = _TextStreamCallbacks(
      onUpdate: onUpdate,
      onComplete: onComplete,
      onError: onError,
    );
  }

  /// Unregisters callbacks for a text stream
  void unregisterTextStream(String streamId) {
    _textStreamCallbacks.remove(streamId);
  }

  @override
  Future<Map<String?, Object?>> invokeTool(
    String sessionId,
    String toolName,
    Map<String?, Object?> arguments,
  ) async {
    final tools = _sessionTools[sessionId];
    if (tools == null) {
      throw Exception('Session $sessionId not found');
    }

    final tool = tools[toolName];
    if (tool == null) {
      throw Exception('Tool $toolName not found in session $sessionId');
    }

    final cleanedArgs = _cleanMapKeys(arguments);
    final result = await tool.call(GeneratedContent(cleanedArgs));

    return _convertToNullableKeys(result.value);
  }

  @override
  void onTextStreamUpdate(String streamId, String text) {
    final callbacks = _textStreamCallbacks[streamId];
    if (callbacks != null) {
      callbacks.onUpdate(text);
    }
  }

  @override
  void onTextStreamComplete(String streamId, String finalText, String transcriptJson) {
    final callbacks = _textStreamCallbacks[streamId];
    if (callbacks != null) {
      final transcript = Transcript.fromJson(transcriptJson);
      callbacks.onComplete(finalText, transcript.entries);
      _textStreamCallbacks.remove(streamId);
    }
  }

  @override
  void onStreamSnapshot(String streamId, Map<String?, Object?> partialContent) {
    final callbacks = _streamCallbacks[streamId];
    if (callbacks != null) {
      final cleanedContent = _cleanMapKeys(partialContent);
      callbacks.onSnapshot(GeneratedContent(cleanedContent));
    }
  }

  @override
  void onStreamComplete(
    String streamId,
    Map<String?, Object?> finalContent,
    String rawContent,
    String transcriptJson,
  ) {
    final callbacks = _streamCallbacks[streamId];
    if (callbacks != null) {
      final cleanedContent = _cleanMapKeys(finalContent);
      final cleanedRawContent = _parseJsonString(rawContent);
      final transcript = Transcript.fromJson(transcriptJson);
      callbacks.onComplete(
        GeneratedContent(cleanedContent),
        GeneratedContent(cleanedRawContent),
        transcript.entries,
      );
      _streamCallbacks.remove(streamId);
    }
  }

  Map<String, dynamic> _parseJsonString(String json) {
    try {
      if (json.isEmpty) return {};
      final decoded = Map<String, dynamic>.from(
        const JsonDecoder().convert(json) as Map,
      );
      return decoded;
    } catch (_) {
      return {};
    }
  }

  @override
  void onStreamError(String streamId, String errorCode, String errorMessage) {
    // Check structured stream callbacks
    final callbacks = _streamCallbacks[streamId];
    if (callbacks != null) {
      callbacks.onError(errorCode, errorMessage);
      _streamCallbacks.remove(streamId);
      return;
    }

    // Check text stream callbacks
    final textCallbacks = _textStreamCallbacks[streamId];
    if (textCallbacks != null) {
      textCallbacks.onError(errorCode, errorMessage);
      _textStreamCallbacks.remove(streamId);
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

  Map<String?, Object?> _convertToNullableKeys(dynamic value) {
    if (value is Map) {
      final result = <String?, Object?>{};
      for (final entry in value.entries) {
        final key = entry.key?.toString();
        final val = entry.value;
        if (val is Map) {
          result[key] = _convertToNullableKeys(val);
        } else if (val is List) {
          result[key] = val.map((e) {
            if (e is Map) {
              return _convertToNullableKeys(e);
            }
            return e;
          }).toList();
        } else {
          result[key] = val;
        }
      }
      return result;
    }
    return {'value': value};
  }
}
