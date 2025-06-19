import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';

class ModelVisitor extends SimpleElementVisitor<void> {
  final fields = <FieldElement>[];

  @override
  void visitFieldElement(FieldElement element) {
    fields.add(element);
  }
}
