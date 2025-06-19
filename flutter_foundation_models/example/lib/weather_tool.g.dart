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
}

extension $WeatherToolArgumentsConvertibleToGeneratedContent
    on WeatherToolArguments {
  GeneratedContent toGeneratedContent() {
    return GeneratedContent({
      "city": city,
    });
  }
}

extension $WeatherToolArgumentsConvertibleFromGeneratedContent
    on WeatherToolArguments {
  static WeatherToolArguments fromGeneratedContent(GeneratedContent content) {
    return WeatherToolArguments(
      city: content.value["city"] as String,
    );
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
          schema: ValueGenerationSchema(type: "Double"),
        ),
      ],
    );
    final dependencies = <DynamicGenerationSchema>[];
    return GenerationSchema(
      root: root,
      dependencies: dependencies,
    );
  }
}

extension $WeatherToolResultConvertibleToGeneratedContent on WeatherToolResult {
  GeneratedContent toGeneratedContent() {
    return GeneratedContent({
      "city": city,
      "temperature": temperature,
    });
  }
}

extension $WeatherToolResultConvertibleFromGeneratedContent
    on WeatherToolResult {
  static WeatherToolResult fromGeneratedContent(GeneratedContent content) {
    return WeatherToolResult(
      city: content.value["city"] as String,
      temperature: content.value["temperature"] as double,
    );
  }
}
