import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_foundation_models/api/language_model_session_api.dart';
import 'package:flutter_foundation_models/flutter_foundation_models.dart';

final class LanguageModelSession {
  final List<Tool> tools;

  final Map<String, Tool> _toolMap = {};

  late MethodChannel _toolChannel;

  LanguageModelSession({
    this.tools = const [],
  }) {
    for (final tool in tools) {
      if (_toolMap.containsKey(tool.name)) {
        throw Exception("Tool with name ${tool.name} already exists");
      }
      _toolMap[tool.name] = tool;
    }

    _initInBackground();
  }

  final Completer<String> _initCompleter = Completer<String>();
  bool _isDisposed = false;

  Future<void> _initInBackground() async {
    try {
      final uuid = await LanguageModelSessionApi.instance.init(
        tools: tools,
      );
      _toolChannel = MethodChannel("flutter_foundation_models.ToolChannel.$uuid");
      _toolChannel.setMethodCallHandler(_handleToolCall);
      _initCompleter.complete(uuid);
    } catch (e) {
      _initCompleter.completeError(e);
    }
  }

  Future<dynamic> _handleToolCall(MethodCall call) async {
    final tool = _toolMap[call.method];
    if (tool == null) {
      throw Exception("Tool with name ${call.method} not found");
    }

    final result = await tool.call(
      GeneratedContent(
        call.arguments,
      ),
    );
    return result.value;
  }

  Future<void> dispose() async {
    if (_isDisposed) return;

    try {
      final uuid = await _initCompleter.future;
      await LanguageModelSessionApi.instance.deinit(sessionId: uuid);
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
      final uuid = await _initCompleter.future;
      final response = await LanguageModelSessionApi.instance.respond(
        sessionId: uuid,
        prompt: to,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<GeneratedContent> respondWithSchema({required String to, required GenerationSchema schema}) async {
    if (_isDisposed) {
      throw Exception('Cannot respond with a disposed LanguageModelSession');
    }

    try {
      final uuid = await _initCompleter.future;
      final response = await LanguageModelSessionApi.instance.respondWithSchema(
        sessionId: uuid,
        prompt: to,
        schema: schema,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }
}
