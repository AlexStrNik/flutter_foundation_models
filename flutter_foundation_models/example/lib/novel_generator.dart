import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_foundation_models/flutter_foundation_models.dart';
import 'package:flutter_foundation_models_example/novel_idea.dart';

class _NovelGeneratorState extends State<NovelGenerator> {
  LanguageModelSession? _session;

  $NovelIdeaPartial? partialNovelIdea;
  NovelIdea? novelIdea;
  bool isStreaming = false;
  bool isInitializing = true;
  StreamSubscription<GeneratedContent>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    _session = await LanguageModelSession.create();
    if (mounted) {
      setState(() {
        isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _session?.dispose();
    super.dispose();
  }

  Future<void> generateNew() async {
    if (_session == null) return;
    final schema = $NovelIdeaGenerable.generationSchema;
    final generatedContent = await _session!.respondToWithSchema(
      "Generate random novel idea",
      schema: schema,
    );

    setState(() {
      novelIdea = $NovelIdeaGenerable.fromGeneratedContent(generatedContent);
      partialNovelIdea = null;
    });
  }

  void generateNewStreaming() {
    if (_session == null) return;
    setState(() {
      isStreaming = true;
      novelIdea = null;
      partialNovelIdea = null;
    });

    final schema = $NovelIdeaGenerable.generationSchema;
    final stream = _session!.streamResponseToWithSchema(
      "Generate random novel idea",
      schema: schema,
    );

    _streamSubscription = stream.listen(
      (partialContent) {
        setState(() {
          partialNovelIdea = $NovelIdeaGenerable.fromPartialGeneratedContent(partialContent);
        });
      },
      onDone: () {
        setState(() {
          isStreaming = false;
          // Convert the final partial to complete if all fields are present
          if (partialNovelIdea != null &&
              partialNovelIdea!.title != null &&
              partialNovelIdea!.subtitle != null &&
              partialNovelIdea!.description != null &&
              partialNovelIdea!.genre != null) {
            novelIdea = NovelIdea(
              title: partialNovelIdea!.title!,
              subtitle: partialNovelIdea!.subtitle!,
              description: partialNovelIdea!.description!,
              genre: partialNovelIdea!.genre!,
            );
          }
        });
      },
      onError: (error) {
        setState(() {
          isStreaming = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error')),
          );
        }
      },
    );
  }

  void cancelStreaming() {
    _streamSubscription?.cancel();
    setState(() {
      isStreaming = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isStreaming ? null : generateNew,
                  child: const Text("Generate (One-shot)"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: isStreaming ? cancelStreaming : generateNewStreaming,
                  child: Text(isStreaming ? "Cancel" : "Generate (Streaming)"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (isStreaming) const LinearProgressIndicator(),
          const SizedBox(height: 16),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Show streaming partial content
    if (partialNovelIdea != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isStreaming)
                const Text(
                  "Generating...",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                partialNovelIdea!.title ?? "...",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                partialNovelIdea!.subtitle ?? "...",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Text(partialNovelIdea!.description ?? "..."),
              const SizedBox(height: 8),
              Chip(
                label: Text(partialNovelIdea!.genre?.name ?? "..."),
              ),
            ],
          ),
        ),
      );
    }

    // Show completed content
    if (novelIdea != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                novelIdea!.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                novelIdea!.subtitle,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Text(novelIdea!.description),
              const SizedBox(height: 8),
              Chip(
                label: Text(novelIdea!.genre.name),
              ),
            ],
          ),
        ),
      );
    }

    // Initial state
    return const Center(
      child: Text(
        "Press a button to generate a novel idea",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}

class NovelGenerator extends StatefulWidget {
  const NovelGenerator({super.key});

  @override
  State<NovelGenerator> createState() => _NovelGeneratorState();
}
