import 'package:flutter_foundation_models/flutter_foundation_models.dart';

part 'novel_idea.g.dart';

@Generable()
class NovelIdea {
  @Guide(description: "A short title")
  final String title;

  @Guide(description: "A short subtitle for the novel")
  final String subtitle;

  @Guide(description: "The genre of the novel")
  final Genre genre;

  NovelIdea({
    required this.title,
    required this.subtitle,
    required this.genre,
  });
}

@Generable()
enum Genre { fiction, nonFiction }
