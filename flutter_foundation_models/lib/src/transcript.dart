import 'dart:convert';

import 'package:flutter_foundation_models/flutter_foundation_models.dart';

/// A transcript containing the conversation history of a session.
///
/// Transcripts can be used to:
/// - Inspect the conversation history
/// - Create a new session continuing from a previous conversation
/// - Serialize and store conversations
class Transcript {
  const Transcript._(this._json, this._entries);

  final Map<String, dynamic> _json;
  final List<TranscriptEntry> _entries;

  /// Creates a Transcript from a JSON string.
  factory Transcript.fromJson(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final transcriptObj = json['transcript'] as Map<String, dynamic>? ?? {};
    final entriesJson = transcriptObj['entries'] as List<dynamic>? ?? [];

    final entries = entriesJson
        .map((e) => TranscriptEntry._fromJson(e as Map<String, dynamic>))
        .toList();

    return Transcript._(json, entries);
  }

  /// Converts this Transcript to a JSON string.
  String toJson() => jsonEncode(_json);

  /// The raw JSON representation of this transcript.
  Map<String, dynamic> get json => _json;

  /// The entries in this transcript.
  List<TranscriptEntry> get entries => _entries;

  /// The number of entries in this transcript.
  int get length => _entries.length;

  /// Whether this transcript is empty.
  bool get isEmpty => _entries.isEmpty;

  /// Whether this transcript is not empty.
  bool get isNotEmpty => _entries.isNotEmpty;

  /// Access entries by index.
  TranscriptEntry operator [](int index) => _entries[index];

  @override
  String toString() => 'Transcript($length entries)';
}

/// Base class for transcript entries.
///
/// Mirrors Swift's `Transcript.Entry` enum with cases:
/// - [TranscriptInstructions] - system instructions
/// - [TranscriptPrompt] - user prompt
/// - [TranscriptToolCalls] - model requesting tool calls
/// - [TranscriptToolOutput] - tool execution result
/// - [TranscriptResponse] - model response
sealed class TranscriptEntry {
  const TranscriptEntry({required this.id});

  /// The unique identifier of this entry.
  final String id;

  factory TranscriptEntry._fromJson(Map<String, dynamic> json) {
    final role = json['role'] as String?;

    // "response" role can be either ToolCalls or Response depending on content
    if (role == 'response') {
      if (json.containsKey('toolCalls')) {
        return TranscriptToolCalls._fromJson(json);
      }
      return TranscriptResponse._fromJson(json);
    }

    return switch (role) {
      'instructions' => TranscriptInstructions._fromJson(json),
      'user' => TranscriptPrompt._fromJson(json),
      'tool' => TranscriptToolOutput._fromJson(json),
      _ => TranscriptUnknown._fromJson(json),
    };
  }
}

/// System instructions entry.
///
/// Mirrors Swift's `Transcript.Instructions`.
class TranscriptInstructions extends TranscriptEntry {
  const TranscriptInstructions({
    required super.id,
    required this.segments,
    required this.toolDefinitions,
  });

  /// The instruction content segments.
  final List<TranscriptSegment> segments;

  /// Tool definitions provided with instructions.
  final List<TranscriptToolDefinition> toolDefinitions;

