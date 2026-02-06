import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foundation_models/flutter_foundation_models.dart';
import 'package:flutter_foundation_models_example/weather_tool.dart';

class TranscriptDemo extends StatefulWidget {
  const TranscriptDemo({super.key});

  @override
  State<TranscriptDemo> createState() => _TranscriptDemoState();
}

class _TranscriptDemoState extends State<TranscriptDemo> {
  LanguageModelSession? _session;
  String? _savedTranscriptJson;
  List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;

  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _session?.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startNewSession() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _session?.dispose();
      _session = await LanguageModelSession.create(
        tools: [
          WeatherTool(
            temperature: 72.0,
            condition: "sunny",
          ),
        ],
        instructions: "You are a helpful assistant. When asked about weather, "
            "use the getWeather tool to get accurate information.",
      );

      setState(() {
        _messages = [];
        _savedTranscriptJson = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (_session == null || text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _messages.add(_ChatMessage(role: 'user', content: text));
    });

    _inputController.clear();
    _scrollToBottom();

    try {
      final response = await _session!.respondTo(text);

      setState(() {
        _messages.add(_ChatMessage(role: 'assistant', content: response.content));
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTranscript() async {
    if (_session == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final transcript = await _session!.transcript;
      setState(() {
        _savedTranscriptJson = transcript.toJson();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transcript saved (${transcript.length} entries)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreTranscript() async {
    if (_savedTranscriptJson == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _session?.dispose();

      final transcript = Transcript.fromJson(_savedTranscriptJson!);
      _session = await LanguageModelSession.createWithTranscript(
        tools: [
          WeatherTool(
            temperature: 72.0,
            condition: "sunny",
          ),
        ],
        transcript: transcript,
      );

      // Rebuild messages from transcript
      _rebuildMessagesFromTranscript(transcript);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transcript restored (${transcript.length} entries)'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _rebuildMessagesFromTranscript(Transcript transcript) {
    final messages = <_ChatMessage>[];

    for (final entry in transcript.entries) {
      switch (entry) {
        case TranscriptPrompt(:final text):
          messages.add(_ChatMessage(role: 'user', content: text));
        case TranscriptResponse(:final text):
          messages.add(_ChatMessage(role: 'assistant', content: text));
        case TranscriptToolCalls(:final calls):
          for (final call in calls) {
            messages.add(_ChatMessage(
              role: 'tool',
              content: 'Tool: ${call.toolName} called',
              toolName: call.toolName,
            ));
          }
        case TranscriptToolOutput(:final toolName):
          messages.add(_ChatMessage(
            role: 'toolOutput',
            content: 'Tool output: $toolName',
            toolName: toolName,
          ));
        case TranscriptInstructions():
        case TranscriptUnknown():
          // Skip instructions and unknown entries in chat view
          break;
      }
    }

    setState(() {
      _messages = messages;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _viewTranscriptJson() async {
    if (_session == null) return;

    try {
      final transcript = await _session!.transcript;
      if (mounted) {
        final jsonString = transcript.toJson();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Expanded(child: Text('Raw Transcript JSON')),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: 'Copy to clipboard',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: jsonString));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SelectableText(
                jsonString,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _startNewSession,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _session == null || _isLoading ? null : _saveTranscript,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _savedTranscriptJson == null || _isLoading
                    ? null
                    : _restoreTranscript,
                icon: const Icon(Icons.restore, size: 18),
                label: const Text('Restore'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _session == null || _isLoading ? null : _viewTranscriptJson,
                icon: const Icon(Icons.code, size: 18),
                label: const Text('JSON'),
              ),
              const Spacer(),
              if (_savedTranscriptJson != null)
                Chip(
                  avatar: const Icon(Icons.check, size: 16),
                  label: const Text('Saved'),
                  backgroundColor: Colors.green.shade100,
                ),
            ],
          ),
        ),

        // Error display
        if (_error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.red.shade100,
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _error = null),
                ),
              ],
            ),
          ),

        // Chat messages
        Expanded(
          child: _session == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'Tap "New" to start a conversation',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Try asking about the weather to see tool calls!',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _MessageBubble(message: message);
                  },
                ),
        ),

        // Input area
        if (_session != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: _isLoading ? null : _sendMessage,
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading
                      ? null
                      : () => _sendMessage(_inputController.text),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ChatMessage {
  final String role;
  final String content;
  final String? toolName;

  _ChatMessage({
    required this.role,
    required this.content,
    this.toolName,
  });
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final isTool = message.role == 'tool';
    final isToolOutput = message.role == 'toolOutput';

    if (isTool || isToolOutput) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isTool ? Colors.orange.shade50 : Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isTool ? Colors.orange.shade200 : Colors.purple.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isTool ? Icons.build : Icons.output,
              size: 16,
              color: isTool ? Colors.orange.shade700 : Colors.purple.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              message.content,
              style: TextStyle(
                color: isTool ? Colors.orange.shade700 : Colors.purple.shade700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message.content),
      ),
    );
  }
}
