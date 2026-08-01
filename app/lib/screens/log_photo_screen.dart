import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/pet.dart';
import '../providers/health_log_provider.dart';
import '../providers/pet_provider.dart';
import '../services/image_service.dart';

class LogPhotoScreen extends StatefulWidget {
  const LogPhotoScreen({super.key});
  @override
  State<LogPhotoScreen> createState() => _LogPhotoScreenState();
}

class _LogPhotoScreenState extends State<LogPhotoScreen> {
  final _img = ImageService();
  final _notes = TextEditingController();
  String? _photoBase64;
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final url = await _img.pickAsDataUrl();
    if (url != null) setState(() => _photoBase64 = url);
  }

  Future<void> _save(Pet pet) async {
    if (_photoBase64 == null) return;
    setState(() => _saving = true);
    await context.read<HealthLogProvider>().addPhoto(
          petId: pet.id,
          imageBase64: _photoBase64!,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final pet = (ModalRoute.of(context)!.settings.arguments as Pet?) ??
        context.read<PetProvider>().pet!;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('Log photo · ${pet.name}')),
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
              child: _photoBase64 == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              size: 48, color: scheme.onSurfaceVariant),
                          const SizedBox(height: 8),
                          Text('No photo yet',
                              style: TextStyle(color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : Image.network(_photoBase64!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                  onPressed: () async {
                    final url = await _img.pickAsDataUrl(
                        source: ImageSource.gallery);
                    if (url != null) setState(() => _photoBase64 = url);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Camera'),
                  onPressed: () async {
                    final url = await _img.pickAsDataUrl(
                        source: ImageSource.camera);
                    if (url != null) setState(() => _photoBase64 = url);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: Text(_saving ? 'Saving…' : 'Save photo'),
            onPressed: (_saving || _photoBase64 == null) ? null : () => _save(pet),
          ),
        ],
      ),
    );
  }
}
