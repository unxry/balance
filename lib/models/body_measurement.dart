enum BodyMeasurementType { chest, hips }

class BodyMeasurement {
  final String id;
  final DateTime date;
  final BodyMeasurementType type;
  final double cm;

  const BodyMeasurement({
    required this.id,
    required this.date,
    required this.type,
    required this.cm,
  });

  static bool validValue(double value) =>
      value.isFinite && value >= 10 && value <= 300;

  static double? parseValue(String value) {
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    return parsed != null && validValue(parsed) ? parsed : null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toUtc().toIso8601String(),
    'type': type.name,
    'cm': cm,
  };

  static BodyMeasurement? tryFromJson(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    final rawDate = value['date'];
    final date = rawDate is String ? DateTime.tryParse(rawDate) : null;
    final rawCm = value['cm'];
    final types = BodyMeasurementType.values.where(
      (type) => type.name == value['type'],
    );
    if (id is! String ||
        id.isEmpty ||
        date == null ||
        types.isEmpty ||
        rawCm is! num ||
        !validValue(rawCm.toDouble())) {
      return null;
    }
    return BodyMeasurement(
      id: id,
      date: date.toLocal(),
      type: types.first,
      cm: rawCm.toDouble(),
    );
  }
}
