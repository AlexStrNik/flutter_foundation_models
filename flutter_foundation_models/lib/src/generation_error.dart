/// Types of generation errors that can occur.
///
/// Mirrors Swift's `LanguageModelSession.GenerationError` cases.
enum GenerationErrorType {
  /// The context window size was exceeded.
  exceededContextWindowSize,

  /// Required assets are unavailable.
  assetsUnavailable,

  /// A guardrail was violated.
  guardrailViolation,

  /// An unsupported generation guide was used.
  unsupportedGuide,

  /// The language or locale is not supported.
  unsupportedLanguageOrLocale,

  /// Failed to decode the response.
  decodingFailure,

  /// Rate limited by the model.
  rateLimited,

  /// Concurrent requests are not allowed.
  concurrentRequests,

  /// The model refused to generate a response.
  refusal,

  /// Unknown error type.
  unknown,
}

/// Exception thrown when generation fails.
///
/// Contains structured error information including the error type,
/// a human-readable message, and optional debug description.
class GenerationException implements Exception {
  /// Creates a GenerationException.
  const GenerationException({
    required this.type,
    required this.message,
    this.debugDescription,
  });

  /// The type of generation error.
  final GenerationErrorType type;

  /// A human-readable error message.
  final String message;

  /// Additional debug information about the error.
  final String? debugDescription;

  /// Creates a GenerationException from an error code string.
  factory GenerationException.fromCode(
    String code,
    String message, {
    String? debugDescription,
  }) {
    final type = _parseErrorType(code);
    return GenerationException(
      type: type,
      message: message,
      debugDescription: debugDescription,
    );
  }

  static GenerationErrorType _parseErrorType(String code) {
    return switch (code) {
      'exceededContextWindowSize' => GenerationErrorType.exceededContextWindowSize,
      'assetsUnavailable' => GenerationErrorType.assetsUnavailable,
      'guardrailViolation' => GenerationErrorType.guardrailViolation,
      'unsupportedGuide' => GenerationErrorType.unsupportedGuide,
      'unsupportedLanguageOrLocale' => GenerationErrorType.unsupportedLanguageOrLocale,
      'decodingFailure' => GenerationErrorType.decodingFailure,
      'rateLimited' => GenerationErrorType.rateLimited,
      'concurrentRequests' => GenerationErrorType.concurrentRequests,
      'refusal' => GenerationErrorType.refusal,
      _ => GenerationErrorType.unknown,
    };
  }

  @override
  String toString() {
    if (debugDescription != null) {
      return 'GenerationException($type): $message\nDebug: $debugDescription';
    }
    return 'GenerationException($type): $message';
  }
}
