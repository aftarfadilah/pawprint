import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_message.dart';

class AiServiceException implements Exception {
  final String message;
  final int? statusCode;
  AiServiceException(this.message, {this.statusCode});
  @override
  String toString() => 'AiServiceException($statusCode): $message';
}

/// Calls OpenRouter's /chat/completions endpoint.
///
/// Free-model defaults to `inclusionai/ling-3.0-flash:free`. The API key is
/// a free OpenRouter account key (no card required) and is supplied by the
/// user in Settings.
class AiService {
  static const String _endpoint = 'https://openrouter.ai/api/v1/chat/completions';

  final String apiKey;
  final String model;
  final String systemPrompt;
  final http.Client _client;

  AiService({
    required this.apiKey,
    required this.model,
    required this.systemPrompt,
    http.Client? client,
  }) : _client = client ?? http.Client();

  bool get isConfigured => apiKey.trim().isNotEmpty;

  /// Sends the conversation and returns the assistant's reply.
  Future<String> chat(
    List<ChatMessage> history, {
    String? userContext,
    String? overrideModel,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    if (!isConfigured) {
      throw AiServiceException(
        'No OpenRouter API key set. Open Settings → AI Configuration to add one.',
      );
    }

    final messages = <Map<String, String>>[];
    messages.add({'role': 'system', 'content': _composeSystemPrompt(userContext)});
    for (final m in history) {
      if (m.role == ChatRole.system) continue;
      messages.add({'role': m.role.apiName, 'content': m.content});
    }

    final body = <String, dynamic>{
      'model': overrideModel ?? model,
      'messages': messages,
      'temperature': 0.6,
      'max_tokens': 600,
    };

    final req = http.Request('POST', Uri.parse(_endpoint))
      ..headers.addAll({
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'HTTP-Referer': 'https://pawprint.local',
        'X-Title': 'PawPrint',
      })
      ..body = jsonEncode(body);

    final streamed = await _client.send(req).timeout(timeout);
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AiServiceException(
        _humanizeError(res),
        statusCode: res.statusCode,
      );
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw AiServiceException('Empty response from model.');
    }
    final first = choices.first as Map<String, dynamic>;
    final msg = first['message'] as Map<String, dynamic>?;
    final content = msg?['content'] as String?;
    if (content == null || content.isEmpty) {
      throw AiServiceException('No content in model response.');
    }
    return content.trim();
  }

  String _composeSystemPrompt(String? userContext) {
    final base = systemPrompt.trim().isEmpty
        ? 'You are a helpful pet health assistant.'
        : systemPrompt.trim();
    if (userContext == null || userContext.trim().isEmpty) return base;
    return '$base\n\nContext about the pet:\n$userContext';
  }

  String _humanizeError(http.Response res) {
    try {
      final j = jsonDecode(res.body);
      final err = j is Map ? j['error'] : null;
      if (err is Map && err['message'] is String) {
        return err['message'] as String;
      }
    } catch (_) {}
    if (res.statusCode == 401) return 'API key rejected (401). Check your key in Settings.';
    if (res.statusCode == 402)
      return 'Account needs credits or the free model is rate-limited (402).';
    if (res.statusCode == 429) return 'Rate-limited by the provider (429). Try again shortly.';
    if (res.statusCode >= 500) return 'Provider is having trouble (${res.statusCode}). Try again.';
    return 'Request failed (${res.statusCode}).';
  }

  void dispose() => _client.close();
}
