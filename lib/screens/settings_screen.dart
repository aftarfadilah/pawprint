import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../providers/pet_provider.dart';
import '../providers/settings_provider.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _key = TextEditingController();
  final _model = TextEditingController();
  final _prompt = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsProvider>().settings;
    _key.text = s.openRouterApiKey;
    _model.text = s.openRouterModel;
    _prompt.text = s.systemPrompt;
  }

  @override
  void dispose() {
    _key.dispose();
    _model.dispose();
    _prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final pet = context.watch<PetProvider>().pet;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('AI Configuration'),
          ListTile(
            title: const Text('OpenRouter API key'),
            subtitle: Text(
              s.hasApiKey
                  ? '••••••••${_key.text.length < 4 ? '' : _key.text.substring(_key.text.length - 4)}'
                  : 'Not set — AI features disabled',
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: _editKey,
          ),
          ListTile(
            title: const Text('Model'),
            subtitle: Text(s.settings.openRouterModel),
            trailing: const Icon(Icons.edit_outlined),
            onTap: _editModel,
          ),
          ListTile(
            title: const Text('System prompt'),
            subtitle: Text(
              s.settings.systemPrompt.isEmpty
                  ? '(using default)'
                  : '${s.settings.systemPrompt.length} characters',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: _editPrompt,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'PawPrint uses free OpenRouter models. Get a free key at '
              'openrouter.ai — no credit card required.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ),
          const Divider(),
          const _SectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark mode'),
            value: s.darkMode,
            onChanged: (v) => s.setDarkMode(v),
          ),
          const Divider(),
          const _SectionHeader('Pet'),
          if (pet != null)
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit pet profile'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const OnboardingScreen(),
                ));
              },
            ),
          if (pet != null)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove pet (start over)'),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Remove pet?'),
                    content: const Text(
                        'This clears the pet profile. Reminders and logs stay.'),
                    actions: [
                      TextButton(
                          onPressed: () =>
                              Navigator.of(context).pop(false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () =>
                              Navigator.of(context).pop(true),
                          child: const Text('Remove')),
                    ],
                  ),
                );
                // No provider method to delete the pet yet; surface a TODO note
                if (ok == true && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Pet removal UI placeholder — re-add via Add Pet.')),
                  );
                }
              },
            ),
          const Divider(),
          const _SectionHeader('About'),
          const ListTile(
            title: Text('PawPrint'),
            subtitle: Text('AI Pet Health Tracker · v0.1.0'),
          ),
          const ListTile(
            title: Text('Disclaimer'),
            subtitle: Text(
              'PawPrint offers general guidance only. Always consult a licensed veterinarian for medical decisions.',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editKey() async {
    final ctl = TextEditingController(text: _key.text);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('OpenRouter API key'),
        content: TextField(
          controller: ctl,
          obscureText: _obscure,
          maxLines: 1,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'sk-or-...',
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      await context.read<SettingsProvider>().setApiKey(ctl.text.trim());
      _key.text = ctl.text.trim();
    }
  }

  Future<void> _editModel() async {
    const presets = [
      'inclusionai/ling-3.0-flash:free',
      'meta-llama/llama-3.3-70b-instruct:free',
      'qwen/qwen-2.5-72b-instruct:free',
      'google/gemini-2.0-flash-exp:free',
    ];
    final ctl = TextEditingController(text: _model.text);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Model'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctl,
                decoration: const InputDecoration(
                  labelText: 'Model id',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Free presets:')),
              for (final p in presets)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => ctl.text = p,
                    child: Text(p),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      await context.read<SettingsProvider>().setModel(ctl.text.trim());
      _model.text = ctl.text.trim();
    }
  }

  Future<void> _editPrompt() async {
    final ctl = TextEditingController(text: _prompt.text);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('System prompt'),
        content: SingleChildScrollView(
          child: TextField(
            controller: ctl,
            minLines: 5,
            maxLines: 14,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Leave blank to use the default prompt.',
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                ctl.text = AppSettings.defaultSystemPrompt;
              },
              child: const Text('Reset default')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      await context.read<SettingsProvider>().setSystemPrompt(ctl.text);
      _prompt.text = ctl.text;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
