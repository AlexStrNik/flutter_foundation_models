/// Sampling mode for text generation.
sealed class SamplingMode {
  const SamplingMode();

  /// Greedy sampling - always picks the most likely token.
  /// Produces deterministic output.
  const factory SamplingMode.greedy() = GreedySamplingMode;

  /// Top-K sampling - samples from the top K most likely tokens.
  const factory SamplingMode.topK(int k, {int? seed}) = TopKSamplingMode;

  /// Top-P (nucleus) sampling - samples from tokens whose cumulative
  /// probability exceeds the threshold.
  const factory SamplingMode.topP(double probabilityThreshold, {int? seed}) =
      TopPSamplingMode;
}

final class GreedySamplingMode extends SamplingMode {
  const GreedySamplingMode();
}

final class TopKSamplingMode extends SamplingMode {
  final int k;
  final int? seed;

  const TopKSamplingMode(this.k, {this.seed});
}

final class TopPSamplingMode extends SamplingMode {
  final double probabilityThreshold;
  final int? seed;

  const TopPSamplingMode(this.probabilityThreshold, {this.seed});
}

/// Options for controlling text generation behavior.
class GenerationOptions {
  /// The sampling mode to use for generation.
  final SamplingMode? sampling;

  /// Temperature controls randomness in generation.
  /// Range: 0.0 to 2.0
  /// Lower values produce more deterministic output.
  /// Higher values produce more creative/random output.
  final double? temperature;

  /// Maximum number of tokens to generate in the response.
  final int? maximumResponseTokens;

  const GenerationOptions({
    this.sampling,
    this.temperature,
    this.maximumResponseTokens,
  });
}
