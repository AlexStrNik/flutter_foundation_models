import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType, TargetKind.enumType})
final class Generable {
  final String? description;

  const Generable({this.description});
}

@Target({TargetKind.field})
final class Guide {
  final String? description;

  const Guide({this.description});
}
