// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:flutter_foundation_models_annotations/flutter_foundation_models_annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'model_visitor.dart';

/// Represents parsed guide constraints from @Guide annotation
class ParsedGuides {
  final List<String>? enumValues;
  final String? pattern;
  final num? minimum;
  final num? maximum;
  final int? minItems;
  final int? maxItems;
  final ParsedGuides? elementGuides;

  ParsedGuides({
    this.enumValues,
    this.pattern,
    this.minimum,
    this.maximum,
    this.minItems,
    this.maxItems,
    this.elementGuides,
  });
}

class GenerableGenerator extends GeneratorForAnnotation<Generable> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement && element is! EnumElement) {
      throw InvalidGenerationSourceError(
        '@Generable() can only be applied to classes and enums.',
        element: element,
      );
    }

    final visitor = ModelVisitor();
    element.visitChildren(visitor);

    if (element is ClassElement) {
      return _generateForClass(element, visitor, annotation);
    } else {
      return _generateForEnum(element as EnumElement, annotation);
    }
  }

  String _generateForClass(
    ClassElement element,
    ModelVisitor visitor,
    ConstantReader annotation,
  ) {
    final className = element.name;
    final description = annotation.peek('description')?.stringValue;
    final buffer = StringBuffer();
    buffer.writeln('extension \$${className}Generable on $className {');
    buffer.writeln('  static GenerationSchema get generationSchema {');

    buffer.writeln('    final root = StructGenerationSchema(');
    buffer.writeln('      name: "$className",');
    if (description != null) {
      buffer.writeln('      description: "$description",');
    }
    buffer.writeln('      properties: [');

    for (final field in visitor.fields) {
      final fieldName = field.name;
      final isOptional = field.type.toString().endsWith('?');

      String? fieldDescription;
      ParsedGuides? guides;

      for (final metadata in field.metadata) {
        final metadataElement = metadata.element;
        if (metadataElement is ConstructorElement && metadataElement.enclosingElement.name == 'Guide') {
          final constantValue = metadata.computeConstantValue();
          if (constantValue != null) {
            final descriptionObj = constantValue.getField('description');
            if (descriptionObj != null && !descriptionObj.isNull) {
              fieldDescription = descriptionObj.toStringValue();
            }

            guides = _parseGuides(constantValue);
          }
        }
      }

      buffer.writeln('        DynamicGenerationSchemaProperty(');
      buffer.writeln('          name: "$fieldName",');
      if (fieldDescription != null) {
        buffer.writeln('          description: "$fieldDescription",');
      }
      buffer.writeln('          schema: ${_getSchemaForType(field.type, guides)},');
      if (isOptional) {
        buffer.writeln('          isOptional: true,');
      }
      buffer.writeln('        ),');
    }

    buffer.writeln('      ],');
    buffer.writeln('    );');

    buffer.writeln('    final dependencies = <DynamicGenerationSchema>[];');

    buffer.writeln('    return GenerationSchema(');
    buffer.writeln('      root: root,');
    buffer.writeln('      dependencies: dependencies,');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    // Generate static fromGeneratedContent method
    buffer.writeln('  static $className fromGeneratedContent(GeneratedContent content) {');
    buffer.writeln('    return $className(');

    for (final field in visitor.fields) {
      final fieldName = field.name;
      final isOptional = field.type.toString().endsWith('?');

      if (isOptional) {
        buffer.writeln(
            '      $fieldName: content.value["$fieldName"] != null ? ${_getFromGeneratedContentForField('content.value["$fieldName"]', field.type)} : null,');
      } else {
        buffer.writeln(
            '      $fieldName: ${_getFromGeneratedContentForField('content.value["$fieldName"]', field.type)},');
      }
    }

    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    // Generate toGeneratedContent instance method
    buffer.writeln('  GeneratedContent toGeneratedContent() {');
    buffer.writeln('    return GeneratedContent({');

    for (final field in visitor.fields) {
      final fieldName = field.name;
      final isOptional = field.type.toString().endsWith('?');

      if (isOptional) {
        buffer.writeln(
            '      if ($fieldName != null) "$fieldName": ${_getToGeneratedContentForField(fieldName, field.type)},');
      } else {
        buffer.writeln('      "$fieldName": ${_getToGeneratedContentForField(fieldName, field.type)},');
      }
    }

    buffer.writeln('    });');
    buffer.writeln('  }');
    buffer.writeln('}');

    return buffer.toString();
  }

  String _generateForEnum(
    EnumElement element,
    ConstantReader annotation,
  ) {
    final enumName = element.name;
    final description = annotation.peek('description')?.stringValue;
    final buffer = StringBuffer();

    buffer.writeln('extension \$${enumName}Generable on $enumName {');
    buffer.writeln('  static GenerationSchema get generationSchema {');

    final enumValues = element.fields.where((field) => field.isEnumConstant).map((field) => field.name).toList();

    buffer.writeln('    final schema = AnyOfStringsGenerationSchema(');
    buffer.writeln('      name: "$enumName",');
    if (description != null) {
      buffer.writeln('      description: "$description",');
    }
    buffer.writeln('      anyOf: [');
    for (final value in enumValues) {
      buffer.writeln('        "$value",');
    }
    buffer.writeln('      ],');
    buffer.writeln('    );');

    buffer.writeln('    return GenerationSchema(');
    buffer.writeln('      root: schema,');
    buffer.writeln('      dependencies: [],');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    // Generate static fromGeneratedContent method
    buffer.writeln('  static $enumName fromGeneratedContent(GeneratedContent content) {');
    buffer.writeln('    return $enumName.values.firstWhere(');
    buffer.writeln('      (e) => e.name == content.value,');
    buffer.writeln('      orElse: () => throw ArgumentError("Unknown enum value: \${content.value}"),');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    // Generate toGeneratedContent instance method
    buffer.writeln('  GeneratedContent toGeneratedContent() {');
    buffer.writeln('    return GeneratedContent(name);');
    buffer.writeln('  }');
    buffer.writeln('}');

    return buffer.toString();
  }

  ParsedGuides? _parseGuides(DartObject guideAnnotation) {
    final guidesField = guideAnnotation.getField('guides');
    if (guidesField == null || guidesField.isNull) {
      return null;
    }

    final guidesList = guidesField.toListValue();
    if (guidesList == null || guidesList.isEmpty) {
      return null;
    }

    List<String>? enumValues;
    String? pattern;
    num? minimum;
    num? maximum;
    int? minItems;
    int? maxItems;
    ParsedGuides? elementGuides;

    for (final guide in guidesList) {
      final guideType = guide.type;
      if (guideType == null) continue;

      final typeName = guideType.getDisplayString(withNullability: false);

      switch (typeName) {
        case 'ConstantGuide':
          final value = guide.getField('value')?.toStringValue();
          if (value != null) {
            enumValues = [value];
          }
          break;

        case 'AnyOfGuide':
          final values = guide.getField('values')?.toListValue();
          if (values != null) {
            enumValues = values.map((v) => v.toStringValue()!).toList();
          }
          break;

        case 'PatternGuide':
          pattern = guide.getField('regex')?.toStringValue();
          break;

        case 'MinimumGuide':
          final value = guide.getField('value');
          if (value != null) {
            minimum = value.toIntValue() ?? value.toDoubleValue();
          }
          break;

        case 'MaximumGuide':
          final value = guide.getField('value');
          if (value != null) {
            maximum = value.toIntValue() ?? value.toDoubleValue();
          }
          break;

        case 'RangeGuide':
          final minVal = guide.getField('min');
          final maxVal = guide.getField('max');
          if (minVal != null) {
            minimum = minVal.toIntValue() ?? minVal.toDoubleValue();
          }
          if (maxVal != null) {
            maximum = maxVal.toIntValue() ?? maxVal.toDoubleValue();
          }
          break;

        case 'MinimumCountGuide':
          minItems = guide.getField('count')?.toIntValue();
          break;

        case 'MaximumCountGuide':
          maxItems = guide.getField('count')?.toIntValue();
          break;

        case 'ExactCountGuide':
          final count = guide.getField('count')?.toIntValue();
          if (count != null) {
            minItems = count;
            maxItems = count;
          }
          break;

        case 'CountRangeGuide':
          minItems = guide.getField('min')?.toIntValue();
          maxItems = guide.getField('max')?.toIntValue();
          break;

        case 'ElementGuide':
          final nestedGuide = guide.getField('guide');
          if (nestedGuide != null) {
            elementGuides = _parseSingleGuide(nestedGuide);
          }
          break;
      }
    }

    if (enumValues == null &&
        pattern == null &&
        minimum == null &&
        maximum == null &&
        minItems == null &&
        maxItems == null &&
        elementGuides == null) {
      return null;
    }

    return ParsedGuides(
      enumValues: enumValues,
      pattern: pattern,
      minimum: minimum,
      maximum: maximum,
      minItems: minItems,
      maxItems: maxItems,
      elementGuides: elementGuides,
    );
  }

  ParsedGuides? _parseSingleGuide(DartObject guide) {
    final guideType = guide.type;
    if (guideType == null) return null;

    final typeName = guideType.getDisplayString(withNullability: false);

    switch (typeName) {
      case 'ConstantGuide':
        final value = guide.getField('value')?.toStringValue();
        if (value != null) {
          return ParsedGuides(enumValues: [value]);
        }
        break;

      case 'AnyOfGuide':
        final values = guide.getField('values')?.toListValue();
        if (values != null) {
          return ParsedGuides(enumValues: values.map((v) => v.toStringValue()!).toList());
        }
        break;

      case 'PatternGuide':
        final pattern = guide.getField('regex')?.toStringValue();
        if (pattern != null) {
          return ParsedGuides(pattern: pattern);
        }
        break;

      case 'MinimumGuide':
        final value = guide.getField('value');
        if (value != null) {
          return ParsedGuides(minimum: value.toIntValue() ?? value.toDoubleValue());
        }
        break;

      case 'MaximumGuide':
        final value = guide.getField('value');
        if (value != null) {
          return ParsedGuides(maximum: value.toIntValue() ?? value.toDoubleValue());
        }
        break;

      case 'RangeGuide':
        final minVal = guide.getField('min');
        final maxVal = guide.getField('max');
        return ParsedGuides(
          minimum: minVal?.toIntValue() ?? minVal?.toDoubleValue(),
          maximum: maxVal?.toIntValue() ?? maxVal?.toDoubleValue(),
        );
    }

    return null;
  }

  String _getSchemaForType(DartType type, [ParsedGuides? guides]) {
    if (type.isDartCoreString) {
      return _buildValueSchema('String', guides);
    } else if (type.isDartCoreInt) {
      return _buildValueSchema('Int', guides);
    } else if (type.isDartCoreDouble) {
      return _buildValueSchema('Double', guides);
    } else if (type.isDartCoreBool) {
      return 'ValueGenerationSchema(type: "Bool")';
    } else if (type.isDartCoreList) {
      final elementType = (type as InterfaceType).typeArguments.single;
      return _buildArraySchema(elementType, guides);
    } else if (type.isDartCoreMap) {
      final typeArguments = (type as InterfaceType).typeArguments;

      if (!typeArguments[0].isDartCoreString) {
        throw Exception("Only Map<String, T> are supported");
      }

      return 'DictionaryGenerationSchema(dictionaryOf: ${_getSchemaForType(typeArguments[1])})';
    } else {
      final typeName = type.getDisplayString(withNullability: false);
      return '\$${typeName}Generable.generationSchema.root';
    }
  }

  String _buildValueSchema(String type, ParsedGuides? guides) {
    final params = <String>['type: "$type"'];

    if (guides != null) {
      if (guides.enumValues != null) {
        final enumStr = guides.enumValues!.map((v) => '"$v"').join(', ');
        params.add('enumValues: [$enumStr]');
      }
      if (guides.pattern != null) {
        // Escape backslashes for the generated code
        final escapedPattern = guides.pattern!.replaceAll(r'\', r'\\');
        params.add('pattern: "$escapedPattern"');
      }
      if (guides.minimum != null) {
        params.add('minimum: ${guides.minimum}');
      }
      if (guides.maximum != null) {
        params.add('maximum: ${guides.maximum}');
      }
    }

    return 'ValueGenerationSchema(${params.join(', ')})';
  }

  String _buildArraySchema(DartType elementType, ParsedGuides? guides) {
    final elementSchema = _getSchemaForType(elementType, guides?.elementGuides);
    final params = <String>['arrayOf: $elementSchema'];

    if (guides != null) {
      if (guides.minItems != null) {
        params.add('minimumElements: ${guides.minItems}');
      }
      if (guides.maxItems != null) {
        params.add('maximumElements: ${guides.maxItems}');
      }
    }

    return 'ArrayGenerationSchema(${params.join(', ')})';
  }

  String _getToGeneratedContentForField(String fieldName, DartType fieldType) {
    if (fieldType.isDartCoreString ||
        fieldType.isDartCoreInt ||
        fieldType.isDartCoreDouble ||
        fieldType.isDartCoreBool) {
      return fieldName;
    } else if (fieldType.isDartCoreList) {
      final elementType = (fieldType as InterfaceType).typeArguments.single;

      return '$fieldName.map((e) => ${_getToGeneratedContentForField("e", elementType)}).toList()';
    } else if (fieldType.isDartCoreMap) {
      final typeArgs = (fieldType as InterfaceType).typeArguments;
      final valueType = typeArgs[1];
      return '$fieldName.map((k, v) => MapEntry(k, ${_getToGeneratedContentForField("v", valueType)}))';
    } else {
      return '$fieldName.toGeneratedContent().value';
    }
  }

  String _getFromGeneratedContentForField(String jsonField, DartType fieldType) {
    if (fieldType.isDartCoreString) {
      return '$jsonField as String';
    } else if (fieldType.isDartCoreInt) {
      return '$jsonField as int';
    } else if (fieldType.isDartCoreDouble) {
      return '$jsonField as double';
    } else if (fieldType.isDartCoreBool) {
      return '$jsonField as bool';
    } else if (fieldType.isDartCoreList) {
      final elementType = (fieldType as InterfaceType).typeArguments.single;

      return '($jsonField as List).map((e) => ${_getFromGeneratedContentForField("e", elementType)}).toList()';
    } else if (fieldType.isDartCoreMap) {
      final typeArgs = (fieldType as InterfaceType).typeArguments;
      final valueType = typeArgs[1];
      return '($jsonField as Map).map((k, v) => MapEntry(k as String, ${_getFromGeneratedContentForField("v", valueType)}))';
    } else {
      final typeName = fieldType.getDisplayString(withNullability: false);
      return '\$${typeName}Generable.fromGeneratedContent(GeneratedContent($jsonField))';
    }
  }
}
