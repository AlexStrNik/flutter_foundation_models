import 'package:flutter_foundation_models/flutter_foundation_models.dart';

abstract class Tool {
  String get name;
  String get description;
  GenerationSchema get parameters;

  Future<GeneratedContent> call(GeneratedContent arguments);

  Map<String, dynamic> toJson() => {
        "name": name,
        "description": description,
        "parameters": parameters.toJson(),
      };
}
