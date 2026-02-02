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

/// Callback for when the tool is called
typedef WeatherToolCallback = void Function(String city);

class WeatherTool extends Tool {
  final double temperature;
  final String condition;
  final WeatherToolCallback? onCalled;

  WeatherTool({
    required this.temperature,
    required this.condition,
    this.onCalled,
  });

  @override
  String name = "getWeather";
  @override
  String description = "Retrieve the latest weather information for a city";

  @override
  Future<GeneratedContent> call(GeneratedContent arguments) async {
    final parsedArguments = $WeatherToolArgumentsGenerable.fromGeneratedContent(
      arguments,
    );

    onCalled?.call(parsedArguments.city);

    return WeatherToolResult(
      city: parsedArguments.city,
      temperature: temperature,
      condition: condition,
    ).toGeneratedContent();
  }

  @override
  GenerationSchema get parameters => $WeatherToolArgumentsGenerable.generationSchema;
}
