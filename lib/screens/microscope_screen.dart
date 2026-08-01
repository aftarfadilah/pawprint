import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../models/chat_message.dart';
import '../models/pet.dart';
import '../providers/chat_provider.dart';
import '../providers/health_log_provider.dart';
import '../providers/pet_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import '../services/image_service.dart';

/// "Microscope" — take a close-up sample image, ask the AI to help interpret.
/// The free text model is given the user's description and a guidance prompt.
class MicroscopeScreen extends StatefulWidget {
  const MicroscopeScreen({super.key});
  @override
  State<MicroscopeScreen> createState() => _MicroscopeScreenState();
}

class _MicroscopeScreenState extends State<MicroscopeScreen> {
  final _img = ImageService();
  final _desc = TextEditingController();
  final _notes = TextEditingController();
  String? _imageBase64;
  String? _result;
  bool _busy = false;

  @override
  void dispose() {
    _desc.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final url = await _img.pickAsDataUrl(source: ImageSource.camera);
    if (url != null) setState(() => _imageBase64 = url);
  }

  Future<void> _pickGallery() async {
    final url = await _img.pickAsDataUrl(source: ImageSource.gallery);
    if (url != null) setState(() => _imageBase64 = url);
  }

  Future<void> _analyze(Pet pet, AppSettings settings) async {
    if (!_img.isWeb && _imageBase64 == null) {
      // On non-web we still allow description-only analysis.
    }
    if (_desc.text.trim().isEmpty && _imageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Add a photo or describe the sample to analyze.')),
      );
      return;
    }
    setState(() {
      _busy = true;
      _result = null;
    });
    final ai = AiService(
      apiKey: settings.openRouterApiKey,
      model: settings.openRouterModel,
      systemPrompt: settings.systemPrompt,
    );
    try {
      final prompt = _composePrompt(pet);
      final reply = await ai.chat(
        [
          ChatMessage(
            id: 'microscope-${DateTime.now().millisecondsSinceEpoch}',
            role: ChatRole.user,
            content: prompt,
            timestamp: DateTime.now(),
          ),
        ],
        userContext: 'User is asking for help analyzing a close-up sample '
            'image of their pet (e.g. skin, fur, ear, stool). They may attach '
            'a description since the model is text-only.',
      );
      setState(() => _result = reply);
    } on AiServiceException catch (e) {
      setState(() => _result = '⚠️ ${e.message}');
    } catch (e) {
      setState(() => _result = '⚠️ Unexpected error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  String _composePrompt(Pet pet) {
    final desc = _desc.text.trim();
    final hasImg = _imageBase64 != null;
    final base = 'I’m looking at a close-up sample from my pet '
        '${pet.name} (${pet.species}, ${pet.ageLabel}).';
    final d = desc.isEmpty ? '' : '\n\nDescription: $desc';
    final i = hasImg
        ? '\n\n(I have attached a photo of the sample. As a text-only model, please reason from my description and ask me for any clarifications you need.)'
        : '';
    final ask =
        '\n\nWhat are the most likely things this could be, what home-care steps should I consider, and when should I see a vet urgently? Please keep your answer focused and practical.';
    return '$base$d$i$ask';
  }

  Future<void> _saveLog(Pet pet) async {
    if (_result == null) return;
    await context.read<HealthLogProvider>().addMicroscope(
          petId: pet.id,
          imageBase64: _imageBase64 ?? '',
          aiSummary: _result,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to health log.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = context.watch<PetProvider>().pet;
    final settings = context.watch<SettingsProvider>().settings;
    final scheme = Theme.of(context).colorScheme;

    if (pet == null) {
      return const Scaffold(body: Center(child: Text('Add a pet first.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Microscope')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: _imageBase64 == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.biotech_outlined,
                              size: 48, color: scheme.onSurfaceVariant),
                          const SizedBox(height: 8),
                          Text('No sample image',
                              style: TextStyle(color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : Image.network(_imageBase64!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Camera'),
                  onPressed: _pick,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                  onPressed: _pickGallery,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Describe what you see',
              hintText:
                  'e.g. small red bump behind the ear, no discharge, itchy',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.auto_awesome),
            label: Text(_busy ? 'Analyzing…' : 'Analyze with AI'),
            onPressed: _busy || !settings.openRouterApiKey.trim().isNotEmpty
                ? null
                : () => _analyze(pet, settings),
          ),
          if (!settings.openRouterApiKey.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Add your OpenRouter API key in Settings → AI Configuration to enable analysis.',
              style: TextStyle(color: scheme.error, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            Card(
              color: scheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology_outlined,
                            color: scheme.onSecondaryContainer),
                        const SizedBox(width: 8),
                        Text('AI assessment',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: scheme.onSecondaryContainer,
                                )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _result!,
                      style: TextStyle(color: scheme.onSecondaryContainer),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonalIcon(
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save to log'),
                        onPressed: _busy ? null : () => _saveLog(pet),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '⚠️ AI suggestions are not a substitute for a vet visit. If '
              'symptoms are severe or worsening, contact a licensed vet.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
