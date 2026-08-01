import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/pet.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import 'settings_provider.dart';

class ChatProvider extends ChangeNotifier {
  final StorageService _storage;
  final SettingsProvider _settings;
  List<ChatMessage> _messages = [];
  bool _busy = false;
  String? _error;
  static const _uuid = Uuid();

  ChatProvider(this._storage, this._settings) {
    _messages = _storage.loadChat();
  }

  AiService _buildAi() => AiService(
        apiKey: _settings.openRouterApiKey,
        model: _settings.openRouterModel,
        systemPrompt: _settings.systemPrompt,
      );

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isBusy => _busy;
  String? get error => _error;

  Future<void> sendUserMessage(String text, {Pet? pet}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final user = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.user,
      content: trimmed,
      timestamp: DateTime.now(),
    );
    _messages = [..._messages, user];
    _busy = true;
    _error = null;
    notifyListeners();
    await _storage.saveChat(_messages);

    try {
      final ai = _buildAi();
      final ctx = pet == null ? null : _petContext(pet);
      final reply = await ai.chat(_messages, userContext: ctx);
      final assistant = ChatMessage(
        id: _uuid.v4(),
        role: ChatRole.assistant,
        content: reply,
        timestamp: DateTime.now(),
      );
      _messages = [..._messages, assistant];
      await _storage.saveChat(_messages);
    } on AiServiceException catch (e) {
      _error = e.message;
      _messages = [
        ..._messages,
        ChatMessage(
          id: _uuid.v4(),
          role: ChatRole.assistant,
          content: e.message,
          timestamp: DateTime.now(),
          isError: true,
        ),
      ];
      await _storage.saveChat(_messages);
    } catch (e) {
      _error = 'Unexpected error: $e';
      _messages = [
        ..._messages,
        ChatMessage(
          id: _uuid.v4(),
          role: ChatRole.assistant,
          content: 'Something went wrong. Please try again.',
          timestamp: DateTime.now(),
          isError: true,
        ),
      ];
      await _storage.saveChat(_messages);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> clear() async {
    _messages = [];
    await _storage.clearChat();
    _error = null;
    notifyListeners();
  }

  String _petContext(Pet p) {
    final lines = <String>[
      'Name: ${p.name}',
      'Species: ${p.species}',
      if (p.breed != null) 'Breed: ${p.breed}',
      if (p.birthDate != null) 'Age: ${p.ageLabel}',
      if (p.currentWeightKg != null) 'Weight: ${p.currentWeightKg!.toStringAsFixed(2)} kg',
      if (p.sex != null) 'Sex: ${p.sex}',
      if (p.notes != null && p.notes!.isNotEmpty) 'Notes: ${p.notes}',
    ];
    return lines.join('\n');
  }
}
