import 'package:flutter/services.dart';
import 'package:flutter_foundation_models/flutter_foundation_models.dart';
import 'package:flutter_foundation_models/src/generation_schema.dart';

class LanguageModelSessionApi {
  static LanguageModelSessionApi? _instance;
  final MethodChannel _channel;

  LanguageModelSessionApi._() : _channel = const MethodChannel("flutter_foundation_models.LanguageModelSessionApi");

  static LanguageModelSessionApi instance = LanguageModelSessionApi._();

  Future<String> init({
    List<Tool> tools = const [],
  }) async {
    final uuid = await _channel.invokeMethod<String>(
      "init",
      {
        "tools": tools.map((tool) => tool.toJson()).toList(),
      },
    );

    if (uuid == null) {
      throw Exception("[LanguageModelSessionApi] Failed to create a LanguageModelSession");
    }

    return uuid;
  }

  Future<void> deinit({required String sessionId}) async {
    await _channel.invokeMethod(
      "deinit",
      {
        "sessionId": sessionId,
      },
    );
  }

  Future<dynamic> respondWithSchema({
    required String sessionId,
    required String prompt,
    required GenerationSchema schema,
  }) async {
    final result = await _channel.invokeMethod<dynamic>(
      "respondWithSchema",
      {
        "sessionId": sessionId,
        "prompt": prompt,
        "schema": schema.toJson(),
      },
    );

    if (result == null) {
      throw Exception("[LanguageModelSessionApi] Failed to respond to \"$prompt\"");
    }

    return result;
  }

  Future<dynamic> respond({
    required String sessionId,
    required String prompt,
  }) async {
    final result = await _channel.invokeMethod<dynamic>(
      "respond",
      {
        "sessionId": sessionId,
        "prompt": prompt,
      },
    );

    if (result == null) {
      throw Exception("[LanguageModelSessionApi] Failed to respond to \"$prompt\"");
    }

    return result;
  }
}
