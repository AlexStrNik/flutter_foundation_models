// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'novel_idea.dart';

// **************************************************************************
// GenerableGenerator
// **************************************************************************

/// Partial version of [NovelIdea] for streaming responses.
/// All fields are optional as they may not be fully generated yet.
class $NovelIdeaPartial {
  final String? title;
  final String? subtitle;
  final String? description;
  final Genre? genre;

  $NovelIdeaPartial({
    this.title,
    this.subtitle,
    this.description,
    this.genre,
  });
}

extension $NovelIdeaGenerable on NovelIdea {
  static GenerationSchema get generationSchema {
    final root = StructGenerationSchema(
      name: "NovelIdea",
      properties: [
        DynamicGenerationSchemaProperty(
          name: "title",
          description: "A short title",
          schema: ValueGenerationSchema(type: "String"),
        ),
        DynamicGenerationSchemaProperty(
          name: "subtitle",
          description: "A short subtitle for the novel",
          schema: ValueGenerationSchema(type: "String"),
        ),
        DynamicGenerationSchemaProperty(
          name: "description",
          description: "A full description of your idea. Minimum 100 words",
          schema: ValueGenerationSchema(type: "String"),
        ),
        DynamicGenerationSchemaProperty(
          name: "genre",
          description: "The genre of the novel",
          schema: $GenreGenerable.generationSchema.root,
        ),
      ],
    );
    final dependencies = <DynamicGenerationSchema>[];
    return GenerationSchema(
      root: root,
      dependencies: dependencies,
    );
  }

  static NovelIdea fromGeneratedContent(GeneratedContent content) {
    return NovelIdea(
      title: content.value["title"] as String,
      subtitle: content.value["subtitle"] as String,
      description: content.value["description"] as String,
      genre: $GenreGenerable
          .fromGeneratedContent(GeneratedContent(content.value["genre"])),
    );
  }

  static $NovelIdeaPartial fromPartialGeneratedContent(
      GeneratedContent content) {
    return $NovelIdeaPartial(
      title: content.value["title"] != null
          ? content.value["title"] as String?
          : null,
      subtitle: content.value["subtitle"] != null
          ? content.value["subtitle"] as String?
          : null,
      description: content.value["description"] != null
          ? content.value["description"] as String?
          : null,
      genre: content.value["genre"] != null
          ? $GenreGenerable.fromPartialGeneratedContent(
              GeneratedContent(content.value["genre"]))
          : null,
    );
  }

  GeneratedContent toGeneratedContent() {
    return GeneratedContent({
      "title": title,
      "subtitle": subtitle,
      "description": description,
      "genre": genre.toGeneratedContent().value,
    });
  }
}

extension $GenreGenerable on Genre {
  static GenerationSchema get generationSchema {
    final schema = AnyOfStringsGenerationSchema(
      name: "Genre",
      anyOf: [
        "fiction",
        "nonFiction",
      ],
    );
    return GenerationSchema(
      root: schema,
      dependencies: [],
    );
  }

  static Genre fromGeneratedContent(GeneratedContent content) {
    return Genre.values.firstWhere(
      (e) => e.name == content.value,
      orElse: () => throw ArgumentError("Unknown enum value: ${content.value}"),
    );
  }

  static Genre? fromPartialGeneratedContent(GeneratedContent content) {
    if (content.value == null) return null;
    return Genre.values.cast<Genre?>().firstWhere(
          (e) => e?.name == content.value,
          orElse: () => null,
        );
  }

  GeneratedContent toGeneratedContent() {
    return GeneratedContent(name);
  }
}
