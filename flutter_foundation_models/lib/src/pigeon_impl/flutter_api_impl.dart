import 'dart:async';

import 'package:flutter_foundation_models/flutter_foundation_models.dart';
import 'package:flutter_foundation_models/src/generated/foundation_models_api.g.dart';

/// Callback types for streaming
typedef StreamSnapshotCallback = void Function(GeneratedContent partialContent);
typedef StreamCompleteCallback = void Function(GeneratedContent finalContent);
typedef StreamErrorCallback = void Function(String errorCode, String errorMessage);

/// Holds callbacks for an active stream
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

class FlutterApiImpl implements FoundationModelsFlutterApi {
  FlutterApiImpl();

  final Map<String, Map<String, Tool>> _sessionTools = {};
  final Map<String, _StreamCallbacks> _streamCallbacks = {};

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

  /// Registers callbacks for a stream
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

  /// Unregisters callbacks for a stream
  void unregisterStream(String streamId) {
    _streamCallbacks.remove(streamId);
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
  void onStreamSnapshot(String streamId, Map<String?, Object?> partialContent) {
    final callbacks = _streamCallbacks[streamId];
    if (callbacks != null) {
      final cleanedContent = _cleanMapKeys(partialContent);
      callbacks.onSnapshot(GeneratedContent(cleanedContent));
    }
  }

  @override
  void onStreamComplete(String streamId, Map<String?, Object?> finalContent) {
    final callbacks = _streamCallbacks[streamId];
    if (callbacks != null) {
      final cleanedContent = _cleanMapKeys(finalContent);
      callbacks.onComplete(GeneratedContent(cleanedContent));
      _streamCallbacks.remove(streamId);
    }
  }

  @override
  void onStreamError(String streamId, String errorCode, String errorMessage) {
    final callbacks = _streamCallbacks[streamId];
    if (callbacks != null) {
      callbacks.onError(errorCode, errorMessage);
      _streamCallbacks.remove(streamId);
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
