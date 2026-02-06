# Flutter Foundation Models Annotations

Annotations for [flutter_foundation_models](https://pub.dev/packages/flutter_foundation_models).

This package provides the `@Generable` and `@Guide` annotations - Dart equivalents of Swift's `@Generable` macro and `#Guide` expression macro from Apple's Foundation Models framework.

## Installation

This package is automatically included when you add `flutter_foundation_models` to your project. You typically don't need to add it directly.

## Swift to Dart Mapping

| Swift | Dart |
|-------|------|
| `@Generable` macro | `@Generable()` annotation |
| `#Guide("description")` | `@Guide(description: "...")` |
| `#Guide(range: 0...100)` | `@Guide(guides: [GenerationGuide.range(0, 100)])` |

## Usage

### @Generable

Mark classes and enums that should be usable as structured output:

```dart
import 'package:flutter_foundation_models/flutter_foundation_models.dart';

part 'movie.g.dart';

@Generable(description: "A movie recommendation")
class Movie {
  @Guide(description: "The movie title")
  final String title;

  @Guide(description: "Release year")
  final int year;

  Movie({required this.title, required this.year});
}

@Generable()
enum Genre { action, comedy, drama, sciFi }
```

### @Guide

Add descriptions and constraints to fields:

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

**String constraints:**
- `GenerationGuide.constant(value)` - Exact value
- `GenerationGuide.anyOf(values)` - One of several values
- `GenerationGuide.pattern(regex)` - Regex pattern

**Numeric constraints:**
- `GenerationGuide.minimum(value)` - Minimum value
- `GenerationGuide.maximum(value)` - Maximum value
- `GenerationGuide.range(min, max)` - Value range

**Array constraints:**
- `GenerationGuide.minimumCount(n)` - Minimum elements
- `GenerationGuide.maximumCount(n)` - Maximum elements
- `GenerationGuide.count(n)` - Exact count
- `GenerationGuide.countRange(min, max)` - Count range
- `GenerationGuide.element(guide)` - Apply guide to elements

## Code Generation

After adding annotations, run the code generator:

```bash
dart run build_runner build
```

This generates:
- `$ClassNameGenerable` extension with `generationSchema`, `fromGeneratedContent()`, `fromPartialGeneratedContent()`
- `$ClassNamePartial` class for streaming responses (all fields nullable)
- `toGeneratedContent()` extension method on instances

## License

MIT License
