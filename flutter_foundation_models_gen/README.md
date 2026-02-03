# Flutter Foundation Models Generator

Code generator for [flutter_foundation_models](https://pub.dev/packages/flutter_foundation_models).

This package generates serialization code for classes and enums annotated with `@Generable`.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_foundation_models: ^0.1.0

dev_dependencies:
  flutter_foundation_models_gen: ^0.1.0
  build_runner: ^2.4.0
```

## Usage

1. Annotate your classes with `@Generable`:

```dart
import 'package:flutter_foundation_models/flutter_foundation_models.dart';

part 'movie.g.dart';

@Generable()
class Movie {
  @Guide(description: "The movie title")
  final String title;

  @Guide(description: "Release year")
  final int year;

  Movie({required this.title, required this.year});
}
```

2. Run the code generator:

```bash
dart run build_runner build
```

## Generated Code

For a class `Movie`, the generator creates:

### `$MovieGenerable` Extension

```dart
extension $MovieGenerable on Movie {
  // Schema for the language model
  static GenerationSchema get generationSchema { ... }

  // Deserialize from model output
  static Movie fromGeneratedContent(GeneratedContent content) { ... }

  // Deserialize partial content (for streaming)
  static $MoviePartial fromPartialGeneratedContent(GeneratedContent content) { ... }

  // Serialize to model input
  GeneratedContent toGeneratedContent() { ... }
}
```

### `$MoviePartial` Class

For streaming responses, all fields are nullable:

```dart
class $MoviePartial {
  final String? title;
  final int? year;

  $MoviePartial({this.title, this.year});
}
```

## Supported Types

- Primitives: `String`, `int`, `double`, `bool`
- Lists: `List<T>` where T is a supported type
- Enums: Must be annotated with `@Generable()`
- Nested classes: Must be annotated with `@Generable()`
- Optional fields: Nullable types (`String?`, etc.)

## License

MIT License
