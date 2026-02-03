import 'package:flutter/material.dart';
import 'package:flutter_foundation_models/flutter_foundation_models.dart';
import 'package:flutter_foundation_models_example/weather_tool.dart';

class MyWeather extends StatefulWidget {
  const MyWeather({super.key});

  @override
  State<MyWeather> createState() => _MyWeatherState();
}

class _MyWeatherState extends State<MyWeather> {
  final _cityController = TextEditingController(text: "New York");

  // User-configurable weather values
  double _temperature = 72.0;
  String _condition = "sunny";

  // Tool call tracking
  String? _toolCalledWithCity;
  String? _llmResponse;
  bool _isLoading = false;

  static const _conditions = ["sunny", "cloudy", "rainy", "snowy"];

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _askAboutWeather() async {
    setState(() {
      _isLoading = true;
      _toolCalledWithCity = null;
      _llmResponse = null;
    });

    final session = await LanguageModelSession.create(
      tools: [
        WeatherTool(
          temperature: _temperature,
          condition: _condition,
          onCalled: (city) {
            setState(() {
              _toolCalledWithCity = city;
            });
          },
        ),
      ],
    );

    try {
      final response = await session.respondTo(
        "What is the weather like in ${_cityController.text}? "
        "Answer in the form of a haiku.",
      );

      setState(() {
        _llmResponse = response;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      session.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Configuration section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Configure Tool Response",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Set the values that the weather tool will return. "
                    "The LLM will use these exact values in its response, "
                    "proving it called the tool.",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Temperature slider
                  Text("Temperature: ${_temperature.toStringAsFixed(0)}°F"),
                  Slider(
                    value: _temperature,
                    min: -40,
                    max: 120,
                    divisions: 160,
                    label: "${_temperature.toStringAsFixed(0)}°F",
                    onChanged: (value) {
                      setState(() {
                        _temperature = value;
                      });
                    },
                  ),

                  const SizedBox(height: 8),

                  // Condition dropdown
                  Row(
                    children: [
                      const Text("Condition: "),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _condition,
                        items: _conditions.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _condition = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Query section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ask the LLM",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: "City",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _askAboutWeather,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("Ask about weather"),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Results section
          if (_toolCalledWithCity != null || _llmResponse != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Results",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_toolCalledWithCity != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Tool called with city: \"$_toolCalledWithCity\"",
                                style: TextStyle(color: Colors.green.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Tool returned:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text("  Temperature: ${_temperature.toStringAsFixed(0)}°F"),
                            Text("  Condition: $_condition"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_llmResponse != null) ...[
                      const Text(
                        "LLM Response:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_llmResponse!),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
