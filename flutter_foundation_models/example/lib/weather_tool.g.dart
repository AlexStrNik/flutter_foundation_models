// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_tool.dart';

// **************************************************************************
// GenerableGenerator
// **************************************************************************

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

  GeneratedContent toGeneratedContent() {
    return GeneratedContent({
      "city": city,
    });
  }
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

  GeneratedContent toGeneratedContent() {
    return GeneratedContent({
      "city": city,
      "temperature": temperature,
      "condition": condition,
    });
  }
}
