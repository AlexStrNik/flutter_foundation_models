## 0.2.0

### Breaking Changes
- `LanguageModelSession` now uses async factory method `LanguageModelSession.create()` instead of constructor
- Moved `isAvailable` from `LanguageModelSession` to `SystemLanguageModel.isAvailable`

### New Features
- **Swift Package Manager support** - Plugin now supports both SPM and CocoaPods
- **SystemLanguageModel class** - Manage language models with configuration options
  - `SystemLanguageModel.defaultModel` - Access the default system model
  - `SystemLanguageModel.create()` - Create custom model with adapter, useCase, or guardrails
  - `SystemLanguageModel.isAvailable` - Check if Foundation Models API is available
  - `SystemLanguageModel.availability` - Get detailed availability info with unavailability reason
- **Adapter support** - Load custom adapters
  - `Adapter.create(name:)` - Create adapter by name
  - `Adapter.fromAsset(assetPath)` - Create adapter from Flutter asset
- **UseCase configuration** - `UseCase.general` and `UseCase.contentTagging`
- **Guardrails configuration** - `Guardrails.defaultGuardrails` and `Guardrails.permissiveContentTransformations`
- **Text streaming** - `streamResponseTo()` for plain text streaming without schema
- **Session prewarm** - `session.prewarm()` to reduce latency on first request
- **Session state** - `session.isResponding` to check if session is actively generating

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
