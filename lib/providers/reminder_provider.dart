import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/reminder.dart';
import '../services/storage_service.dart';

class ReminderProvider extends ChangeNotifier {
  final StorageService _storage;
  List<Reminder> _reminders = [];
  static const _uuid = Uuid();

  ReminderProvider(this._storage) {
    _reminders = _storage.loadReminders();
  }

  List<Reminder> get all => List.unmodifiable(_reminders);
  List<Reminder> forPet(String petId) =>
      _reminders.where((r) => r.petId == petId).toList();

  /// Reminders that are still pending and due within `windowDays` ahead
  /// (overdue items always included).
  List<Reminder> upcoming({int windowDays = 30}) {
    final now = DateTime.now();
    final end = now.add(Duration(days: windowDays));
    return _reminders
        .where((r) => !r.completed && r.dueDate.isBefore(end))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<Reminder> get overdue =>
      _reminders.where((r) => r.isOverdue).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  Future<Reminder> add({
    required String petId,
    required String title,
    required DateTime dueDate,
    ReminderType type = ReminderType.other,
    String? notes,
    int repeatDays = 0,
  }) async {
    final r = Reminder(
      id: _uuid.v4(),
      petId: petId,
      title: title.trim(),
      dueDate: dueDate,
      type: type,
      notes: notes,
      repeatDays: repeatDays,
    );
    _reminders = [..._reminders, r]
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    await _storage.saveReminders(_reminders);
    notifyListeners();
    return r;
  }

  Future<void> toggleComplete(String id) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx < 0) return;
    final r = _reminders[idx];
    final updated = r.copyWith(completed: !r.completed);
    _reminders = [..._reminders]..[idx] = updated;
    if (updated.completed && updated.repeatDays > 0) {
      // schedule the next occurrence
      final next = updated.copyWith(
        completed: false,
        dueDate: updated.dueDate.add(Duration(days: updated.repeatDays)),
      );
      _reminders = [..._reminders, next];
    }
    _reminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    await _storage.saveReminders(_reminders);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _reminders = _reminders.where((r) => r.id != id).toList();
    await _storage.saveReminders(_reminders);
    notifyListeners();
  }

  Future<void> update(Reminder r) async {
    final idx = _reminders.indexWhere((x) => x.id == r.id);
    if (idx < 0) return;
    _reminders = [..._reminders]..[idx] = r;
    _reminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    await _storage.saveReminders(_reminders);
    notifyListeners();
  }
}
