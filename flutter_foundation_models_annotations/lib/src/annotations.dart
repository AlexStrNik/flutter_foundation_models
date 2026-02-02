import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType, TargetKind.enumType})
final class Generable {
  final String? description;

  const Generable({this.description});
}

@Target({TargetKind.field})
final class Guide {
  final String? description;
  final List<GenerationGuide> guides;

  const Guide({this.description, this.guides = const []});
}

/// Base class for generation guides that constrain output values.
sealed class GenerationGuide {
  const GenerationGuide();

  // String guides
  const factory GenerationGuide.constant(String value) = ConstantGuide;
  const factory GenerationGuide.anyOf(List<String> values) = AnyOfGuide;
  const factory GenerationGuide.pattern(String regex) = PatternGuide;

  // Numeric guides (int, double)
  const factory GenerationGuide.minimum(num value) = MinimumGuide;
  const factory GenerationGuide.maximum(num value) = MaximumGuide;
  const factory GenerationGuide.range(num min, num max) = RangeGuide;

  // Array guides
  const factory GenerationGuide.minimumCount(int count) = MinimumCountGuide;
  const factory GenerationGuide.maximumCount(int count) = MaximumCountGuide;
  const factory GenerationGuide.count(int count) = ExactCountGuide;
  const factory GenerationGuide.countRange(int min, int max) = CountRangeGuide;
  const factory GenerationGuide.element(GenerationGuide guide) = ElementGuide;
}

/// Constrains a String field to an exact constant value.
final class ConstantGuide extends GenerationGuide {
  final String value;
  const ConstantGuide(this.value);
}

/// Constrains a String field to one of the specified values.
final class AnyOfGuide extends GenerationGuide {
  final List<String> values;
  const AnyOfGuide(this.values);
}

/// Constrains a String field to match the specified regex pattern.
final class PatternGuide extends GenerationGuide {
  final String regex;
  const PatternGuide(this.regex);
}

/// Constrains a numeric field to a minimum value.
final class MinimumGuide extends GenerationGuide {
  final num value;
  const MinimumGuide(this.value);
}

/// Constrains a numeric field to a maximum value.
final class MaximumGuide extends GenerationGuide {
  final num value;
  const MaximumGuide(this.value);
}

/// Constrains a numeric field to a range of values.
final class RangeGuide extends GenerationGuide {
  final num min;
  final num max;
  const RangeGuide(this.min, this.max);
}

/// Constrains an array field to a minimum number of elements.
final class MinimumCountGuide extends GenerationGuide {
  final int count;
  const MinimumCountGuide(this.count);
}

/// Constrains an array field to a maximum number of elements.
final class MaximumCountGuide extends GenerationGuide {
  final int count;
  const MaximumCountGuide(this.count);
}

/// Constrains an array field to an exact number of elements.
final class ExactCountGuide extends GenerationGuide {
  final int count;
  const ExactCountGuide(this.count);
}

/// Constrains an array field to a range of element counts.
final class CountRangeGuide extends GenerationGuide {
  final int min;
  final int max;
  const CountRangeGuide(this.min, this.max);
}

/// Applies a guide to each element of an array.
final class ElementGuide extends GenerationGuide {
  final GenerationGuide guide;
  const ElementGuide(this.guide);
}
