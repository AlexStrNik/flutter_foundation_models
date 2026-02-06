# Flutter Foundation Models

[![pub package](https://img.shields.io/pub/v/flutter_foundation_models.svg)](https://pub.dev/packages/flutter_foundation_models)

A Flutter plugin providing a direct port of Apple's Foundation Models framework for on-device AI, available on iOS 26+ and macOS 26+.

## Design Philosophy

This package aims to be a **direct port of Swift's Foundation Models API** to Dart/Flutter. The API design mirrors Swift's native interfaces as closely as possible given Flutter's constraints:

| Swift | Dart |
|-------|------|
| `SystemLanguageModel.default` | `SystemLanguageModel.defaultModel` |
| `SystemLanguageModel(useCase:guardrails:)` | `SystemLanguageModel.create(useCase:guardrails:)` |
| `LanguageModelSession(model:tools:instructions:)` | `LanguageModelSession.create(model:tools:instructions:)` |
| `session.respond(to:)` → `Response<String>` | `session.respondTo()` → `TextResponse` |
| `session.respond(to:generating:)` → `Response<T>` | `session.respondToWithSchema()` → `StructuredResponse` |
| `session.streamResponse(to:)` | `session.streamResponseTo()` |
| `session.transcript` | `session.transcript` |
| `@Generable` macro | `@Generable()` annotation + codegen |
| `#Guide` macro | `@Guide()` annotation |

When learning this package, you can reference [Apple's Foundation Models documentation](https://developer.apple.com/documentation/foundationmodels) - the concepts translate directly.

## Features

- **Text Generation** - Generate natural language responses with `respondTo()`
- **Structured Output** - Generate typed Dart objects with `respondToWithSchema()`
- **List Generation** - Generate arrays of objects with `GenerationSchema.array()`
- **Streaming** - Real-time streaming for text and structured content
- **Tool Use** - Let the model call your Dart functions
- **Transcripts** - Access, persist, and restore conversation history
- **Generation Guides** - Constrain output with patterns, ranges, and enums
- **Model Configuration** - Custom adapters, use cases, and guardrails
- **Error Handling** - Typed exceptions matching Swift's `GenerationError`

## Requirements

- iOS 16.0+ / macOS (Foundation Models API requires iOS/macOS 26+ at runtime)
- Flutter 3.22+
- Xcode 26+ (for iOS/macOS 26 SDK)

**Note:** The package can be added to apps targeting iOS 16+, but the Foundation Models API is only available at runtime on iOS 26+. Use `SystemLanguageModel.isAvailable` to check availability.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_foundation_models: ^0.3.0

dev_dependencies:
  flutter_foundation_models_gen: ^0.1.0
  build_runner: ^2.4.0
```

## Quick Start

### Check Availability

```dart
import 'package:flutter_foundation_models/flutter_foundation_models.dart';

if (await SystemLanguageModel.isAvailable) {
  // Foundation Models is available
} else {
  // Not available - check detailed reason
  final availability = await SystemLanguageModel.availability;
  print('Unavailable: ${availability.unavailableReason}');
}
```

### Text Generation

```dart
final session = await LanguageModelSession.create();

final response = await session.respondTo("What is Flutter?");
print(response.content);  // The generated text
print(response.transcriptEntries.length);  // Entries created during this response

session.dispose();
```

### Structured Output

Define your data model with `@Generable`:

```dart
import 'package:flutter_foundation_models/flutter_foundation_models.dart';

part 'movie.g.dart';

@Generable(description: "A movie recommendation")
class Movie {
  @Guide(description: "The movie title")
  final String title;

  @Guide(description: "Release year")
  final int year;

  @Guide(description: "Brief plot summary")
  final String summary;

  Movie({required this.title, required this.year, required this.summary});
}
```

Run code generation:

```bash
dart run build_runner build
```

Generate structured content:

```dart
final session = await LanguageModelSession.create();

final response = await session.respondToWithSchema(
  "Recommend a sci-fi movie from the 1980s",
  schema: $MovieGenerable.generationSchema,
);

final movie = $MovieGenerable.fromGeneratedContent(response.content);
print('${movie.title} (${movie.year})');
print(movie.summary);

// Access raw content and transcript
print(response.rawContent);  // Pre-transformation content
print(response.transcriptEntries);  // Conversation entries
```

### Generating Lists

Generate multiple items using `GenerationSchema.array`:

```dart
final response = await session.respondToWithSchema(
  "Recommend 3 sci-fi movies",
  schema: GenerationSchema.array(
    $MovieGenerable.generationSchema,
    minimumElements: 3,
    maximumElements: 3,
  ),
);

final movies = response.content.toList($MovieGenerable.fromGeneratedContent);
for (final movie in movies) {
  print('${movie.title} (${movie.year})');
}
```

### Streaming

#### Text Streaming

```dart
final stream = session.streamResponseTo("Tell me a story");
stream.listen((text) {
  print(text);  // Progressively updates
});
```

#### Structured Streaming

```dart
final stream = session.streamResponseToWithSchema(
  "Generate a story",
  schema: $StoryGenerable.generationSchema,
);

stream.listen((partial) {
  final story = $StoryGenerable.fromPartialGeneratedContent(partial);
  print(story.title ?? "Loading title...");
  print(story.content ?? "Loading content...");
});
```

#### List Streaming

```dart
final stream = session.streamResponseToWithSchema(
  "Generate 3 movies",
  schema: GenerationSchema.array($MovieGenerable.generationSchema),
);

stream.listen((partial) {
  final movies = partial.toPartialList($MovieGenerable.fromPartialGeneratedContent);
  for (final movie in movies) {
    print(movie?.title ?? "Loading...");
  }
});
```

## Tool Use

Let the model call your Dart functions:

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
  WeatherResult({required this.city, required this.temperature, required this.condition});
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
print(response.content);  // Uses weather data in response
```

## Transcripts

Access and persist conversation history:

```dart
final session = await LanguageModelSession.create();

// Have a conversation
await session.respondTo("Hello!");
await session.respondTo("What's 2+2?");

// Get the transcript
final transcript = await session.transcript;
print('Conversation has ${transcript.length} entries');

// Iterate over entries
for (final entry in transcript.entries) {
  switch (entry) {
    case TranscriptPrompt(:final prompt):
      print('User: $prompt');
    case TranscriptResponse(:final content):
      print('Assistant: $content');
    case TranscriptToolCalls(:final toolCalls):
      print('Tool calls: ${toolCalls.length}');
    case TranscriptToolOutput(:final toolName, :final output):
      print('Tool $toolName returned: $output');
    case TranscriptInstructions(:final instructions):
      print('Instructions: $instructions');
    case TranscriptUnknown():
      print('Unknown entry type');
  }
}

// Serialize for storage
final json = transcript.toJson();

// Later, restore and continue the conversation
final restored = Transcript.fromJson(json);
final newSession = await LanguageModelSession.createWithTranscript(
  transcript: restored,
);
```

## Generation Guides

Constrain generated values with `@Guide`:

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
    description: "Tags",
    guides: [GenerationGuide.countRange(1, 5)],
  )
  final List<String> tags;

  Product({required this.name, required this.price, required this.category, required this.tags});
}
```

### Available Guides

| Guide | Description | Applies To |
|-------|-------------|------------|
| `constant(value)` | Exact string value | String |
| `anyOf(values)` | One of several string values | String |
| `pattern(regex)` | Regex pattern match | String |
| `minimum(value)` | Minimum numeric value | int, double |
| `maximum(value)` | Maximum numeric value | int, double |
| `range(min, max)` | Numeric value range | int, double |
| `minimumCount(n)` | Minimum element count | List |
| `maximumCount(n)` | Maximum element count | List |
| `count(n)` | Exact element count | List |
| `countRange(min, max)` | Element count range | List |
| `element(guide)` | Apply guide to list elements | List |

## Generation Options

Fine-tune generation behavior:

```dart
final options = GenerationOptions(
  sampling: TopPSamplingMode(probabilityThreshold: 0.9),
  temperature: 0.7,
  maximumResponseTokens: 500,
);

final response = await session.respondTo(
  "Write a creative story",
  options: options,
);
```

### Sampling Modes

| Mode | Description |
|------|-------------|
| `GreedySamplingMode()` | Deterministic, always picks most likely token |
| `TopKSamplingMode(k: 40)` | Sample from top K tokens |
| `TopPSamplingMode(probabilityThreshold: 0.9)` | Sample from tokens with cumulative probability p |

Add `seed` parameter to any sampling mode for reproducible results.

## Model Configuration

### System Instructions

```dart
final session = await LanguageModelSession.create(
  instructions: "You are a helpful cooking assistant. "
      "Provide recipes and cooking tips.",
);
```

### Use Cases

```dart
final model = await SystemLanguageModel.create(
  useCase: UseCase.contentTagging,  // or UseCase.general (default)
);

final session = await LanguageModelSession.create(model: model);

session.dispose();
model.dispose();
```

### Guardrails

```dart
final model = await SystemLanguageModel.create(
  guardrails: Guardrails.permissiveContentTransformations,
);
```

### Custom Adapters

```dart
// From a named adapter
final adapter = await Adapter.create(name: "my-adapter");

// Or from a Flutter asset
final adapter = await Adapter.fromAsset("assets/my-adapter.mlmodelc");

final model = await SystemLanguageModel.create(adapter: adapter);
final session = await LanguageModelSession.create(model: model);

// Dispose all resources
session.dispose();
model.dispose();
adapter.dispose();
```

## Session Optimization

### Prewarming

Reduce latency by prewarming the session before the user starts typing:

```dart
final session = await LanguageModelSession.create();

// Prewarm with no specific prefix
await session.prewarm();

// Or prewarm with a known prompt prefix
await session.prewarm(promptPrefix: "Translate to Spanish: ");
```

### Checking Session State

```dart
if (await session.isResponding) {
  print("Session is currently generating a response");
}
```

## Error Handling

Generation errors are thrown as `GenerationException`:

```dart
try {
  final response = await session.respondTo("...");
} on GenerationException catch (e) {
  switch (e.type) {
    case GenerationErrorType.exceededContextWindowSize:
      print("Context too long: ${e.message}");
    case GenerationErrorType.guardrailViolation:
      print("Content policy violation: ${e.message}");
    case GenerationErrorType.rateLimited:
      print("Rate limited: ${e.message}");
    case GenerationErrorType.refusal:
      print("Model refused: ${e.message}");
    default:
      print("Error: ${e.message}");
  }

  // Debug info if available
  if (e.debugDescription != null) {
    print("Debug: ${e.debugDescription}");
  }
}
```

### Error Types

| Type | Description |
|------|-------------|
| `exceededContextWindowSize` | Context window limit exceeded |
| `assetsUnavailable` | Required model assets unavailable |
| `guardrailViolation` | Content policy violated |
| `unsupportedGuide` | Unsupported generation guide used |
| `unsupportedLanguageOrLocale` | Language/locale not supported |
| `decodingFailure` | Failed to decode model response |
| `rateLimited` | Rate limit exceeded |
| `concurrentRequests` | Concurrent request limit exceeded |
| `refusal` | Model refused to generate |
| `unknown` | Unknown error |

## API Reference

### SystemLanguageModel

| Member | Description |
|--------|-------------|
| `SystemLanguageModel.isAvailable` | Check if API is available (static, async) |
| `SystemLanguageModel.availability` | Get detailed availability info (static, async) |
| `SystemLanguageModel.defaultModel` | The default system model (static) |
| `SystemLanguageModel.create()` | Create custom model (static, async) |
| `dispose()` | Release resources (no-op for defaultModel) |

### Adapter

| Member | Description |
|--------|-------------|
| `Adapter.create(name:)` | Create adapter by name (static, async) |
| `Adapter.fromAsset(path)` | Create adapter from Flutter asset (static, async) |
| `dispose()` | Release resources |

### LanguageModelSession

| Member | Description |
|--------|-------------|
| `LanguageModelSession.create()` | Create new session (static, async) |
| `LanguageModelSession.createWithTranscript()` | Create session from transcript (static, async) |
| `respondTo(prompt)` | Generate text → `TextResponse` |
| `streamResponseTo(prompt)` | Stream text → `Stream<String>` |
| `respondToWithSchema(prompt, schema:)` | Generate structured → `StructuredResponse` |
| `streamResponseToWithSchema(prompt, schema:)` | Stream structured → `Stream<GeneratedContent>` |
| `transcript` | Get conversation transcript (async) |
| `prewarm()` | Reduce latency for first request |
| `isResponding` | Check if currently generating (async) |
| `dispose()` | Release resources |

### Response Types

| Type | Properties |
|------|------------|
| `TextResponse` | `content`, `transcriptEntries` |
| `StructuredResponse` | `content`, `rawContent`, `transcriptEntries` |

### GenerationSchema

| Member | Description |
|--------|-------------|
| `GenerationSchema.array(schema)` | Create array schema from item schema |

### GeneratedContent

| Member | Description |
|--------|-------------|
| `toList(fromContent)` | Convert array content to typed `List<T>` |
| `toPartialList(fromPartialContent)` | Convert partial array for streaming |

### Generated Extensions

For a class `MyClass` annotated with `@Generable()`:

| Member | Description |
|--------|-------------|
| `$MyClassGenerable.generationSchema` | Schema for generation |
| `$MyClassGenerable.fromGeneratedContent(content)` | Convert to typed object |
| `$MyClassGenerable.fromPartialGeneratedContent(content)` | Convert partial (streaming) |
| `myInstance.toGeneratedContent()` | Convert instance to GeneratedContent |
| `$MyClassPartial` | Partial type for streaming (nullable fields) |

## Package Manager Support

This plugin supports both **Swift Package Manager** and **CocoaPods**. SPM is recommended for new projects and provides faster build times.

## License

MIT License
