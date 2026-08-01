import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pet_provider.dart';
import '../services/image_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _breed = TextEditingController();
  final _weight = TextEditingController();
  String _species = 'Cat';
  String _sex = 'Male';
  DateTime? _birth;
  String? _photoBase64;
  final _img = ImageService();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final url = await _img.pickAsDataUrl();
    if (url != null) setState(() => _photoBase64 = url);
  }

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(now.year - 2, now.month, now.day),
      firstDate: DateTime(now.year - 30),
      lastDate: now,
    );
    if (picked != null) setState(() => _birth = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final w = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    await context.read<PetProvider>().createPet(
          name: _name.text.trim(),
          species: _species,
          breed: _breed.text.trim().isEmpty ? null : _breed.text.trim(),
          birthDate: _birth,
          photoBase64: _photoBase64,
          currentWeightKg: w,
          sex: _sex,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Add your pet')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primaryContainer,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _photoBase64 != null
                      ? Image.network(_photoBase64!, fit: BoxFit.cover)
                      : Icon(Icons.add_a_photo_outlined,
                          size: 40, color: scheme.onPrimaryContainer),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please give a name' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _species,
              decoration: const InputDecoration(
                labelText: 'Species',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Cat', child: Text('Cat')),
                DropdownMenuItem(value: 'Dog', child: Text('Dog')),
                DropdownMenuItem(value: 'Rabbit', child: Text('Rabbit')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _species = v ?? 'Cat'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _breed,
              decoration: const InputDecoration(
                labelText: 'Breed (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _sex,
              decoration: const InputDecoration(
                labelText: 'Sex',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Unknown', child: Text('Unknown')),
              ],
              onChanged: (v) => setState(() => _sex = v ?? 'Male'),
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              title: const Text('Birth date'),
              subtitle: Text(_birth == null
                  ? 'Tap to choose'
                  : '${_birth!.year}-${_birth!.month.toString().padLeft(2, '0')}-${_birth!.day.toString().padLeft(2, '0')}'),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickBirth,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weight,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Current weight (kg, optional)',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = double.tryParse(v.trim().replaceAll(',', '.'));
                if (n == null || n <= 0) return 'Enter a number in kg';
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: Text(_saving ? 'Saving…' : 'Save'),
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
