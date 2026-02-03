import 'package:flutter_foundation_models/src/generated/foundation_models_api.g.dart';

/// Use case for the language model.
enum UseCase {
  /// General purpose model for creative generation and Q&A.
  general,

  /// Model fine-tuned for tagging and extraction tasks.
  contentTagging,
}

/// Guardrails setting for the language model.
enum Guardrails {
  /// Default guardrails enforcing Apple's content guidelines.
  defaultGuardrails,

  /// More permissive guardrails for content transformations.
  permissiveContentTransformations,
}

/// Represents the availability status of the language model.
class ModelAvailability {
  final bool isAvailable;
  final String? unavailableReason;

  ModelAvailability({required this.isAvailable, this.unavailableReason});
}

/// A model adapter for customizing language model behavior.
///
/// Create an adapter using [Adapter.create] or [Adapter.fromAsset].
///
/// Example:
/// ```dart
/// // From registered name
/// final adapter = await Adapter.create(name: 'my-adapter');
///
/// // From asset path
/// final adapter = await Adapter.fromAsset('assets/my-adapter.mlmodel');
///
/// final model = await SystemLanguageModel.create(adapter: adapter);
/// ```
class Adapter {
  final String _adapterId;
  static final FoundationModelsHostApi _hostApi = FoundationModelsHostApi();

  Adapter._(this._adapterId);

  /// The internal adapter ID.
  String get adapterId => _adapterId;

  /// Creates an adapter by name.
  static Future<Adapter> create({required String name}) async {
    final adapterId = await _hostApi.createAdapter(name, null);
    return Adapter._(adapterId);
  }

  /// Creates an adapter from a Flutter asset path.
  ///
  /// The asset path is resolved to a file URL on the native side.
  static Future<Adapter> fromAsset(String assetPath) async {
    final adapterId = await _hostApi.createAdapter(null, assetPath);
    return Adapter._(adapterId);
  }

  /// Disposes the adapter and releases resources.
  Future<void> dispose() async {
    await _hostApi.destroyAdapter(_adapterId);
  }
}

/// Represents a system language model for on-device AI.
///
/// Use [SystemLanguageModel.defaultModel] for the standard model,
/// or [SystemLanguageModel.create] for custom models.
///
/// Example:
/// ```dart
/// if (await SystemLanguageModel.isAvailable) {
///   // Default model
///   final session = await LanguageModelSession.create(
///     model: SystemLanguageModel.defaultModel,
///   );
///
///   // Custom model
///   final model = await SystemLanguageModel.create(
///     useCase: UseCase.contentTagging,
///   );
///   final session = await LanguageModelSession.create(model: model);
///
///   // With adapter
///   final adapter = await Adapter.create(name: 'my-adapter');
///   final model = await SystemLanguageModel.create(adapter: adapter);
/// }
/// ```
class SystemLanguageModel {
  final String _modelId;
  final bool _isDefault;

  static final FoundationModelsHostApi _hostApi = FoundationModelsHostApi();

  SystemLanguageModel._(this._modelId, {bool isDefault = false})
      : _isDefault = isDefault;

  /// The default system language model.
  static final SystemLanguageModel defaultModel =
      SystemLanguageModel._('default', isDefault: true);

  /// The model ID.
  String get modelId => _modelId;

  /// Whether this is the default model.
  bool get isDefault => _isDefault;

  /// Creates a new language model.
  ///
  /// [adapter] - Optional adapter for custom model behavior.
  /// [useCase] - The use case. Defaults to [UseCase.general].
  /// [guardrails] - The guardrails setting. Defaults to [Guardrails.defaultGuardrails].
  static Future<SystemLanguageModel> create({
    Adapter? adapter,
    UseCase useCase = UseCase.general,
    Guardrails guardrails = Guardrails.defaultGuardrails,
  }) async {
    final useCaseType = switch (useCase) {
      UseCase.general => ModelUseCaseType.general,
      UseCase.contentTagging => ModelUseCaseType.contentTagging,
    };

    final guardrailsType = switch (guardrails) {
      Guardrails.defaultGuardrails => ModelGuardrailsType.defaultGuardrails,
      Guardrails.permissiveContentTransformations =>
        ModelGuardrailsType.permissiveContentTransformations,
    };

    final configMessage = ModelConfigurationMessage(
      adapterId: adapter?.adapterId,
      useCase: useCaseType,
      guardrails: guardrailsType,
    );

    final modelId = await _hostApi.createModel(configMessage);
    return SystemLanguageModel._(modelId);
  }

  /// Checks if Foundation Models API is available.
  static Future<bool> get isAvailable async {
    try {
      return _hostApi.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Gets detailed availability information.
  static Future<ModelAvailability> get availability async {
    try {
      final result = await _hostApi.getModelAvailability();
      return ModelAvailability(
        isAvailable: result.isAvailable,
        unavailableReason: result.unavailableReason,
      );
    } catch (e) {
      return ModelAvailability(
        isAvailable: false,
        unavailableReason: e.toString(),
      );
    }
  }

  /// Disposes the model. No-op for [defaultModel].
  Future<void> dispose() async {
    if (_isDefault) return;
    await _hostApi.destroyModel(_modelId);
  }
}
