# Flutter Foundation Models

A Flutter plugin for Apple's on-device Foundation Models, available on iOS 26+ and macOS 26+.

## Features

- **Text Generation** - Generate natural language responses
- **Structured Output** - Generate typed Dart objects with schema validation
- **Streaming** - Real-time streaming for progressive UI updates
- **Tool Use** - Let the model call your functions to fetch data or perform actions
- **Generation Guides** - Constrain output with patterns, ranges, and enums

## Requirements

- iOS 26.0+ or macOS 26.0+
- Flutter 3.22+
- Xcode 26+

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_foundation_models: ^0.1.0

dev_dependencies:
  flutter_foundation_models_gen: ^0.1.0
  build_runner: ^2.4.0
```

## Quick Start

### Basic Text Generation

```dart
import 'package:flutter_foundation_models/flutter_foundation_models.dart';

final session = LanguageModelSession();

final response = await session.respondTo("What is Flutter?");
print(response);

// Don't forget to dispose
session.dispose();
```

### Structured Output

Define your data model:

```dart
import 'package:flutter_foundation_models/flutter_foundation_models.dart';

part 'movie.g.dart';

@Generable()
class MovieRecommendation {
  @Guide(description: "The movie title")
  final String title;

  @Guide(description: "Release year")
  final int year;

  @Guide(description: "Brief plot summary")
  final String summary;

  MovieRecommendation({
    required this.title,
    required this.year,
    required this.summary,
  });
}
```

Run the code generator:

```bash
dart run build_runner build
```

Generate structured content:

```dart
final session = LanguageModelSession();

final content = await session.respondToWithSchema(
  "Recommend a sci-fi movie from the 1980s",
  schema: $MovieRecommendationGenerable.generationSchema,
);

final movie = $MovieRecommendationGenerable.fromGeneratedContent(content);
print('${movie.title} (${movie.year})');
print(movie.summary);
```

### Streaming

For real-time UI updates:

```dart
final stream = session.streamResponseToWithSchema(
  "Write a short story",
  schema: $StoryGenerable.generationSchema,
);

stream.listen((partialContent) {
  final partial = $StoryGenerable.fromPartialGeneratedContent(partialContent);
  // Update UI with partial.title, partial.content, etc.
  // Fields are nullable until fully generated
});
```

### Using Enums

```dart
@Generable()
enum Priority { low, medium, high, critical }

@Generable()
class Task {
  @Guide(description: "Task description")
  final String description;

  @Guide(description: "Priority level")
  final Priority priority;

  Task({required this.description, required this.priority});
}
```

### Generation Guides

Constrain generated values:

```dart
@Generable()
class Product {
  @Guide(description: "Product name")
  final String name;

  @Guide(
    description: "Price in USD",
    guides: [GenerationGuide.range(0.01, 10000)],
  )
  final double price;

  @Guide(
    description: "Category",
    guides: [GenerationGuide.anyOf(["electronics", "clothing", "food"])],
  )
  final String category;

  @Guide(
    description: "Tags for the product",
    guides: [GenerationGuide.countRange(1, 5)],
  )
  final List<String> tags;

  Product({
    required this.name,
    required this.price,
    required this.category,
    required this.tags,
  });
}
```

Available guides:

| Guide | Description | Applies To |
|-------|-------------|------------|
| `constant(value)` | Exact string value | String |
| `anyOf(values)` | One of several values | String |
| `pattern(regex)` | Regex pattern match | String |
| `minimum(value)` | Minimum value | int, double |
| `maximum(value)` | Maximum value | int, double |
| `range(min, max)` | Value range | int, double |
| `minimumCount(n)` | Min elements | List |
| `maximumCount(n)` | Max elements | List |
| `count(n)` | Exact element count | List |
| `countRange(min, max)` | Element count range | List |
| `element(guide)` | Apply guide to elements | List |

### Tool Use

Let the model call your functions:

```dart
// Define tool arguments
@Generable()
class WeatherArgs {
  @Guide(description: "City name")
  final String city;
  WeatherArgs({required this.city});
}

// Define tool result
@Generable()
class WeatherResult {
  final String city;
  final double temperature;
  final String condition;
  WeatherResult({
    required this.city,
    required this.temperature,
    required this.condition,
  });
}

// Implement the tool
class WeatherTool extends Tool {
  @override
  String name = "getWeather";

  @override
  String description = "Get current weather for a city";

  @override
  GenerationSchema get parameters => $WeatherArgsGenerable.generationSchema;

  @override
  Future<GeneratedContent> call(GeneratedContent arguments) async {
    final args = $WeatherArgsGenerable.fromGeneratedContent(arguments);

    // Fetch real weather data here...

    return WeatherResult(
      city: args.city,
      temperature: 72.0,
      condition: "sunny",
    ).toGeneratedContent();
  }
}

// Use the tool
final session = LanguageModelSession(
  tools: [WeatherTool()],
);

final response = await session.respondTo(
  "What's the weather like in San Francisco?",
);
// The model will call WeatherTool and use the result in its response
```

### Generation Options

Fine-tune generation behavior:

```dart
final options = GenerationOptions(
  sampling: SamplingMode.topP(0.9),
  temperature: 0.7,
  maximumResponseTokens: 500,
);

final response = await session.respondTo(
  "Write a creative story",
  options: options,
);
```

Sampling modes:
- `SamplingMode.greedy()` - Deterministic, always picks most likely token
- `SamplingMode.topK(k)` - Sample from top K tokens
- `SamplingMode.topP(p)` - Sample from tokens with cumulative probability p

### System Instructions

Provide context for the model:

```dart
final session = LanguageModelSession(
  instructions: "You are a helpful cooking assistant. "
      "Provide recipes and cooking tips. "
      "Always include preparation time and difficulty level.",
);
```

## API Reference

### LanguageModelSession

| Method | Description |
|--------|-------------|
| `respondTo(prompt)` | Generate text response |
| `respondToWithSchema(prompt, schema:)` | Generate structured content |
| `streamResponseToWithSchema(prompt, schema:)` | Stream structured content |
| `dispose()` | Release resources |

### Generated Extensions

For a class `MyClass` annotated with `@Generable()`:

| Member | Description |
|--------|-------------|
| `$MyClassGenerable.generationSchema` | Schema for generation |
| `$MyClassGenerable.fromGeneratedContent(content)` | Convert to typed object |
| `$MyClassGenerable.fromPartialGeneratedContent(content)` | Convert partial (streaming) |
| `myInstance.toGeneratedContent()` | Convert to GeneratedContent |
| `$MyClassPartial` | Partial class for streaming |

## License

MIT License
