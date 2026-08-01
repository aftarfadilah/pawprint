import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/health_log.dart';
import '../services/storage_service.dart';

class HealthLogProvider extends ChangeNotifier {
  final StorageService _storage;
  List<HealthLog> _logs = [];
  static const _uuid = Uuid();

  HealthLogProvider(this._storage) {
    _logs = _storage.loadLogs();
  }

  List<HealthLog> get all => List.unmodifiable(_logs);

  List<HealthLog> forPet(String petId) =>
      _logs.where((l) => l.petId == petId).toList();

  /// Most recent N entries across all types.
  List<HealthLog> recent({int limit = 10}) {
    final copy = [..._logs]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return copy.take(limit).toList();
  }

  Future<HealthLog> add(HealthLog log) async {
    _logs = [log, ..._logs];
    _logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _storage.saveLogs(_logs);
    notifyListeners();
    return log;
  }

  /// Convenience builder.
  Future<HealthLog> addPhoto({
    required String petId,
    required String imageBase64,
    String? notes,
  }) {
    return add(HealthLog(
      id: _uuid.v4(),
      petId: petId,
      type: HealthLogType.photo,
      createdAt: DateTime.now(),
      imageBase64: imageBase64,
      notes: notes,
    ));
  }

  Future<HealthLog> addWeight({
    required String petId,
    required double kg,
    String? notes,
  }) {
    return add(HealthLog(
      id: _uuid.v4(),
      petId: petId,
      type: HealthLogType.weight,
      createdAt: DateTime.now(),
      weightKg: kg,
      notes: notes,
    ));
  }

  Future<HealthLog> addMedicine({
    required String petId,
    required String name,
    String? dosage,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
  }) {
    return add(HealthLog(
      id: _uuid.v4(),
      petId: petId,
      type: HealthLogType.medicine,
      createdAt: DateTime.now(),
      medicineName: name,
      dosage: dosage,
      frequency: frequency,
      medicineStartDate: startDate,
      medicineEndDate: endDate,
      notes: notes,
    ));
  }

  Future<HealthLog> addGrooming({
    required String petId,
    required String type,
    String? notes,
  }) {
    return add(HealthLog(
      id: _uuid.v4(),
      petId: petId,
      type: HealthLogType.grooming,
      createdAt: DateTime.now(),
      groomingType: type,
      notes: notes,
    ));
  }

  Future<HealthLog> addMicroscope({
    required String petId,
    required String imageBase64,
    String? aiSummary,
    String? notes,
  }) {
    return add(HealthLog(
      id: _uuid.v4(),
      petId: petId,
      type: HealthLogType.microscope,
      createdAt: DateTime.now(),
      imageBase64: imageBase64,
      aiSummary: aiSummary,
      notes: notes,
    ));
  }

  Future<void> delete(String id) async {
    _logs = _logs.where((l) => l.id != id).toList();
    await _storage.saveLogs(_logs);
    notifyListeners();
  }

  Future<void> clearAll() async {
    _logs = [];
    await _storage.saveLogs(_logs);
    notifyListeners();
  }
}
