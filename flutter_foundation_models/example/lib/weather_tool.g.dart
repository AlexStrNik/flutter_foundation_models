// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_tool.dart';

// **************************************************************************
// GenerableGenerator
// **************************************************************************

/// Partial version of [WeatherToolArguments] for streaming responses.
/// All fields are optional as they may not be fully generated yet.
class $WeatherToolArgumentsPartial {
  final String? city;

  $WeatherToolArgumentsPartial({
    this.city,
  });
}

extension $WeatherToolArgumentsGenerable on WeatherToolArguments {
  static GenerationSchema get generationSchema {
    final root = StructGenerationSchema(
      name: "WeatherToolArguments",
      properties: [
        DynamicGenerationSchemaProperty(
          name: "city",
          description: "The city to get weather information for",
          schema: ValueGenerationSchema(type: "String"),
        ),
      ],
    );
    final dependencies = <DynamicGenerationSchema>[];
    return GenerationSchema(
      root: root,
      dependencies: dependencies,
    );
  }

  static WeatherToolArguments fromGeneratedContent(GeneratedContent content) {
    return WeatherToolArguments(
      city: content.value["city"] as String,
    );
  }

  static $WeatherToolArgumentsPartial fromPartialGeneratedContent(
      GeneratedContent content) {
    return $WeatherToolArgumentsPartial(
      city: content.value["city"] != null
          ? content.value["city"] as String?
          : null,
    );
  }

  GeneratedContent toGeneratedContent() {
    return GeneratedContent({
      "city": city,
    });
  }
}

/// Partial version of [WeatherToolResult] for streaming responses.
/// All fields are optional as they may not be fully generated yet.
class $WeatherToolResultPartial {
  final String? city;
  final double? temperature;
  final String? condition;

  $WeatherToolResultPartial({
    this.city,
    this.temperature,
    this.condition,
  });
}

extension $WeatherToolResultGenerable on WeatherToolResult {
  static GenerationSchema get generationSchema {
    final root = StructGenerationSchema(
      name: "WeatherToolResult",
      properties: [
        DynamicGenerationSchemaProperty(
          name: "city",
          schema: ValueGenerationSchema(type: "String"),
        ),
        DynamicGenerationSchemaProperty(
          name: "temperature",
          description: "Temperature in Fahrenheit",
          schema:
              ValueGenerationSchema(type: "Double", minimum: -40, maximum: 140),
        ),
        DynamicGenerationSchemaProperty(
          name: "condition",
          description: "Weather condition",
          schema: ValueGenerationSchema(
              type: "String",
              enumValues: ["sunny", "cloudy", "rainy", "snowy"]),
        ),
      ],
    );
    final dependencies = <DynamicGenerationSchema>[];
    return GenerationSchema(
      root: root,
      dependencies: dependencies,
    );
  }

  static WeatherToolResult fromGeneratedContent(GeneratedContent content) {
    return WeatherToolResult(
      city: content.value["city"] as String,
      temperature: content.value["temperature"] as double,
      condition: content.value["condition"] as String,
    );
  }

  static $WeatherToolResultPartial fromPartialGeneratedContent(
      GeneratedContent content) {
    return $WeatherToolResultPartial(
      city: content.value["city"] != null
          ? content.value["city"] as String?
          : null,
      temperature: content.value["temperature"] != null
          ? content.value["temperature"] as double?
          : null,
      condition: content.value["condition"] != null
          ? content.value["condition"] as String?
          : null,
    );
  }

  GeneratedContent toGeneratedContent() {
    return GeneratedContent({
      "city": city,
      "temperature": temperature,
      "condition": condition,
    });
  }
}
