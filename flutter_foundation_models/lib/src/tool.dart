import 'package:flutter_foundation_models/flutter_foundation_models.dart';

/// Base class for defining tools that can be called by the language model.
///
/// Tools allow the language model to perform actions or retrieve information
/// that it cannot do on its own, such as fetching live data, performing
/// calculations, or interacting with external services.
///
/// To create a tool, extend this class and implement:
/// - [name] - A unique identifier for the tool
/// - [description] - A description of what the tool does (used by the model)
/// - [parameters] - The schema defining the tool's input parameters
/// - [call] - The function that executes when the model calls the tool
///
/// Example:
/// ```dart
/// @Generable()
/// class WeatherArgs {
///   @Guide(description: "The city to get weather for")
///   final String city;
///   WeatherArgs({required this.city});
/// }
///
/// class WeatherTool extends Tool {
///   @override
///   String name = "getWeather";
///
///   @override
///   String description = "Get current weather for a city";
///
///   @override
///   GenerationSchema get parameters => $WeatherArgsGenerable.generationSchema;
///
///   @override
///   Future<GeneratedContent> call(GeneratedContent arguments) async {
///     final args = $WeatherArgsGenerable.fromGeneratedContent(arguments);
///     // Fetch weather data...
///     return WeatherResult(temperature: 72, condition: "sunny").toGeneratedContent();
///   }
/// }
/// ```
abstract class Tool {
  /// The unique name of this tool.
  ///
  /// This name is used by the model to identify and call the tool.
  /// Should be descriptive and use camelCase (e.g., "getWeather", "searchDatabase").
  String get name;

  /// A description of what this tool does.
  ///
  /// This description is provided to the language model to help it understand
  /// when and how to use the tool. Be clear and specific about the tool's
  /// purpose and capabilities.
  String get description;

  /// The schema defining the tool's input parameters.
  ///
  /// Use the generated schema from a @Generable class to define the
  /// structure of arguments the tool accepts.
  GenerationSchema get parameters;

  /// Executes the tool with the given arguments.
  ///
  /// [arguments] - The arguments passed by the model, conforming to [parameters].
  ///
  /// Returns [GeneratedContent] containing the tool's result, which will be
  /// passed back to the model to formulate its response.
  Future<GeneratedContent> call(GeneratedContent arguments);

  /// Converts this tool to a JSON representation.
  Map<String, dynamic> toJson() => {
        "name": name,
        "description": description,
        "parameters": parameters.toJson(),
      };
}
