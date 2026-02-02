import 'package:meta/meta_meta.dart';

/// Marks a class or enum as generable by the Foundation Models.
///
/// Apply this annotation to classes and enums that should be usable
/// as structured output from the language model.
///
/// For classes, all final fields are included in the generated schema.
/// For enums, all enum values are included.
///
/// Example:
/// ```dart
/// @Generable(description: "A book recommendation")
/// class BookRecommendation {
///   @Guide(description: "The book title")
///   final String title;
///
///   @Guide(description: "The author's name")
///   final String author;
///
///   @Guide(description: "Rating from 1 to 5")
///   final int rating;
///
///   BookRecommendation({
///     required this.title,
///     required this.author,
///     required this.rating,
///   });
/// }
///
/// @Generable()
/// enum Genre { fiction, nonFiction, mystery, sciFi }
/// ```
///
/// The code generator creates:
/// - `$BookRecommendationGenerable` extension with schema and converters
/// - `$BookRecommendationPartial` class for streaming responses
/// - `$GenreGenerable` extension for the enum
@Target({TargetKind.classType, TargetKind.enumType})
final class Generable {
  /// Optional description of this type for the language model.
  ///
  /// This description helps the model understand what this type represents
  /// and when to use it.
  final String? description;

  /// Creates a Generable annotation.
  const Generable({this.description});
}

/// Provides guidance for a field in a @Generable class.
///
/// Use this annotation to describe fields and apply constraints
/// that guide the model's output.
///
/// Example:
/// ```dart
/// @Generable()
/// class Product {
///   @Guide(description: "Product name, max 50 characters")
///   final String name;
///
///   @Guide(
///     description: "Price in USD",
///     guides: [GenerationGuide.range(0.01, 10000)],
///   )
///   final double price;
///
///   @Guide(
///     description: "Product category",
///     guides: [GenerationGuide.anyOf(["electronics", "clothing", "food"])],
///   )
///   final String category;
///
///   Product({required this.name, required this.price, required this.category});
/// }
/// ```
@Target({TargetKind.field})
final class Guide {
  /// Description of this field for the language model.
  ///
  /// This helps the model understand what value to generate.
  final String? description;

  /// Constraints to apply to this field's generated value.
  ///
  /// See [GenerationGuide] for available constraint types.
  final List<GenerationGuide> guides;

  /// Creates a Guide annotation.
  const Guide({this.description, this.guides = const []});
}

/// Base class for generation guides that constrain output values.
///
/// Generation guides help the model produce valid output by specifying
/// constraints on what values are acceptable.
///
/// Available guides:
///
/// **String constraints:**
/// - [GenerationGuide.constant] - Exact string value
/// - [GenerationGuide.anyOf] - One of several string values
/// - [GenerationGuide.pattern] - Regex pattern match
///
/// **Numeric constraints (int, double):**
/// - [GenerationGuide.minimum] - Minimum value
/// - [GenerationGuide.maximum] - Maximum value
/// - [GenerationGuide.range] - Min and max values
///
/// **Array constraints (List):**
/// - [GenerationGuide.minimumCount] - Minimum element count
/// - [GenerationGuide.maximumCount] - Maximum element count
/// - [GenerationGuide.count] - Exact element count
/// - [GenerationGuide.countRange] - Element count range
/// - [GenerationGuide.element] - Constraint for each element
sealed class GenerationGuide {
  const GenerationGuide();

  /// Constrains a String field to an exact constant value.
  ///
  /// Example:
  /// ```dart
  /// @Guide(guides: [GenerationGuide.constant("USD")])
  /// final String currency;
  /// ```
  const factory GenerationGuide.constant(String value) = ConstantGuide;

  /// Constrains a String field to one of the specified values.
  ///
  /// Example:
  /// ```dart
  /// @Guide(guides: [GenerationGuide.anyOf(["small", "medium", "large"])])
  /// final String size;
  /// ```
  const factory GenerationGuide.anyOf(List<String> values) = AnyOfGuide;

  /// Constrains a String field to match a regex pattern.
  ///
  /// Example:
  /// ```dart
  /// @Guide(guides: [GenerationGuide.pattern(r'^\d{3}-\d{3}-\d{4}$')])
  /// final String phoneNumber;
  /// ```
  const factory GenerationGuide.pattern(String regex) = PatternGuide;

  /// Constrains a numeric field to a minimum value.
  ///
  /// Example:
  /// ```dart
  /// @Guide(guides: [GenerationGuide.minimum(0)])
  /// final int quantity;
  /// ```
  const factory GenerationGuide.minimum(num value) = MinimumGuide;

  /// Constrains a numeric field to a maximum value.
  ///
  /// Example:
  /// ```dart
  /// @Guide(guides: [GenerationGuide.maximum(100)])
  /// final int percentage;
  /// ```
  const factory GenerationGuide.maximum(num value) = MaximumGuide;

