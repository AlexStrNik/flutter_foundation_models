/// Sampling mode for text generation.
///
/// Sampling modes control how the model selects the next token during generation.
/// Different modes produce different levels of randomness and creativity.
sealed class SamplingMode {
  const SamplingMode();

  /// Greedy sampling - always picks the most likely token.
  ///
  /// Produces deterministic output. Use when you need consistent,
  /// predictable responses.
  const factory SamplingMode.greedy() = GreedySamplingMode;

  /// Top-K sampling - samples from the top K most likely tokens.
  ///
  /// [k] - The number of top tokens to consider.
  /// [seed] - Optional seed for reproducible randomness.
  ///
  /// Lower K values produce more focused output, higher values
  /// allow more variety.
  const factory SamplingMode.topK(int k, {int? seed}) = TopKSamplingMode;

  /// Top-P (nucleus) sampling - samples from tokens whose cumulative
  /// probability exceeds the threshold.
  ///
  /// [probabilityThreshold] - The cumulative probability threshold (0.0 to 1.0).
  /// [seed] - Optional seed for reproducible randomness.
  ///
  /// Lower values (e.g., 0.1) produce more focused output,
  /// higher values (e.g., 0.9) allow more variety.
  const factory SamplingMode.topP(double probabilityThreshold, {int? seed}) =
      TopPSamplingMode;
}

/// Greedy sampling mode - always picks the most likely token.
///
/// See [SamplingMode.greedy] for details.
final class GreedySamplingMode extends SamplingMode {
  /// Creates a greedy sampling mode.
  const GreedySamplingMode();
}

/// Top-K sampling mode - samples from the top K most likely tokens.
///
/// See [SamplingMode.topK] for details.
final class TopKSamplingMode extends SamplingMode {
  /// The number of top tokens to consider.
  final int k;

  /// Optional seed for reproducible randomness.
  final int? seed;

  /// Creates a top-K sampling mode.
  const TopKSamplingMode(this.k, {this.seed});
}

/// Top-P (nucleus) sampling mode.
///
/// See [SamplingMode.topP] for details.
final class TopPSamplingMode extends SamplingMode {
  /// The cumulative probability threshold (0.0 to 1.0).
  final double probabilityThreshold;

  /// Optional seed for reproducible randomness.
  final int? seed;

  /// Creates a top-P sampling mode.
  const TopPSamplingMode(this.probabilityThreshold, {this.seed});
}

/// Options for controlling text generation behavior.
///
/// Use these options to fine-tune how the model generates responses.
///
/// Example:
/// ```dart
/// final options = GenerationOptions(
///   sampling: SamplingMode.topP(0.9),
///   temperature: 0.7,
///   maximumResponseTokens: 500,
/// );
///
/// final response = await session.respondTo(
///   "Write a story",
///   options: options,
/// );
/// ```
class GenerationOptions {
  /// The sampling mode to use for generation.
  ///
  /// Controls how the model selects tokens. If not specified,
  /// the model uses its default sampling behavior.
  final SamplingMode? sampling;

  /// Temperature controls randomness in generation.
  ///
  /// Range: 0.0 to 2.0
  /// - Lower values (e.g., 0.2) produce more deterministic, focused output
  /// - Higher values (e.g., 1.5) produce more creative, varied output
  ///
  /// If not specified, the model uses its default temperature.
  final double? temperature;

  /// Maximum number of tokens to generate in the response.
  ///
  /// Use this to limit response length. If not specified,
  /// the model generates until it naturally completes.
  final int? maximumResponseTokens;

  /// Creates generation options.
  const GenerationOptions({
    this.sampling,
    this.temperature,
    this.maximumResponseTokens,
  });
}
