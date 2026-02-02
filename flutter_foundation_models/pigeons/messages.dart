import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/generated/foundation_models_api.g.dart',
  swiftOut: 'ios/Classes/Generated/FoundationModelsApi.g.swift',
))
class ToolDefinitionMessage {
  ToolDefinitionMessage({
    required this.name,
    required this.description,
    required this.parameters,
  });

  final String name;
  final String description;
  final Map<String?, Object?> parameters;
}

/// Sampling mode for generation
enum SamplingModeType {
  greedy,
  topK,
  topP,
}

class SamplingModeMessage {
  SamplingModeMessage({
    required this.type,
    this.topK,
    this.probabilityThreshold,
    this.seed,
  });

  final SamplingModeType type;
  final int? topK;
  final double? probabilityThreshold;
  final int? seed;
}

class GenerationOptionsMessage {
  GenerationOptionsMessage({
    this.sampling,
    this.temperature,
    this.maximumResponseTokens,
  });

  final SamplingModeMessage? sampling;
  final double? temperature;
  final int? maximumResponseTokens;
}

@HostApi()
abstract class FoundationModelsHostApi {
  /// Checks if Foundation Models API is available on this device.
  /// Returns true if iOS 26+ and the FoundationModels framework is available.
  bool isAvailable();

  @async
  String createSession(List<ToolDefinitionMessage> tools, String? instructions);

  @async
  void destroySession(String sessionId);

  @async
  String respondTo(
    String sessionId,
    String prompt,
    GenerationOptionsMessage? options,
  );

  @async
  Map<String?, Object?> respondToWithSchema(
    String sessionId,
    String prompt,
    Map<String?, Object?> schema,
    bool includeSchemaInPrompt,
    GenerationOptionsMessage? options,
  );

  /// Starts a streaming response. Returns a stream ID.
  /// Snapshots will be sent via FlutterApi.onStreamSnapshot.
  /// Completion/error will be sent via FlutterApi.onStreamComplete/onStreamError.
  @async
  String streamResponseToWithSchema(
    String sessionId,
    String prompt,
    Map<String?, Object?> schema,
    bool includeSchemaInPrompt,
    GenerationOptionsMessage? options,
  );

  /// Cancels an active stream.
  @async
  void cancelStream(String streamId);
}

@FlutterApi()
abstract class FoundationModelsFlutterApi {
  @async
  Map<String?, Object?> invokeTool(
    String sessionId,
    String toolName,
    Map<String?, Object?> arguments,
  );

  /// Called when a new snapshot is available during streaming.
  void onStreamSnapshot(
    String streamId,
    Map<String?, Object?> partialContent,
  );

  /// Called when streaming completes successfully.
  void onStreamComplete(
    String streamId,
    Map<String?, Object?> finalContent,
  );

  /// Called when streaming fails.
  void onStreamError(
    String streamId,
    String errorCode,
    String errorMessage,
  );
}