  /// Constrains a numeric field to a range of values.
  ///
  /// Example:
  /// ```dart
  /// @Guide(guides: [GenerationGuide.range(1, 5)])
  /// final int rating;
  /// ```
  const factory GenerationGuide.range(num min, num max) = RangeGuide;

  /// Constrains an array field to a minimum number of elements.
  ///
  /// Example:
  /// ```dart
  /// @Guide(guides: [GenerationGuide.minimumCount(1)])
  /// final List<String> tags;
  /// ```
  const factory GenerationGuide.minimumCount(int count) = MinimumCountGuide;

  /// Constrains an array field to a maximum number of elements.
  ///
  /// Example:
  /// ```dart
  /// @Guide(guides: [GenerationGuide.maximumCount(10)])
  /// final List<String> items;
  /// ```
  const factory GenerationGuide.maximumCount(int count) = MaximumCountGuide;

  /// Constrains an array field to an exact number of elements.
  ///
  /// Example:
  /// ```dart
  /// @Guide(guides: [GenerationGuide.count(3)])
  /// final List<String> topThree;
  /// ```
  const factory GenerationGuide.count(int count) = ExactCountGuide;

  /// Constrains an array field to a range of element counts.
  ///
  /// Example:
  /// ```dart
  /// @Guide(guides: [GenerationGuide.countRange(2, 5)])
  /// final List<String> options;
  /// ```
  const factory GenerationGuide.countRange(int min, int max) = CountRangeGuide;

  /// Applies a guide to each element of an array.
  ///
  /// Example:
  /// ```dart
  /// @Guide(guides: [
  ///   GenerationGuide.countRange(1, 5),
  ///   GenerationGuide.element(GenerationGuide.range(1, 100)),
  /// ])
  /// final List<int> scores;
  /// ```
  const factory GenerationGuide.element(GenerationGuide guide) = ElementGuide;
}

/// Constrains a String field to an exact constant value.
///
/// See [GenerationGuide.constant] for usage.
final class ConstantGuide extends GenerationGuide {
  /// The exact value the field must have.
  final String value;

  /// Creates a constant guide.
  const ConstantGuide(this.value);
}

/// Constrains a String field to one of the specified values.
///
/// See [GenerationGuide.anyOf] for usage.
final class AnyOfGuide extends GenerationGuide {
  /// The allowed values.
  final List<String> values;

  /// Creates an anyOf guide.
  const AnyOfGuide(this.values);
}

/// Constrains a String field to match a regex pattern.
///
/// See [GenerationGuide.pattern] for usage.
final class PatternGuide extends GenerationGuide {
  /// The regex pattern to match.
  final String regex;

  /// Creates a pattern guide.
  const PatternGuide(this.regex);
}

/// Constrains a numeric field to a minimum value.
///
/// See [GenerationGuide.minimum] for usage.
final class MinimumGuide extends GenerationGuide {
  /// The minimum allowed value.
  final num value;

  /// Creates a minimum guide.
  const MinimumGuide(this.value);
}

/// Constrains a numeric field to a maximum value.
///
/// See [GenerationGuide.maximum] for usage.
final class MaximumGuide extends GenerationGuide {
  /// The maximum allowed value.
  final num value;

  /// Creates a maximum guide.
  const MaximumGuide(this.value);
}

/// Constrains a numeric field to a range of values.
///
/// See [GenerationGuide.range] for usage.
final class RangeGuide extends GenerationGuide {
  /// The minimum allowed value.
  final num min;

  /// The maximum allowed value.
  final num max;

  /// Creates a range guide.
  const RangeGuide(this.min, this.max);
}

/// Constrains an array field to a minimum number of elements.
///
/// See [GenerationGuide.minimumCount] for usage.
final class MinimumCountGuide extends GenerationGuide {
  /// The minimum number of elements.
  final int count;

  /// Creates a minimum count guide.
  const MinimumCountGuide(this.count);
}

/// Constrains an array field to a maximum number of elements.
///
/// See [GenerationGuide.maximumCount] for usage.
final class MaximumCountGuide extends GenerationGuide {
  /// The maximum number of elements.
  final int count;

  /// Creates a maximum count guide.
  const MaximumCountGuide(this.count);
}

/// Constrains an array field to an exact number of elements.
///
/// See [GenerationGuide.count] for usage.
final class ExactCountGuide extends GenerationGuide {
  /// The exact number of elements required.
  final int count;

  /// Creates an exact count guide.
  const ExactCountGuide(this.count);
}

/// Constrains an array field to a range of element counts.
///
/// See [GenerationGuide.countRange] for usage.
final class CountRangeGuide extends GenerationGuide {
  /// The minimum number of elements.
  final int min;

  /// The maximum number of elements.
  final int max;

  /// Creates a count range guide.
  const CountRangeGuide(this.min, this.max);
}

/// Applies a guide to each element of an array.
///
/// See [GenerationGuide.element] for usage.
final class ElementGuide extends GenerationGuide {
  /// The guide to apply to each element.
  final GenerationGuide guide;

  /// Creates an element guide.
  const ElementGuide(this.guide);
}
