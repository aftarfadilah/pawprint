import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;
  AppSettings _settings;

  SettingsProvider(this._storage) : _settings = _storage.loadSettings();

  AppSettings get settings => _settings;
  String get openRouterApiKey => _settings.openRouterApiKey;
  String get openRouterModel => _settings.openRouterModel;
  String get systemPrompt => _settings.systemPrompt.isEmpty
      ? AppSettings.defaultSystemPrompt
      : _settings.systemPrompt;
  bool get darkMode => _settings.darkMode;
  bool get hasApiKey => _settings.openRouterApiKey.trim().isNotEmpty;
  bool get hasOnboarded => _settings.hasOnboarded;

  Future<void> setApiKey(String key) async {
    _settings = _settings.copyWith(openRouterApiKey: key.trim());
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setModel(String model) async {
    _settings = _settings.copyWith(openRouterModel: model.trim());
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setSystemPrompt(String prompt) async {
    _settings = _settings.copyWith(systemPrompt: prompt);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setDarkMode(bool v) async {
    _settings = _settings.copyWith(darkMode: v);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setOnboarded(bool v) async {
    _settings = _settings.copyWith(hasOnboarded: v);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> reset() async {
    _settings = const AppSettings();
    await _storage.saveSettings(_settings);
    notifyListeners();
  }
}
