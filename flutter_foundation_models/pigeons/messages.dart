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

@HostApi()
abstract class FoundationModelsHostApi {
  @async
  String createSession(List<ToolDefinitionMessage> tools);

  @async
  void destroySession(String sessionId);

  @async
  String respond(String sessionId, String prompt);

  @async
  Map<String?, Object?> respondWithSchema(
    String sessionId,
    String prompt,
    Map<String?, Object?> schema,
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
