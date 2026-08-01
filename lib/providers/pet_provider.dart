import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/pet.dart';
import '../services/storage_service.dart';

class PetProvider extends ChangeNotifier {
  final StorageService _storage;
  Pet? _pet;
  static const _uuid = Uuid();

  PetProvider(this._storage) {
    _pet = _storage.loadPet();
  }

  Pet? get pet => _pet;
  bool get hasPet => _pet != null;

  /// Creates a new pet and persists it.
  Future<Pet> createPet({
    required String name,
    required String species,
    String? breed,
    DateTime? birthDate,
    String? photoBase64,
    double? currentWeightKg,
    String? sex,
    String? notes,
  }) async {
    final p = Pet(
      id: _uuid.v4(),
      name: name.trim(),
      species: species.trim(),
      breed: breed?.trim().isEmpty == true ? null : breed?.trim(),
      birthDate: birthDate,
      photoBase64: photoBase64,
      currentWeightKg: currentWeightKg,
      sex: sex,
      notes: notes,
    );
    await _storage.savePet(p);
    _pet = p;
    notifyListeners();
    return p;
  }

  Future<void> updatePet(Pet p) async {
    await _storage.savePet(p);
    _pet = p;
    notifyListeners();
  }

  /// Updates weight and persists, creating a pet shell if none exists.
  Future<void> setCurrentWeight(double kg) async {
    if (_pet == null) return;
    final updated = _pet!.copyWith(currentWeightKg: kg);
    await updatePet(updated);
  }
}