  factory TranscriptInstructions._fromJson(Map<String, dynamic> json) {
    final contentsJson = json['contents'] as List<dynamic>? ?? [];
    final toolsJson = json['tools'] as List<dynamic>? ?? [];

    return TranscriptInstructions(
      id: json['id'] as String? ?? '',
      segments: contentsJson
          .map((s) => TranscriptSegment._fromJson(s as Map<String, dynamic>))
          .toList(),
      toolDefinitions: toolsJson
          .map((t) => TranscriptToolDefinition._fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Get the full text content of the instructions.
  String get text => segments
      .whereType<TranscriptTextSegment>()
      .map((s) => s.content)
      .join();

  @override
  String toString() => 'TranscriptInstructions(${segments.length} segments)';
}

/// User prompt entry.
///
/// Mirrors Swift's `Transcript.Prompt`.
class TranscriptPrompt extends TranscriptEntry {
  const TranscriptPrompt({
    required super.id,
    required this.segments,
    this.options,
  });

  /// The prompt content segments.
  final List<TranscriptSegment> segments;

  /// Generation options used for this prompt.
  final Map<String, dynamic>? options;

  factory TranscriptPrompt._fromJson(Map<String, dynamic> json) {
    final contentsJson = json['contents'] as List<dynamic>? ?? [];
    final optionsJson = json['options'] as Map<String, dynamic>?;

    return TranscriptPrompt(
      id: json['id'] as String? ?? '',
      segments: contentsJson
          .map((s) => TranscriptSegment._fromJson(s as Map<String, dynamic>))
          .toList(),
      options: optionsJson,
    );
  }

  /// Get the full text content of the prompt.
  String get text => segments
      .whereType<TranscriptTextSegment>()
      .map((s) => s.content)
      .join();

  @override
  String toString() => 'TranscriptPrompt("${text.length > 50 ? '${text.substring(0, 50)}...' : text}")';
}

/// Tool calls entry (model requesting tool invocations).
///
/// Mirrors Swift's `Transcript.ToolCalls`.
class TranscriptToolCalls extends TranscriptEntry {
  const TranscriptToolCalls({
    required super.id,
    required this.calls,
  });

  /// The list of tool calls.
  final List<TranscriptToolCall> calls;

  factory TranscriptToolCalls._fromJson(Map<String, dynamic> json) {
    final callsJson = json['toolCalls'] as List<dynamic>? ?? [];

    return TranscriptToolCalls(
      id: json['id'] as String? ?? '',
      calls: callsJson
          .map((c) => TranscriptToolCall._fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  String toString() => 'TranscriptToolCalls(${calls.length} calls)';
}

/// A single tool call.
///
/// Mirrors Swift's `Transcript.ToolCall`.
class TranscriptToolCall {
  const TranscriptToolCall({
    required this.id,
    required this.toolName,
    required this.arguments,
  });

  /// The unique identifier of this tool call.
  final String id;

  /// The name of the tool being called.
  final String toolName;

  /// The JSON-encoded arguments string for the tool.
  final String arguments;

  /// Parse arguments as GeneratedContent.
  GeneratedContent get toolInput {
    try {
      final parsed = jsonDecode(arguments) as Map<String, dynamic>;
      return GeneratedContent(parsed);
    } catch (_) {
      return GeneratedContent({});
    }
  }

  factory TranscriptToolCall._fromJson(Map<String, dynamic> json) {
    return TranscriptToolCall(
      id: json['id'] as String? ?? '',
      toolName: json['name'] as String? ?? '',
      arguments: json['arguments'] as String? ?? '{}',
    );
  }

  @override
  String toString() => 'TranscriptToolCall($toolName)';
}

/// Tool output entry (result from a tool invocation).
///
/// Mirrors Swift's `Transcript.ToolOutput`.
class TranscriptToolOutput extends TranscriptEntry {
  const TranscriptToolOutput({
    required super.id,
    required this.toolName,
    required this.toolCallID,
    required this.segments,
  });

  /// The name of the tool that produced this output.
  final String toolName;

  /// The ID of the tool call this output responds to.
  final String toolCallID;

  /// The output content segments.
  final List<TranscriptSegment> segments;

  factory TranscriptToolOutput._fromJson(Map<String, dynamic> json) {
    final contentsJson = json['contents'] as List<dynamic>? ?? [];

    return TranscriptToolOutput(
      id: json['id'] as String? ?? '',
      toolName: json['toolName'] as String? ?? '',
      toolCallID: json['toolCallID'] as String? ?? '',
      segments: contentsJson
          .map((s) => TranscriptSegment._fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Get the text content of the tool output.
  String get text => segments
      .whereType<TranscriptTextSegment>()
      .map((s) => s.content)
      .join();

  @override
  String toString() => 'TranscriptToolOutput($toolName)';
}

/// Model response entry.
///
/// Mirrors Swift's `Transcript.Response`.
class TranscriptResponse extends TranscriptEntry {
  const TranscriptResponse({
    required super.id,
    required this.segments,
    required this.assets,
  });

  /// The response content segments.
  final List<TranscriptSegment> segments;

  /// Asset IDs associated with this response (model identifiers).
  final List<String> assets;

  factory TranscriptResponse._fromJson(Map<String, dynamic> json) {
    final contentsJson = json['contents'] as List<dynamic>? ?? [];
    final assetsJson = json['assets'] as List<dynamic>? ?? [];

    return TranscriptResponse(
      id: json['id'] as String? ?? '',
      segments: contentsJson
          .map((s) => TranscriptSegment._fromJson(s as Map<String, dynamic>))
          .toList(),
      assets: assetsJson.cast<String>(),
    );
  }

  /// Get the full text content of the response.
  String get text => segments
      .whereType<TranscriptTextSegment>()
      .map((s) => s.content)
      .join();

  @override
  String toString() => 'TranscriptResponse("${text.length > 50 ? '${text.substring(0, 50)}...' : text}")';
}

/// Unknown entry type (for forward compatibility).
class TranscriptUnknown extends TranscriptEntry {
  const TranscriptUnknown({
    required super.id,
    required this.role,
    required this.json,
  });

  /// The unknown role string.
  final String? role;

  /// The raw JSON of this entry.
  final Map<String, dynamic> json;

  factory TranscriptUnknown._fromJson(Map<String, dynamic> json) {
    return TranscriptUnknown(
      id: json['id'] as String? ?? '',
      role: json['role'] as String?,
      json: json,
    );
  }

  @override
  String toString() => 'TranscriptUnknown($role)';
}

/// Base class for transcript segments.
///
/// Mirrors Swift's `Transcript.Segment` enum with cases:
/// - [TranscriptTextSegment] - plain text content
/// - [TranscriptStructuredSegment] - structured generated content
sealed class TranscriptSegment {
  const TranscriptSegment({required this.id});

  /// The unique identifier of this segment.
  final String id;

  factory TranscriptSegment._fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'text' => TranscriptTextSegment._fromJson(json),
      'structure' => TranscriptStructuredSegment._fromJson(json),
      _ => TranscriptTextSegment(id: json['id'] as String? ?? '', content: ''),
    };
  }
}

/// Text segment containing plain text content.
///
/// Mirrors Swift's `Transcript.TextSegment`.
class TranscriptTextSegment extends TranscriptSegment {
  const TranscriptTextSegment({
    required super.id,
    required this.content,
  });

  /// The text content.
  final String content;

  factory TranscriptTextSegment._fromJson(Map<String, dynamic> json) {
    return TranscriptTextSegment(
      id: json['id'] as String? ?? '',
      content: json['text'] as String? ?? '',
    );
  }

  @override
  String toString() => 'TranscriptTextSegment("${content.length > 30 ? '${content.substring(0, 30)}...' : content}")';
}

/// Structured segment containing generated content.
///
/// Mirrors Swift's `Transcript.StructuredSegment`.
class TranscriptStructuredSegment extends TranscriptSegment {
  const TranscriptStructuredSegment({
    required super.id,
    required this.source,
    required this.content,
  });

  /// The source representation of the structured content.
  final String source;

  /// The structured content.
  final GeneratedContent content;

  factory TranscriptStructuredSegment._fromJson(Map<String, dynamic> json) {
    final contentJson = json['content'] as Map<String, dynamic>? ?? {};

    return TranscriptStructuredSegment(
      id: json['id'] as String? ?? '',
      source: json['source'] as String? ?? '',
      content: GeneratedContent(contentJson),
    );
  }

  @override
  String toString() => 'TranscriptStructuredSegment($source)';
}

/// Tool definition in transcript.
///
/// Mirrors Swift's `Transcript.ToolDefinition`.
class TranscriptToolDefinition {
  const TranscriptToolDefinition({
    required this.name,
    required this.description,
    required this.parameters,
  });

  /// The tool name.
  final String name;

  /// The tool description.
  final String description;

  /// The tool parameters schema.
  final Map<String, dynamic> parameters;

  factory TranscriptToolDefinition._fromJson(Map<String, dynamic> json) {
    // Tools are wrapped in a "function" object
    final function = json['function'] as Map<String, dynamic>? ?? json;

    return TranscriptToolDefinition(
      name: function['name'] as String? ?? '',
      description: function['description'] as String? ?? '',
      parameters: function['parameters'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  String toString() => 'TranscriptToolDefinition($name)';
}
