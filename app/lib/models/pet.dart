import 'dart:convert';

class Pet {
  final String id;
  final String name;
  final String species; // e.g. "Cat", "Dog"
  final String? breed;
  final DateTime? birthDate;
  final String? photoBase64; // data URL, optional
  final double? currentWeightKg;
  final String? sex; // "Male" | "Female" | "Unknown"
  final String? notes;

  const Pet({
    required this.id,
    required this.name,
    required this.species,
    this.breed,
    this.birthDate,
    this.photoBase64,
    this.currentWeightKg,
    this.sex,
    this.notes,
  });

  int? get ageMonths {
    if (birthDate == null) return null;
    final now = DateTime.now();
    return (now.year - birthDate!.year) * 12 + (now.month - birthDate!.month);
  }

  String get ageLabel {
    final m = ageMonths;
    if (m == null) return 'Age unknown';
    if (m < 12) return '$m mo';
    final y = m ~/ 12;
    final rem = m % 12;
    if (rem == 0) return '$y yr';
    return '$y yr $rem mo';
  }

  Pet copyWith({
    String? id,
    String? name,
    String? species,
    String? breed,
    DateTime? birthDate,
    String? photoBase64,
    double? currentWeightKg,
    String? sex,
    String? notes,
    bool clearPhoto = false,
    bool clearWeight = false,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      birthDate: birthDate ?? this.birthDate,
      photoBase64: clearPhoto ? null : (photoBase64 ?? this.photoBase64),
      currentWeightKg: clearWeight ? null : (currentWeightKg ?? this.currentWeightKg),
      sex: sex ?? this.sex,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'species': species,
        'breed': breed,
        'birthDate': birthDate?.toIso8601String(),
        'photoBase64': photoBase64,
        'currentWeightKg': currentWeightKg,
        'sex': sex,
        'notes': notes,
      };

  factory Pet.fromJson(Map<String, dynamic> j) => Pet(
        id: j['id'] as String,
        name: j['name'] as String,
        species: (j['species'] as String?) ?? 'Pet',
        breed: j['breed'] as String?,
        birthDate: j['birthDate'] != null ? DateTime.parse(j['birthDate'] as String) : null,
        photoBase64: j['photoBase64'] as String?,
        currentWeightKg: (j['currentWeightKg'] as num?)?.toDouble(),
        sex: j['sex'] as String?,
        notes: j['notes'] as String?,
      );

  String toRawJson() => jsonEncode(toJson());
  factory Pet.fromRawJson(String s) => Pet.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
