# Flutter Foundation Models

[![pub package](https://img.shields.io/pub/v/flutter_foundation_models.svg)](https://pub.dev/packages/flutter_foundation_models)

A Flutter plugin for Apple's on-device Foundation Models framework. Provides text generation, structured output, streaming, and tool use capabilities.

## Packages

| Package | Description |
|---------|-------------|
| [flutter_foundation_models](flutter_foundation_models/) | Main Flutter plugin |
| [flutter_foundation_models_annotations](flutter_foundation_models_annotations/) | Annotations (@Generable, @Guide) |
| [flutter_foundation_models_gen](flutter_foundation_models_gen/) | Code generator for @Generable |

## Quick Start

```dart
import 'package:flutter_foundation_models/flutter_foundation_models.dart';

// Check availability first
if (!await SystemLanguageModel.isAvailable) {
  print('Foundation Models not available');
  return;
}

// Simple text generation
final session = await LanguageModelSession.create();
final response = await session.respondTo("What is Flutter?");

// Structured output
@Generable()
class Movie {
  @Guide(description: "Movie title")
  final String title;
  final int year;
  Movie({required this.title, required this.year});
}

final content = await session.respondToWithSchema(
  "Recommend a movie",
  schema: $MovieGenerable.generationSchema,
);
final movie = $MovieGenerable.fromGeneratedContent(content);

// Don't forget to dispose
session.dispose();
```

See the [main package README](flutter_foundation_models/README.md) for full documentation.

## Example

Check out the [example app](flutter_foundation_models/example/) for a complete demo with:
- Structured output generation
- Streaming with partial updates
- Tool use with user-configurable responses

## Requirements

- iOS 16.0+ (Foundation Models API requires iOS 26.0+ at runtime)
- Flutter 3.22+
- Xcode 26+ (for iOS 26 SDK)

Use `SystemLanguageModel.isAvailable` to check API availability at runtime.

## License

MIT
