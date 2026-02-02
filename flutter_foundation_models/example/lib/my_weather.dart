import 'package:flutter/material.dart';
import 'package:flutter_foundation_models/flutter_foundation_models.dart';
import 'package:flutter_foundation_models_example/weather_tool.dart';

class MyWeather extends StatefulWidget {
  const MyWeather({super.key});

  @override
  State<MyWeather> createState() => _MyWeatherState();
}

class _MyWeatherState extends State<MyWeather> {
  late LanguageModelSession _session;

  String? weather;

  @override
  void initState() {
    super.initState();

    _session = LanguageModelSession(
      tools: [WeatherTool()],
    );
  }

  Future<void> getWeather() async {
    final weatherResult = await _session.respondTo(
      "What is the weather like in New York?",
    );

    setState(() {
      weather = weatherResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: getWeather,
          child: const Text("Get weather"),
        ),
        if (weather != null) Text(weather!),
      ],
    );
  }
}
