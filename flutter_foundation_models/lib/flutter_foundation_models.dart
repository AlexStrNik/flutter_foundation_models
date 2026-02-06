/// Flutter Foundation Models - A Flutter plugin for Apple's on-device Foundation Models.
///
/// This package provides a Flutter interface to Apple's on-device language model,
/// available on iOS 26+ and macOS 26+. It enables text generation, structured
/// output, streaming responses, and tool use.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:flutter_foundation_models/flutter_foundation_models.dart';
///
/// // Check availability and create a session
/// if (await SystemLanguageModel.isAvailable) {
///   final session = await LanguageModelSession.create();
///
///   // Generate text
///   final response = await session.respondTo("What is Flutter?");
///   print(response.content);
///
///   // Clean up
///   session.dispose();
/// }
/// ```
///
/// ## Structured Output
///
/// Define your data models with the @Generable annotation:
///
/// ```dart
/// @Generable()
/// class MovieRecommendation {
///   @Guide(description: "Movie title")
///   final String title;
///
///   @Guide(description: "Year released")
///   final int year;
///
///   MovieRecommendation({required this.title, required this.year});
/// }
/// ```
///
/// Then generate structured content:
///
/// ```dart
/// final response = await session.respondToWithSchema(
///   "Recommend a sci-fi movie",
///   schema: $MovieRecommendationGenerable.generationSchema,
/// );
/// final movie = $MovieRecommendationGenerable.fromGeneratedContent(response.content);
/// print('${movie.title} (${movie.year})');
/// ```
///
/// ## Generating Lists
///
/// Generate multiple items using `GenerationSchema.array`:
///
/// ```dart
/// final response = await session.respondToWithSchema(
///   "Recommend 3 sci-fi movies",
///   schema: GenerationSchema.array(
///     $MovieRecommendationGenerable.generationSchema,
///     minimumElements: 3,
///     maximumElements: 3,
///   ),
/// );
/// final movies = response.content.toList($MovieRecommendationGenerable.fromGeneratedContent);
/// for (final movie in movies) {
///   print('${movie.title} (${movie.year})');
/// }
/// ```
///
/// ## Streaming
///
/// For real-time UI updates during generation:
///
/// ```dart
/// final stream = session.streamResponseToWithSchema(
///   "Generate a story",
///   schema: $StoryGenerable.generationSchema,
/// );
///
/// stream.listen((partial) {
///   final story = $StoryGenerable.fromPartialGeneratedContent(partial);
///   print(story.text ?? "Loading...");
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
///     // Fetch real weather data...
///     return WeatherResult(...).toGeneratedContent();
///   }
/// }
///
/// final session = await LanguageModelSession.create(tools: [WeatherTool()]);
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
