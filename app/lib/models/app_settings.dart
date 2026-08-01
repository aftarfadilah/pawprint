import 'dart:convert';

class AppSettings {
  final String openRouterApiKey;
  final String openRouterModel;
  final String systemPrompt;
  final bool darkMode;
  final bool hasOnboarded;

  const AppSettings({
    this.openRouterApiKey = '',
    this.openRouterModel = 'inclusionai/ling-3.0-flash:free',
    this.systemPrompt = '',
    this.darkMode = false,
    this.hasOnboarded = false,
  });

  static const String defaultSystemPrompt =
      'You are a friendly, careful pet health assistant. You give general '
      'information and home-care suggestions but you are NOT a veterinarian. '
      'When the user describes symptoms or a condition that sounds serious, '
      'urgent, or worsening, recommend they contact a licensed vet immediately. '
      'Be warm, concise, and practical. Use plain language.';

  AppSettings copyWith({
    String? openRouterApiKey,
    String? openRouterModel,
    String? systemPrompt,
    bool? darkMode,
    bool? hasOnboarded,
  }) {
    return AppSettings(
      openRouterApiKey: openRouterApiKey ?? this.openRouterApiKey,
      openRouterModel: openRouterModel ?? this.openRouterModel,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      darkMode: darkMode ?? this.darkMode,
      hasOnboarded: hasOnboarded ?? this.hasOnboarded,
    );
  }

  Map<String, dynamic> toJson() => {
        'openRouterApiKey': openRouterApiKey,
        'openRouterModel': openRouterModel,
        'systemPrompt': systemPrompt.isEmpty ? defaultSystemPrompt : systemPrompt,
        'darkMode': darkMode,
        'hasOnboarded': hasOnboarded,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        openRouterApiKey: (j['openRouterApiKey'] as String?) ?? '',
        openRouterModel: (j['openRouterModel'] as String?) ??
            'inclusionai/ling-3.0-flash:free',
        systemPrompt: (j['systemPrompt'] as String?) ?? defaultSystemPrompt,
        darkMode: (j['darkMode'] as bool?) ?? false,
        hasOnboarded: (j['hasOnboarded'] as bool?) ?? false,
      );

  String toRawJson() => jsonEncode(toJson());
  factory AppSettings.fromRawJson(String s) =>
      AppSettings.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
