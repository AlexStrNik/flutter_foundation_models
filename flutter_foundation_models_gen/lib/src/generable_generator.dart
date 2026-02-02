// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:flutter_foundation_models_annotations/flutter_foundation_models_annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'model_visitor.dart';

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
      for (final metadata in field.metadata) {
        final metadataElement = metadata.element;
        if (metadataElement is ConstructorElement && metadataElement.enclosingElement.name == 'Guide') {
          final descriptionObj = metadata.computeConstantValue()?.getField('description');
          if (descriptionObj != null && !descriptionObj.isNull) {
            fieldDescription = descriptionObj.toStringValue();
          }
        }
      }

      buffer.writeln('        DynamicGenerationSchemaProperty(');
      buffer.writeln('          name: "$fieldName",');
      if (fieldDescription != null) {
        buffer.writeln('          description: "$fieldDescription",');
      }
      buffer.writeln('          schema: ${_getSchemaForType(field.type)},');
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

  String _getSchemaForType(DartType type) {
    if (type.isDartCoreString) {
      return 'ValueGenerationSchema(type: "String")';
    } else if (type.isDartCoreInt) {
      return 'ValueGenerationSchema(type: "Int")';
    } else if (type.isDartCoreDouble) {
      return 'ValueGenerationSchema(type: "Double")';
    } else if (type.isDartCoreBool) {
      return 'ValueGenerationSchema(type: "Bool")';
    } else if (type.isDartCoreList) {
      final elementType = (type as InterfaceType).typeArguments.single;
      return 'ArrayGenerationSchema(arrayOf: ${_getSchemaForType(elementType)})';
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
