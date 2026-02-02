// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'novel_idea.dart';

// **************************************************************************
// GenerableGenerator
// **************************************************************************

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
      genre: $GenreGenerable
          .fromGeneratedContent(GeneratedContent(content.value["genre"])),
    );
  }

  GeneratedContent toGeneratedContent() {
    return GeneratedContent({
      "title": title,
      "subtitle": subtitle,
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

  GeneratedContent toGeneratedContent() {
    return GeneratedContent(name);
  }
}
