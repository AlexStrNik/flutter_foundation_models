final class GenerationSchema {
  DynamicGenerationSchema root;
  List<DynamicGenerationSchema> dependencies;

  GenerationSchema({
    required this.root,
    required this.dependencies,
  });

  Map<String, dynamic> toJson() => {
        "root": root.toJson(),
        "dependencies": dependencies.map((e) => e.toJson()).toList(),
      };
}

sealed class DynamicGenerationSchema {
  Map<String, dynamic> toJson();
}

final class ValueGenerationSchema extends DynamicGenerationSchema {
  final String type;

  /// For constant/anyOf string constraints
  final List<String>? enumValues;

  /// For regex pattern constraint
  final String? pattern;

  /// For numeric minimum constraint
  final num? minimum;

  /// For numeric maximum constraint
  final num? maximum;

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

final class ArrayGenerationSchema extends DynamicGenerationSchema {
  final DynamicGenerationSchema arrayOf;
  final int? minimumElements;
  final int? maximumElements;

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

final class AnyOfGenerationSchema extends DynamicGenerationSchema {
  final String name;
  String? description;
  final List<DynamicGenerationSchema> anyOf;

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

final class AnyOfStringsGenerationSchema extends DynamicGenerationSchema {
  final String name;
  String? description;
  final List<String> anyOf;

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

final class StructGenerationSchema extends DynamicGenerationSchema {
  final String name;
  final String? description;
  final List<DynamicGenerationSchemaProperty> properties;

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

final class DynamicGenerationSchemaProperty {
  final String name;
  final String? description;
  final DynamicGenerationSchema schema;
  final bool isOptional;

  DynamicGenerationSchemaProperty({
    required this.name,
    this.description,
    required this.schema,
    this.isOptional = false,
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        if (description != null) "description": description,
        "schema": schema.toJson(),
        "isOptional": isOptional,
      };
}
