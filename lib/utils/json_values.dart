/// Small, forgiving converters for values that arrive from Supabase.
///
/// PostgREST can return numbers as `int`, `double`, or `String` depending on
/// the column type, so every model reads through these helpers instead of
/// assuming a concrete Dart type.
double asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0;
  return 0;
}

int asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

int? asIntOrNull(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

String asString(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

String? asStringOrNull(Object? value) {
  final text = asString(value).trim();
  return text.isEmpty ? null : text;
}

DateTime? asDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final text = value is String ? value.trim() : '';
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

bool asBool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final text = value.toLowerCase().trim();
    if (text == 'true' || text == 't' || text == '1') return true;
    if (text == 'false' || text == 'f' || text == '0') return false;
  }
  return fallback;
}
