import 'package:flutter_foundation_models/flutter_foundation_models.dart';

/// Response from text generation.
///
/// Contains the generated text content along with the transcript
/// entries created during this response.
class TextResponse {
  /// Creates a TextResponse.
  const TextResponse({
    required this.content,
    required this.transcriptEntries,
  });

  /// The generated text content.
  final String content;

  /// Transcript entries created during this response.
  ///
  /// This includes the prompt, any tool calls/outputs, and the response itself.
  final List<TranscriptEntry> transcriptEntries;

  @override
  String toString() => 'TextResponse(content: "${content.length > 50 ? '${content.substring(0, 50)}...' : content}")';
}

/// Response from structured generation.
///
/// Contains the generated content, raw content, and transcript entries.
class StructuredResponse {
  /// Creates a StructuredResponse.
  const StructuredResponse({
    required this.content,
    required this.rawContent,
    required this.transcriptEntries,
  });

  /// The generated content as a typed object.
  final GeneratedContent content;

  /// The raw generated content before type conversion.
  final GeneratedContent rawContent;

  /// Transcript entries created during this response.
  ///
  /// This includes the prompt, any tool calls/outputs, and the response itself.
  final List<TranscriptEntry> transcriptEntries;

  @override
  String toString() => 'StructuredResponse(${transcriptEntries.length} transcript entries)';
}
