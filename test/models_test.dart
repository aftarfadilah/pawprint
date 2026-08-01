// Minimal smoke test — keeps `flutter test` happy without
// requiring full app instantiation.
import 'package:flutter_test/flutter_test.dart';
import 'package:pawprint/models/app_settings.dart';
import 'package:pawprint/models/pet.dart';
import 'package:pawprint/models/reminder.dart';

void main() {
  group('Pet JSON round-trip', () {
    test('preserves all fields', () {
      final p = Pet(
        id: 'abc',
        name: 'Milo',
        species: 'Cat',
        breed: 'Tabby',
        currentWeightKg: 4.2,
        sex: 'Male',
      );
      final restored = Pet.fromRawJson(p.toRawJson());
      expect(restored.id, 'abc');
      expect(restored.name, 'Milo');
      expect(restored.species, 'Cat');
      expect(restored.breed, 'Tabby');
      expect(restored.currentWeightKg, 4.2);
      expect(restored.sex, 'Male');
    });
  });

  group('Reminder JSON round-trip', () {
    test('preserves type and due date', () {
      final r = Reminder(
        id: 'r1',
        petId: 'p1',
        title: 'Vaccine',
        dueDate: DateTime.utc(2026, 9, 1, 10, 0),
        type: ReminderType.vaccine,
      );
      final restored = Reminder.fromRawJson(r.toRawJson());
      expect(restored.id, 'r1');
      expect(restored.title, 'Vaccine');
      expect(restored.type, ReminderType.vaccine);
      expect(restored.dueDate, r.dueDate);
    });
  });

  group('AppSettings', () {
    test('default has the OpenRouter free model', () {
      const s = AppSettings();
      expect(s.openRouterModel, 'inclusionai/ling-3.0-flash:free');
    });
    test('default system prompt is non-empty', () {
      expect(AppSettings.defaultSystemPrompt, isNotEmpty);
    });
  });
}
