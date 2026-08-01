import 'dart:convert';

enum HealthLogType {
  photo,
  weight,
  medicine,
  grooming,
  microscope,
}

extension HealthLogTypeX on HealthLogType {
  String get label {
    switch (this) {
      case HealthLogType.photo:
        return 'Photo';
      case HealthLogType.weight:
        return 'Weight';
      case HealthLogType.medicine:
        return 'Medicine';
      case HealthLogType.grooming:
        return 'Grooming';
      case HealthLogType.microscope:
        return 'Microscope';
    }
  }

  static HealthLogType parse(String s) {
    return HealthLogType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => HealthLogType.photo,
    );
  }
}

class HealthLog {
  final String id;
  final String petId;
  final HealthLogType type;
  final DateTime createdAt;
  final String? notes;

  // type-specific
  final String? imageBase64; // photo / microscope
  final double? weightKg; // weight
  final String? medicineName; // medicine
  final String? dosage; // medicine
  final String? frequency; // medicine
  final DateTime? medicineStartDate; // medicine
  final DateTime? medicineEndDate; // medicine
  final String? groomingType; // grooming: bath / brush / nails / ears / teeth
  final String? aiSummary; // microscope: AI text

  const HealthLog({
    required this.id,
    required this.petId,
    required this.type,
    required this.createdAt,
    this.notes,
    this.imageBase64,
    this.weightKg,
    this.medicineName,
    this.dosage,
    this.frequency,
    this.medicineStartDate,
    this.medicineEndDate,
    this.groomingType,
    this.aiSummary,
  });

  String get title {
    switch (type) {
      case HealthLogType.photo:
        return notes?.isNotEmpty == true ? 'Photo note' : 'Photo';
      case HealthLogType.weight:
        return 'Weight: ${weightKg?.toStringAsFixed(2) ?? '—'} kg';
      case HealthLogType.medicine:
        return 'Medicine: ${medicineName ?? '—'}';
      case HealthLogType.grooming:
        return 'Grooming: ${groomingType ?? '—'}';
      case HealthLogType.microscope:
        return 'Microscope sample';
    }
  }

  String get subtitle {
    switch (type) {
      case HealthLogType.medicine:
        final f = frequency ?? '';
        final d = dosage ?? '';
        if (f.isEmpty && d.isEmpty) return notes ?? '';
        return '${d.isEmpty ? '' : '$d '}${f.isEmpty ? '' : '· $f'}';
      default:
        return notes ?? '';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'petId': petId,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
        'notes': notes,
        'imageBase64': imageBase64,
        'weightKg': weightKg,
        'medicineName': medicineName,
        'dosage': dosage,
        'frequency': frequency,
        'medicineStartDate': medicineStartDate?.toIso8601String(),
        'medicineEndDate': medicineEndDate?.toIso8601String(),
        'groomingType': groomingType,
        'aiSummary': aiSummary,
      };

  factory HealthLog.fromJson(Map<String, dynamic> j) => HealthLog(
        id: j['id'] as String,
        petId: j['petId'] as String,
        type: HealthLogTypeX.parse(j['type'] as String? ?? 'photo'),
        createdAt: DateTime.parse(j['createdAt'] as String),
        notes: j['notes'] as String?,
        imageBase64: j['imageBase64'] as String?,
        weightKg: (j['weightKg'] as num?)?.toDouble(),
        medicineName: j['medicineName'] as String?,
        dosage: j['dosage'] as String?,
        frequency: j['frequency'] as String?,
        medicineStartDate: j['medicineStartDate'] != null
            ? DateTime.parse(j['medicineStartDate'] as String)
            : null,
        medicineEndDate: j['medicineEndDate'] != null
            ? DateTime.parse(j['medicineEndDate'] as String)
            : null,
        groomingType: j['groomingType'] as String?,
        aiSummary: j['aiSummary'] as String?,
      );

  String toRawJson() => jsonEncode(toJson());
  factory HealthLog.fromRawJson(String s) =>
      HealthLog.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
