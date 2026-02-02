import 'dart:math';
import 'package:flutter_foundation_models/flutter_foundation_models.dart';

part 'weather_tool.g.dart';

@Generable()
class WeatherToolArguments {
  @Guide(description: "The city to get weather information for")
  final String city;

  WeatherToolArguments({
    required this.city,
  });
}

@Generable()
class WeatherToolResult {
  final String city;

  @Guide(
    description: "Temperature in Fahrenheit",
    guides: [GenerationGuide.range(-40, 140)],
  )
  final double temperature;

  @Guide(
    description: "Weather condition",
    guides: [GenerationGuide.anyOf(["sunny", "cloudy", "rainy", "snowy"])],
  )
  final String condition;

  WeatherToolResult({
    required this.city,
    required this.temperature,
    required this.condition,
  });
}

class WeatherTool extends Tool {
  @override
  String name = "getWeather";
  @override
  String description = "Retrieve the latest weather information for a city";

  @override
  Future<GeneratedContent> call(GeneratedContent arguments) async {
    final parsedArguments = $WeatherToolArgumentsGenerable.fromGeneratedContent(
      arguments,
    );

    final conditions = ["sunny", "cloudy", "rainy", "snowy"];

    return WeatherToolResult(
      city: parsedArguments.city,
      temperature: Random().nextDouble() * 100,
      condition: conditions[Random().nextInt(conditions.length)],
    ).toGeneratedContent();
  }

  @override
  GenerationSchema get parameters => $WeatherToolArgumentsGenerable.generationSchema;
}
