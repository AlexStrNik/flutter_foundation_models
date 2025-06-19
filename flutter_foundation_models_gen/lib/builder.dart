import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generable_generator.dart';

Builder generableBuilder(BuilderOptions options) => SharedPartBuilder(
      [GenerableGenerator()],
      'generable',
    );
