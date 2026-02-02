import 'dart:async';

import 'package:flutter_foundation_models/flutter_foundation_models.dart';
import 'package:flutter_foundation_models/src/generated/foundation_models_api.g.dart';
import 'package:flutter_foundation_models/src/pigeon_impl/flutter_api_impl.dart';

/// A session for interacting with Apple's on-device Foundation Models.
///
/// [LanguageModelSession] provides methods to generate text responses and
/// structured content using Apple's on-device language model. It supports
/// both one-shot and streaming generation, as well as tool use.
///
/// Before creating a session, check if the API is available:
/// ```dart
/// if (await LanguageModelSession.isAvailable()) {
///   final session = LanguageModelSession();
///   // Use session...
/// } else {
///   // Foundation Models not available on this device
/// }
/// ```
///
/// Example usage:
/// ```dart
/// final session = LanguageModelSession();
///
/// // Simple text response
/// final response = await session.respondTo("What is Flutter?");
///
/// // Structured output with schema
/// final content = await session.respondToWithSchema(
///   "Generate a user profile",
///   schema: $UserProfileGenerable.generationSchema,
/// );
/// final profile = $UserProfileGenerable.fromGeneratedContent(content);
///
/// // Don't forget to dispose when done
/// session.dispose();
/// ```
///
/// For tool use, pass tools to the constructor:
/// ```dart
/// final session = LanguageModelSession(
///   tools: [WeatherTool(), CalculatorTool()],
/// );
/// ```
final class LanguageModelSession {
  /// Checks if the Foundation Models API is available on this device.
  ///
  /// Returns `true` if the device is running iOS 26+ (or macOS 26+) and
  /// the FoundationModels framework is available.
  ///
  /// Use this to conditionally enable AI features in your app:
  /// ```dart
  /// if (await LanguageModelSession.isAvailable()) {
  ///   // Show AI-powered features
  /// } else {
  ///   // Hide or disable AI features
  /// }
  /// ```
  static Future<bool> isAvailable() async {
    try {
      return await _hostApi.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Tools available for the model to use during generation.
  ///
  /// Tools allow the model to call external functions to retrieve information
  /// or perform actions. The model will automatically call tools when needed
  /// based on the user's prompt.
  final List<Tool> tools;

  /// System instructions that guide the model's behavior.
  ///
  /// Instructions provide context and guidelines for how the model should
  /// respond. They are included at the beginning of the conversation.
  final String? instructions;

  static final FlutterApiImpl _flutterApiImpl = FlutterApiImpl();
  static bool _flutterApiSetUp = false;

  static final FoundationModelsHostApi _hostApi = FoundationModelsHostApi();

  /// Creates a new language model session.
  ///
  /// [tools] - Optional list of tools the model can use.
  /// [instructions] - Optional system instructions for the model.
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
  final Set<String> _activeStreams = {};

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

  /// Disposes the session and releases resources.
  ///
  /// Always call this method when you're done using the session to free
  /// native resources. After disposal, the session cannot be used again.
  Future<void> dispose() async {
    if (_isDisposed) return;

    // Cancel all active streams
    for (final streamId in _activeStreams.toList()) {
      try {
        await _hostApi.cancelStream(streamId);
      } catch (_) {}
      _flutterApiImpl.unregisterStream(streamId);
    }
    _activeStreams.clear();

    try {
      final sessionId = await _initCompleter.future;
      _flutterApiImpl.unregisterSession(sessionId);
      await _hostApi.destroySession(sessionId);
      _isDisposed = true;
    } catch (e) {
      rethrow;
    }
  }

  /// Generates a text response for the given prompt.
  ///
  /// This method sends the [prompt] to the language model and returns
  /// the generated text response. If tools are configured, the model
  /// may call them to gather information before responding.
  ///
  /// [prompt] - The user's input prompt.
  /// [options] - Optional generation options for controlling output.
  ///
  /// Returns the generated text response.
  ///
  /// Throws an [Exception] if the session has been disposed.
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

  /// Generates structured content according to a schema.
  ///
  /// This method sends the [prompt] to the language model and returns
  /// content that conforms to the provided [schema]. Use this for generating
  /// typed data structures like objects, lists, and enums.
  ///
  /// [prompt] - The user's input prompt.
  /// [schema] - The schema defining the structure of the output.
  /// [includeSchemaInPrompt] - Whether to include schema description in the prompt.
  /// [options] - Optional generation options for controlling output.
  ///
  /// Returns [GeneratedContent] that can be converted to typed objects.
  ///
  /// Example:
  /// ```dart
  /// final content = await session.respondToWithSchema(
  ///   "Generate a novel idea",
  ///   schema: $NovelIdeaGenerable.generationSchema,
  /// );
  /// final novelIdea = $NovelIdeaGenerable.fromGeneratedContent(content);
  /// ```
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

  /// Streams structured content as it's generated.
  ///
  /// Similar to [respondToWithSchema], but returns a [Stream] that emits
  /// partial content as the model generates it. This allows showing
  /// progressive updates in the UI.
  ///
  /// [prompt] - The user's input prompt.
  /// [schema] - The schema defining the structure of the output.
  /// [includeSchemaInPrompt] - Whether to include schema description in the prompt.
  /// [options] - Optional generation options for controlling output.
  ///
  /// Returns a [Stream] of [GeneratedContent] with partial results.
  ///
  /// Example:
  /// ```dart
  /// final stream = session.streamResponseToWithSchema(
  ///   "Generate a novel idea",
  ///   schema: $NovelIdeaGenerable.generationSchema,
  /// );
  ///
  /// stream.listen((partialContent) {
  ///   final partial = $NovelIdeaGenerable.fromPartialGeneratedContent(partialContent);
  ///   print('Title so far: ${partial.title ?? "..."}');
  /// });
  /// ```
  Stream<GeneratedContent> streamResponseToWithSchema(
    String prompt, {
    required GenerationSchema schema,
    bool includeSchemaInPrompt = true,
    GenerationOptions? options,
  }) {
    if (_isDisposed) {
      throw Exception('Cannot stream with a disposed LanguageModelSession');
    }

    // Create a stream controller to emit snapshots
    late StreamController<GeneratedContent> controller;

    controller = StreamController<GeneratedContent>(
      onCancel: () async {
        // When the stream subscription is cancelled, cancel the native stream
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

    // Start the stream asynchronously
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
      final sessionId = await _initCompleter.future;
      final schemaJson = _convertToNullableKeys(schema.toJson());

      final streamId = await _hostApi.streamResponseToWithSchema(
        sessionId,
        prompt,
        schemaJson,
        includeSchemaInPrompt,
        _convertOptions(options),
      );

      _activeStreams.add(streamId);

      // Register callbacks to receive stream events
      _flutterApiImpl.registerStream(
        streamId,
        onSnapshot: (partialContent) {
          if (!controller.isClosed) {
            controller.add(partialContent);
          }
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
