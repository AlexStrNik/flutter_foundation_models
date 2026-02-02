/// Defines the structure for generated content output.
///
/// [GenerationSchema] describes what type of content the model should generate.
/// It consists of a root schema and optional dependencies for complex types.
///
/// Typically, you don't create these manually. Instead, use the @Generable
/// annotation and the generated `generationSchema` getter:
///
/// ```dart
/// @Generable()
/// class UserProfile {
///   final String name;
///   final int age;
///   UserProfile({required this.name, required this.age});
/// }
///
/// // Use the generated schema
/// final schema = $UserProfileGenerable.generationSchema;
/// ```
final class GenerationSchema {
  /// The root schema defining the top-level structure.
  DynamicGenerationSchema root;

  /// Additional schema definitions for nested types.
  List<DynamicGenerationSchema> dependencies;

  /// Creates a generation schema.
  GenerationSchema({
    required this.root,
    required this.dependencies,
  });

  /// Converts this schema to JSON for the native API.
  Map<String, dynamic> toJson() => {
        "root": root.toJson(),
        "dependencies": dependencies.map((e) => e.toJson()).toList(),
      };
}

/// Base class for dynamic generation schema types.
///
/// Subclasses define different kinds of schemas:
/// - [ValueGenerationSchema] - Primitive types (String, int, double, bool)
/// - [ArrayGenerationSchema] - Lists of values
/// - [StructGenerationSchema] - Objects with named properties
/// - [AnyOfGenerationSchema] - Union types (one of several schemas)
/// - [AnyOfStringsGenerationSchema] - Enum-like string values
sealed class DynamicGenerationSchema {
  /// Converts this schema to JSON.
  Map<String, dynamic> toJson();
}

/// Schema for primitive value types.
///
/// Supports String, Int, Double, and Bool types with optional constraints.
///
/// Constraints can be applied using the @Guide annotation:
/// ```dart
/// @Guide(guides: [GenerationGuide.range(0, 100)])
/// final int score;
///
/// @Guide(guides: [GenerationGuide.pattern(r'^\d{3}-\d{4}$')])
/// final String phoneNumber;
/// ```
final class ValueGenerationSchema extends DynamicGenerationSchema {
  /// The type name: "String", "Int", "Double", or "Bool".
  final String type;

  /// For constant/anyOf string constraints.
  final List<String>? enumValues;

  /// For regex pattern constraint on strings.
  final String? pattern;

  /// For numeric minimum constraint.
  final num? minimum;

  /// For numeric maximum constraint.
  final num? maximum;

  /// Creates a value schema.
  ValueGenerationSchema({
    required this.type,
    this.enumValues,
    this.pattern,
    this.minimum,
    this.maximum,
  });

  @override
  Map<String, dynamic> toJson() => {
        "kind": "ValueGenerationSchema",
        "type": type,
        if (enumValues != null) "enum": enumValues,
        if (pattern != null) "pattern": pattern,
        if (minimum != null) "minimum": minimum,
        if (maximum != null) "maximum": maximum,
      };
}

/// Schema for array/list types.
///
/// Defines a list where each element conforms to [arrayOf] schema.
///
/// Element count can be constrained using @Guide:
/// ```dart
/// @Guide(guides: [GenerationGuide.countRange(1, 5)])
/// final List<String> tags;
/// ```
final class ArrayGenerationSchema extends DynamicGenerationSchema {
  /// The schema for array elements.
  final DynamicGenerationSchema arrayOf;

  /// Minimum number of elements (optional).
  final int? minimumElements;

  /// Maximum number of elements (optional).
  final int? maximumElements;

  /// Creates an array schema.
  ArrayGenerationSchema({
    required this.arrayOf,
    this.minimumElements,
    this.maximumElements,
  });

  @override
  Map<String, dynamic> toJson() => {
        "kind": "ArrayGenerationSchema",
        "arrayOf": arrayOf.toJson(),
        if (minimumElements != null) "minimumElements": minimumElements,
        if (maximumElements != null) "maximumElements": maximumElements,
      };
}

/// Schema for union types (one of several possible schemas).
///
/// Used for sealed class hierarchies or discriminated unions.
final class AnyOfGenerationSchema extends DynamicGenerationSchema {
  /// The name of this union type.
  final String name;

  /// Optional description for the model.
  String? description;

  /// The possible schemas this type can be.
  final List<DynamicGenerationSchema> anyOf;

  /// Creates an anyOf schema.
  AnyOfGenerationSchema({
    required this.name,
    this.description,
    required this.anyOf,
  });

  @override
  Map<String, dynamic> toJson() => {
        "kind": "AnyOfGenerationSchema",
        "name": name,
        if (description != null) "description": description,
        "anyOf": anyOf.map((e) => e.toJson()).toList(),
      };
}

/// Schema for enum-like string values.
///
/// Used for Dart enums, mapping enum values to their string names.
///
/// ```dart
/// @Generable()
/// enum Priority { low, medium, high }
/// ```
final class AnyOfStringsGenerationSchema extends DynamicGenerationSchema {
  /// The name of this enum type.
  final String name;

  /// Optional description for the model.
  String? description;

  /// The allowed string values.
  final List<String> anyOf;

  /// Creates a string enum schema.
  AnyOfStringsGenerationSchema({
    required this.name,
    this.description,
    required this.anyOf,
  });

  @override
  Map<String, dynamic> toJson() => {
        "kind": "AnyOfStringsGenerationSchema",
        "name": name,
        if (description != null) "description": description,
        "anyOf": anyOf.toList(),
      };
}

/// Schema for structured objects with named properties.
///
/// Generated automatically for classes annotated with @Generable.
///
/// ```dart
/// @Generable(description: "A user profile")
/// class UserProfile {
///   @Guide(description: "The user's full name")
///   final String name;
///
///   @Guide(description: "Age in years")
///   final int age;
///
///   UserProfile({required this.name, required this.age});
/// }
/// ```
final class StructGenerationSchema extends DynamicGenerationSchema {
  /// The name of this struct type.
  final String name;

  /// Optional description for the model.
  final String? description;

  /// The properties of this struct.
  final List<DynamicGenerationSchemaProperty> properties;

  /// Creates a struct schema.
  StructGenerationSchema({
    required this.name,
    this.description,
    required this.properties,
  });

  @override
  Map<String, dynamic> toJson() => {
        "kind": "StructGenerationSchema",
        "name": name,
        if (description != null) "description": description,
        "properties": properties.map((e) => e.toJson()).toList(),
      };
}

/// A property definition within a [StructGenerationSchema].
final class DynamicGenerationSchemaProperty {
  /// The property name.
  final String name;

  /// Optional description for the model.
  final String? description;

  /// The schema for this property's value.
  final DynamicGenerationSchema schema;

  /// Whether this property is optional (nullable).
  final bool isOptional;

  /// Creates a schema property.
  DynamicGenerationSchemaProperty({
    required this.name,
    this.description,
    required this.schema,
    this.isOptional = false,
  });

  /// Converts this property to JSON.
  Map<String, dynamic> toJson() => {
        "name": name,
        if (description != null) "description": description,
        "schema": schema.toJson(),
        "isOptional": isOptional,
      };
}
