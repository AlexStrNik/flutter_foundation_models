# Flutter Foundation Models

[![pub package](https://img.shields.io/pub/v/flutter_foundation_models.svg)](https://pub.dev/packages/flutter_foundation_models)

A Flutter plugin providing a **direct port of Apple's Foundation Models framework** for on-device AI, available on iOS 26+ and macOS 26+.

## Design Philosophy

This package mirrors Swift's Foundation Models API as closely as possible. If you know Swift's API, you know this one:

| Swift | Dart |
|-------|------|
| `SystemLanguageModel.default` | `SystemLanguageModel.defaultModel` |
| `session.respond(to:)` → `Response<String>` | `session.respondTo()` → `TextResponse` |
| `session.respond(to:generating:)` → `Response<T>` | `session.respondToWithSchema()` → `StructuredResponse` |
| `@Generable` macro | `@Generable()` annotation + codegen |

Reference [Apple's Foundation Models documentation](https://developer.apple.com/documentation/foundationmodels) - the concepts translate directly.

## Packages

| Package | Description |
|---------|-------------|
| [flutter_foundation_models](flutter_foundation_models/) | Main Flutter plugin |
| [flutter_foundation_models_annotations](flutter_foundation_models_annotations/) | Annotations (`@Generable`, `@Guide`) |
| [flutter_foundation_models_gen](flutter_foundation_models_gen/) | Code generator for `@Generable` |

## Quick Start

```dart
import 'package:flutter_foundation_models/flutter_foundation_models.dart';

// Check availability
if (!await SystemLanguageModel.isAvailable) {
  print('Foundation Models not available');
  return;
}

// Text generation
final session = await LanguageModelSession.create();
final response = await session.respondTo("What is Flutter?");
print(response.content);

// Structured output
@Generable()
class Movie {
  @Guide(description: "Movie title")
  final String title;
  final int year;
  Movie({required this.title, required this.year});
}

final structured = await session.respondToWithSchema(
  "Recommend a movie",
  schema: $MovieGenerable.generationSchema,
);
final movie = $MovieGenerable.fromGeneratedContent(structured.content);

// List generation
final listResponse = await session.respondToWithSchema(
  "Recommend 3 movies",
  schema: GenerationSchema.array($MovieGenerable.generationSchema),
);
final movies = listResponse.content.toList($MovieGenerable.fromGeneratedContent);

session.dispose();
```

## Features

- **Text Generation** - `respondTo()` returns `TextResponse` with content and transcript
- **Structured Output** - `respondToWithSchema()` returns typed `StructuredResponse`
- **List Generation** - `GenerationSchema.array()` + `content.toList()`
- **Streaming** - `streamResponseTo()` and `streamResponseToWithSchema()`
- **Tool Use** - Let the model call your Dart functions
- **Transcripts** - Persist and restore conversation history
- **Generation Guides** - Constrain with patterns, ranges, enums
- **Model Configuration** - Adapters, use cases, guardrails
- **Error Handling** - Typed `GenerationException` matching Swift's errors

See the [main package README](flutter_foundation_models/README.md) for complete documentation.

## Example

Check out the [example app](flutter_foundation_models/example/) for demos of:
- Structured output generation
- Streaming with partial updates
- Tool use with function calling
- Transcript save/restore

## Requirements

- iOS 16.0+ (Foundation Models API requires iOS 26.0+ at runtime)
- Flutter 3.22+
- Xcode 26+ (for iOS 26 SDK)

Use `SystemLanguageModel.isAvailable` to check API availability at runtime.

## License

MIT
