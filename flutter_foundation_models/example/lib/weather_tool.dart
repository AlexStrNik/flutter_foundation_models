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
  final double temperature;

  WeatherToolResult({
    required this.city,
    required this.temperature,
  });
}

class WeatherTool extends Tool {
  @override
  String name = "getWeather";
  @override
  String description = "Retrieve the latest weather information for a city";

  @override
  Future<GeneratedContent> call(GeneratedContent arguments) async {
    final parsedArguments = $WeatherToolArgumentsConvertibleFromGeneratedContent.fromGeneratedContent(
      arguments,
    );

    return WeatherToolResult(
      city: parsedArguments.city,
      temperature: Random().nextDouble() * 100,
    ).toGeneratedContent();
  }

  @override
  GenerationSchema get parameters => $WeatherToolArgumentsGenerable.generationSchema;
}
