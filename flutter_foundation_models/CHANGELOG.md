## 0.1.1

- Add runtime availability check with `LanguageModelSession.isAvailable()`
- Lower minimum iOS version to 16.0 (API requires iOS 26+ at runtime)
- Improve documentation
- Clean up published package (exclude unnecessary example files)

## 0.1.0

- Initial release
- Text generation with `respondTo()`
- Structured output with `respondToWithSchema()`
- Streaming support with `streamResponseToWithSchema()`
- Tool use support
- Generation options (sampling mode, temperature, max tokens)
- System instructions support
- Availability checking with `LanguageModelSession.isAvailable()`
- Supports iOS 16+ (Foundation Models API requires iOS 26+ at runtime)
