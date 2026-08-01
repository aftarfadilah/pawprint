import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../providers/chat_provider.dart';
import '../providers/pet_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/empty_state.dart';
import 'settings_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final chat = context.watch<ChatProvider>();
    final pet = context.watch<PetProvider>().pet;
    final scheme = Theme.of(context).colorScheme;

    if (!settings.openRouterApiKey.trim().isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI chat')),
        body: EmptyState(
          icon: Icons.smart_toy_outlined,
          title: 'Add an OpenRouter API key',
          message:
              'PawPrint uses a free OpenRouter model. Add your key in Settings to start chatting.',
          action: FilledButton.icon(
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Open Settings'),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ));
            },
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear conversation',
            onPressed: chat.messages.isEmpty
                ? null
                : () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Clear conversation?'),
                        content:
                            const Text('This will erase the current chat.'),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(false),
                              child: const Text('Cancel')),
                          FilledButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(true),
                              child: const Text('Clear')),
                        ],
                      ),
                    );
                    if (ok == true) await context.read<ChatProvider>().clear();
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          if (pet != null)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: scheme.surfaceContainerLow,
              child: Text(
                'Pet: ${pet.name} (${pet.species}${pet.breed == null ? '' : ' · ${pet.breed}'})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: chat.messages.isEmpty
                ? EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'Start a conversation',
                    message:
                        'Ask anything about ${pet?.name ?? 'your pet’'}s health, behavior, or care.',
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chat.messages.length,
                    itemBuilder: (_, i) =>
                        ChatBubble(message: chat.messages[i]),
                  ),
          ),
          if (chat.isBusy)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text('Thinking…',
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(
                    top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _send(chat, pet?.id),
                      decoration: InputDecoration(
                        hintText: 'Ask about your pet…',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: chat.isBusy ? null : () => _send(chat, pet?.id),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _send(ChatProvider chat, String? petId) {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    _ctrl.clear();
    final pet = petId == null
        ? null
        : context.read<PetProvider>().pet;
    chat.sendUserMessage(t, pet: pet);
    _scrollToEnd();
  }
}
