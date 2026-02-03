## 0.1.1

- Rename partial classes to use `$` prefix (`$ClassNamePartial`)
- Improve documentation

## 0.1.0

- Initial release
- Code generation for `@Generable` classes and enums
- Generates `$ClassNameGenerable` extensions with:
  - `generationSchema` getter
  - `fromGeneratedContent()` for deserialization
  - `fromPartialGeneratedContent()` for streaming
  - `toGeneratedContent()` for serialization
- Generates `$ClassNamePartial` classes for streaming responses
- Support for nested types, lists, and enums
- Support for all generation guides (constraints)
