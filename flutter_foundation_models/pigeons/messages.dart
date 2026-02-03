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

/// Use case for the model
enum ModelUseCaseType {
  general,
  contentTagging,
}

/// Guardrails setting for the model
enum ModelGuardrailsType {
  defaultGuardrails,
  permissiveContentTransformations,
}

/// Configuration for creating a model
class ModelConfigurationMessage {
  ModelConfigurationMessage({
    this.adapterId,
    this.useCase,
    this.guardrails,
  });

  /// Internal adapter ID (from adapters map on Swift side)
  final String? adapterId;
  final ModelUseCaseType? useCase;
  final ModelGuardrailsType? guardrails;
}

/// Message for creating an adapter
class AdapterMessage {
  AdapterMessage({
    required this.adapterId,
    required this.name,
  });

  final String adapterId;
  final String name;
}

/// Model availability status
class ModelAvailabilityMessage {
  ModelAvailabilityMessage({
    required this.isAvailable,
    this.unavailableReason,
  });

  final bool isAvailable;
  final String? unavailableReason;
}

@HostApi()
abstract class FoundationModelsHostApi {
  /// Checks if Foundation Models API is available on this device.
  /// Returns true if iOS 26+ and the FoundationModels framework is available.
  bool isAvailable();

  /// Gets detailed availability information including reason if unavailable.
  ModelAvailabilityMessage getModelAvailability();

  /// Creates an adapter. Returns adapter ID.
  /// Either name or assetPath must be provided.
  @async
  String createAdapter(String? name, String? assetPath);

  /// Destroys an adapter by ID.
  @async
  void destroyAdapter(String adapterId);

  /// Creates a model with optional configuration.
  /// Returns a model ID.
  @async
  String createModel(ModelConfigurationMessage? configuration);

  /// Destroys a model by ID.
  @async
  void destroyModel(String modelId);

  /// Creates a session with the given model ID.
  @async
  String createSession(
    String modelId,
    List<ToolDefinitionMessage> tools,
    String? instructions,
  );

  @async
  void destroySession(String sessionId);

  /// Returns whether the session is currently responding.
  @async
  bool isSessionResponding(String sessionId);

  /// Prewarms the session with an optional prompt prefix.
  @async
  void prewarmSession(String sessionId, String? promptPrefix);

  @async
  String respondTo(
    String sessionId,
    String prompt,
    GenerationOptionsMessage? options,
  );

  /// Starts a text streaming response. Returns a stream ID.
  /// Updates will be sent via FlutterApi.onTextStreamUpdate.
  /// Completion will be sent via FlutterApi.onTextStreamComplete.
  @async
  String streamResponseTo(
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

  /// Called when new text is available during text streaming.
  void onTextStreamUpdate(
    String streamId,
    String text,
  );

  /// Called when text streaming completes successfully.
  void onTextStreamComplete(
    String streamId,
    String finalText,
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
