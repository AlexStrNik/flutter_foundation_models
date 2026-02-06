/// Flutter Foundation Models - A direct port of Apple's Foundation Models framework.
///
/// This package provides a Flutter interface to Apple's on-device language model,
/// available on iOS 26+ and macOS 26+. The API mirrors Swift's native Foundation
/// Models framework as closely as possible.
///
/// ## Design Philosophy
///
/// This package is a **direct port of Swift's Foundation Models API**:
///
/// | Swift | Dart |
/// |-------|------|
/// | `SystemLanguageModel.default` | `SystemLanguageModel.defaultModel` |
/// | `session.respond(to:)` → `Response<String>` | `session.respondTo()` → `TextResponse` |
/// | `session.respond(to:generating:)` → `Response<T>` | `session.respondToWithSchema()` → `StructuredResponse` |
/// | `@Generable` macro | `@Generable()` annotation + codegen |
///
/// ## Quick Start
///
/// ```dart
/// import 'package:flutter_foundation_models/flutter_foundation_models.dart';
///
/// if (await SystemLanguageModel.isAvailable) {
///   final session = await LanguageModelSession.create();
///   final response = await session.respondTo("What is Flutter?");
///   print(response.content);
///   session.dispose();
/// }
/// ```
///
/// ## Structured Output
///
/// Define data models with `@Generable`:
///
/// ```dart
/// @Generable(description: "A movie recommendation")
/// class Movie {
///   @Guide(description: "Movie title")
///   final String title;
///
///   @Guide(description: "Year released")
///   final int year;
///
///   Movie({required this.title, required this.year});
/// }
/// ```
///
/// Generate structured content:
///
/// ```dart
/// final response = await session.respondToWithSchema(
///   "Recommend a sci-fi movie",
///   schema: $MovieGenerable.generationSchema,
/// );
/// final movie = $MovieGenerable.fromGeneratedContent(response.content);
/// print('${movie.title} (${movie.year})');
/// ```
///
/// ## Generating Lists
///
/// Generate arrays using `GenerationSchema.array`:
///
/// ```dart
/// final response = await session.respondToWithSchema(
///   "Recommend 3 sci-fi movies",
///   schema: GenerationSchema.array(
///     $MovieGenerable.generationSchema,
///     minimumElements: 3,
///   ),
/// );
/// final movies = response.content.toList($MovieGenerable.fromGeneratedContent);
/// ```
///
/// ## Streaming
///
/// For real-time UI updates:
///
/// ```dart
/// // Text streaming
/// session.streamResponseTo("Tell me a story").listen((text) {
///   print(text);
/// });
///
/// // Structured streaming
/// session.streamResponseToWithSchema(
///   "Generate a story",
///   schema: $StoryGenerable.generationSchema,
/// ).listen((partial) {
///   final story = $StoryGenerable.fromPartialGeneratedContent(partial);
///   print(story.title ?? "Loading...");
/// });
/// ```
///
/// ## Tools
///
/// Enable the model to call your functions:
///
/// ```dart
/// class WeatherTool extends Tool {
///   @override
///   String name = "getWeather";
///
///   @override
///   String description = "Get weather for a city";
///
///   @override
///   GenerationSchema get parameters => $WeatherArgsGenerable.generationSchema;
///
///   @override
///   Future<GeneratedContent> call(GeneratedContent arguments) async {
///     final args = $WeatherArgsGenerable.fromGeneratedContent(arguments);
///     return WeatherResult(city: args.city, temp: 72).toGeneratedContent();
///   }
/// }
///
/// final session = await LanguageModelSession.create(tools: [WeatherTool()]);
/// ```
///
/// ## Transcripts
///
/// Persist and restore conversation history:
///
/// ```dart
/// final transcript = await session.transcript;
/// final json = transcript.toJson();  // Store this
///
/// // Later, restore:
/// final restored = Transcript.fromJson(json);
/// final newSession = await LanguageModelSession.createWithTranscript(
///   transcript: restored,
/// );
/// ```
///
/// ## Error Handling
///
/// ```dart
/// try {
///   final response = await session.respondTo("...");
/// } on GenerationException catch (e) {
///   print('${e.type}: ${e.message}');
/// }
/// ```
library flutter_foundation_models;

export 'src/generated_content.dart';
export 'src/generation_error.dart';
export 'src/generation_options.dart';
export 'src/generation_schema.dart';
export 'src/language_model_session.dart';
export 'src/response.dart';
export 'src/system_language_model.dart';
export 'src/tool.dart';
export 'src/transcript.dart';

export 'package:flutter_foundation_models_annotations/flutter_foundation_models_annotations.dart';
