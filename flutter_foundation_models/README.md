# Flutter Foundation Models

[![pub package](https://img.shields.io/pub/v/flutter_foundation_models.svg)](https://pub.dev/packages/flutter_foundation_models)

A Flutter plugin for Apple's on-device Foundation Models, available on iOS 26+ and macOS 26+.

## Features

- **Text Generation** - Generate natural language responses
- **Structured Output** - Generate typed Dart objects with schema validation
- **Streaming** - Real-time streaming for progressive UI updates (text and structured)
- **Tool Use** - Let the model call your functions to fetch data or perform actions
- **Generation Guides** - Constrain output with patterns, ranges, and enums
- **Model Configuration** - Custom adapters, use cases, and guardrails

## Requirements

- iOS 16.0+ (Foundation Models API requires iOS 26.0+ at runtime)
- Flutter 3.22+
- Xcode 26+ (for iOS 26 SDK)

**Note:** The package can be added to apps targeting iOS 16+, but the Foundation Models API is only available on iOS 26+. Use `SystemLanguageModel.isAvailable` to check availability at runtime.

## Package Manager Support

This plugin supports both **Swift Package Manager** and **CocoaPods**. SPM is recommended for new projects and provides faster build times.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_foundation_models: ^0.2.0

dev_dependencies:
  flutter_foundation_models_gen: ^0.1.0
  build_runner: ^2.4.0
```

## Quick Start

### Check Availability

Before using Foundation Models, check if the API is available:

```dart
import 'package:flutter_foundation_models/flutter_foundation_models.dart';

if (await SystemLanguageModel.isAvailable) {
  // Foundation Models is available, show AI features
} else {
  // Not available, hide AI features or show fallback
}

// For detailed availability info:
final availability = await SystemLanguageModel.availability;
if (!availability.isAvailable) {
  print('Unavailable: ${availability.unavailableReason}');
}
```

### Basic Text Generation

```dart
import 'package:flutter_foundation_models/flutter_foundation_models.dart';

// Check availability first
if (!await SystemLanguageModel.isAvailable) {
  print('Foundation Models not available on this device');
  return;
}

final session = await LanguageModelSession.create();

final response = await session.respondTo("What is Flutter?");
print(response);

// Don't forget to dispose
session.dispose();
```

### Text Streaming

For real-time text output:

```dart
final session = await LanguageModelSession.create();

final stream = session.streamResponseTo("Tell me a joke");
stream.listen((text) {
  print(text); // Progressively prints as text is generated
});
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
final session = await LanguageModelSession.create();

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
final session = await LanguageModelSession.create(
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
final session = await LanguageModelSession.create(
  instructions: "You are a helpful cooking assistant. "
      "Provide recipes and cooking tips. "
      "Always include preparation time and difficulty level.",
);
```

### Model Configuration

Configure the language model with custom settings:

```dart
// Use a specific use case
final model = await SystemLanguageModel.create(
  useCase: UseCase.contentTagging,
);

// Or with custom guardrails
final model = await SystemLanguageModel.create(
  guardrails: Guardrails.permissiveContentTransformations,
);

// Create session with custom model
final session = await LanguageModelSession.create(model: model);

// Don't forget to dispose both
session.dispose();
model.dispose();
```

### Custom Adapters

Load custom adapters for specialized models:

```dart
// From a named adapter
final adapter = await Adapter.create(name: "my-adapter");

// Or from a Flutter asset
final adapter = await Adapter.fromAsset("assets/my-adapter.mlmodelc");

final model = await SystemLanguageModel.create(adapter: adapter);
final session = await LanguageModelSession.create(model: model);

// Dispose when done
session.dispose();
model.dispose();
adapter.dispose();
```

### Session Optimization

Reduce latency with prewarming:

```dart
final session = await LanguageModelSession.create();

// Prewarm the session before the user starts typing
await session.prewarm();

// Or prewarm with a known prompt prefix
await session.prewarm(promptPrefix: "Translate to Spanish: ");

// Check if session is currently generating
if (await session.isResponding) {
  print("Session is busy");
}
```

## API Reference

### SystemLanguageModel

| Member | Description |
|--------|-------------|
| `SystemLanguageModel.isAvailable` | Check if API is available (static) |
| `SystemLanguageModel.availability` | Get detailed availability info (static) |
| `SystemLanguageModel.defaultModel` | Access the default model (static) |
| `SystemLanguageModel.create()` | Create model with configuration (static) |
| `dispose()` | Release resources |

### Adapter

| Member | Description |
|--------|-------------|
| `Adapter.create(name:)` | Create adapter by name (static) |
| `Adapter.fromAsset(assetPath)` | Create adapter from Flutter asset (static) |
| `dispose()` | Release resources |

### LanguageModelSession

| Member | Description |
|--------|-------------|
| `LanguageModelSession.create()` | Create a new session (static) |
| `respondTo(prompt)` | Generate text response |
| `streamResponseTo(prompt)` | Stream text response |
| `respondToWithSchema(prompt, schema:)` | Generate structured content |
| `streamResponseToWithSchema(prompt, schema:)` | Stream structured content |
| `prewarm()` | Reduce latency for first request |
| `isResponding` | Check if session is generating |
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
