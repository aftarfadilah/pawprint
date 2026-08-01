import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/chat_message.dart';
import '../models/health_log.dart';
import '../models/pet.dart';
import '../models/reminder.dart';

/// Thin wrapper around SharedPreferences that serializes all our app data.
class StorageService {
  static const _kPet = 'pawprint.pet.v1';
  static const _kPets = 'pawprint.pets.v1'; // for future multi-pet support
  static const _kLogs = 'pawprint.logs.v1';
  static const _kReminders = 'pawprint.reminders.v1';
  static const _kChat = 'pawprint.chat.v1';
  static const _kSettings = 'pawprint.settings.v1';

  final SharedPreferences _prefs;
  StorageService(this._prefs);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // ─── Pet ──────────────────────────────────────────────────────────────
  Pet? loadPet() {
    final raw = _prefs.getString(_kPet);
    if (raw == null) return null;
    try {
      return Pet.fromRawJson(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> savePet(Pet pet) async {
    await _prefs.setString(_kPet, pet.toRawJson());
  }

  // ─── Health logs ──────────────────────────────────────────────────────
  List<HealthLog> loadLogs() {
    final raw = _prefs.getStringList(_kLogs) ?? const <String>[];
    final out = <HealthLog>[];
    for (final s in raw) {
      try {
        out.add(HealthLog.fromRawJson(s));
      } catch (_) {/* skip bad rows */}
    }
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  Future<void> saveLogs(List<HealthLog> logs) async {
    final raw = logs.map((l) => l.toRawJson()).toList();
    await _prefs.setStringList(_kLogs, raw);
  }

  // ─── Reminders ───────────────────────────────────────────────────────
  List<Reminder> loadReminders() {
    final raw = _prefs.getStringList(_kReminders) ?? const <String>[];
    final out = <Reminder>[];
    for (final s in raw) {
      try {
        out.add(Reminder.fromRawJson(s));
      } catch (_) {/* skip */}
    }
    out.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return out;
  }

  Future<void> saveReminders(List<Reminder> reminders) async {
    final raw = reminders.map((r) => r.toRawJson()).toList();
    await _prefs.setStringList(_kReminders, raw);
  }

  // ─── Chat ────────────────────────────────────────────────────────────
  List<ChatMessage> loadChat() {
    final raw = _prefs.getStringList(_kChat) ?? const <String>[];
    final out = <ChatMessage>[];
    for (final s in raw) {
      try {
        out.add(ChatMessage.fromRawJson(s));
      } catch (_) {/* skip */}
    }
    return out;
  }

  Future<void> saveChat(List<ChatMessage> messages) async {
    final raw = messages.map((m) => m.toRawJson()).toList();
    await _prefs.setStringList(_kChat, raw);
  }

  Future<void> clearChat() async {
    await _prefs.remove(_kChat);
  }

  // ─── Settings ────────────────────────────────────────────────────────
  AppSettings loadSettings() {
    final raw = _prefs.getString(_kSettings);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromRawJson(raw);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings s) async {
    await _prefs.setString(_kSettings, s.toRawJson());
  }

  // ─── Wipe ────────────────────────────────────────────────────────────
  Future<void> wipeAll() async {
    await _prefs.remove(_kPet);
    await _prefs.remove(_kLogs);
    await _prefs.remove(_kReminders);
    await _prefs.remove(_kChat);
    await _prefs.remove(_kSettings);
  }

  // helper for debugging
  String dumpKeys() {
    final keys = _prefs.getKeys().toList()..sort();
    final data = keys.map((k) {
      final v = _prefs.get(k);
      final s = v is String ? v : jsonEncode(v);
      return '$k -> ${s.length > 60 ? '${s.substring(0, 60)}…' : s}';
    });
    return data.join('\n');
  }
}
