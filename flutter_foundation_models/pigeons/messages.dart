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
}

@FlutterApi()
abstract class FoundationModelsFlutterApi {
  @async
  Map<String?, Object?> invokeTool(
    String sessionId,
    String toolName,
    Map<String?, Object?> arguments,
  );
}
