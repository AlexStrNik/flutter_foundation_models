import 'package:flutter/material.dart';
import 'package:flutter_foundation_models/flutter_foundation_models.dart';
import 'package:flutter_foundation_models_example/novel_idea.dart';

class _NovelGeneratorState extends State<NovelGenerator> {
  late LanguageModelSession _session;

  NovelIdea? novelIdea;

  @override
  void initState() {
    super.initState();

    _session = LanguageModelSession();
  }

  Future<void> generateNew() async {
    final schema = $NovelIdeaGenerable.generationSchema;
    final generatedContent = await _session.respondWithSchema(
      to: "Generate random novel idea",
      schema: schema,
    );

    setState(() {
      novelIdea = $NovelIdeaConvertibleFromGeneratedContent.fromGeneratedContent(generatedContent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: generateNew,
          child: const Text("Generate New Idea"),
        ),
        if (novelIdea != null)
          Column(
            children: [
              Text(novelIdea!.title),
              Text(novelIdea!.subtitle),
              Text(novelIdea!.genre.name),
            ],
          )
      ],
    );
  }
}

class NovelGenerator extends StatefulWidget {
  const NovelGenerator({super.key});

  @override
  State<NovelGenerator> createState() => _NovelGeneratorState();
}
