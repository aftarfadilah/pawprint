import 'dart:convert';

enum ReminderType {
  vaccine,
  medication,
  grooming,
  vet,
  other,
}

extension ReminderTypeX on ReminderType {
  String get label {
    switch (this) {
      case ReminderType.vaccine:
        return 'Vaccine';
      case ReminderType.medication:
        return 'Medication';
      case ReminderType.grooming:
        return 'Grooming';
      case ReminderType.vet:
        return 'Vet visit';
      case ReminderType.other:
        return 'Other';
    }
  }

  static ReminderType parse(String s) {
    return ReminderType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => ReminderType.other,
    );
  }
}

class Reminder {
  final String id;
  final String petId;
  final String title;
  final String? notes;
  final DateTime dueDate;
  final ReminderType type;
  final bool completed;
  // Recurrence in days; 0 = one-shot
  final int repeatDays;

  const Reminder({
    required this.id,
    required this.petId,
    required this.title,
    required this.dueDate,
    this.notes,
    this.type = ReminderType.other,
    this.completed = false,
    this.repeatDays = 0,
  });

  bool get isOverdue =>
      !completed && dueDate.isBefore(DateTime.now());

  Duration get timeUntilDue => dueDate.difference(DateTime.now());

  Reminder copyWith({
    String? id,
    String? petId,
    String? title,
    String? notes,
    DateTime? dueDate,
    ReminderType? type,
    bool? completed,
    int? repeatDays,
  }) {
    return Reminder(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      dueDate: dueDate ?? this.dueDate,
      type: type ?? this.type,
      completed: completed ?? this.completed,
      repeatDays: repeatDays ?? this.repeatDays,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'petId': petId,
        'title': title,
        'notes': notes,
        'dueDate': dueDate.toIso8601String(),
        'type': type.name,
        'completed': completed,
        'repeatDays': repeatDays,
      };

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'] as String,
        petId: j['petId'] as String,
        title: j['title'] as String,
        notes: j['notes'] as String?,
        dueDate: DateTime.parse(j['dueDate'] as String),
        type: ReminderTypeX.parse(j['type'] as String? ?? 'other'),
        completed: (j['completed'] as bool?) ?? false,
        repeatDays: (j['repeatDays'] as int?) ?? 0,
      );

  String toRawJson() => jsonEncode(toJson());
  factory Reminder.fromRawJson(String s) =>
      Reminder.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
