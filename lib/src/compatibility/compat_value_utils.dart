Object? compatNormalizeJsonValue(Object? value) {
  return switch (value) {
    null || bool() || num() || String() => value,
    List() => value.map(compatNormalizeJsonValue).toList(growable: false),
    Map() => value.map(
        (key, nestedValue) => MapEntry(
          key as String,
          compatNormalizeJsonValue(nestedValue),
        ),
      ),
    _ => value.toString(),
  };
}

DateTime? parseCompatUtcDate(String? value) {
  if (value == null) {
    return null;
  }

  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) {
    return null;
  }

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);

  try {
    final parsed = DateTime.utc(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  } catch (_) {
    return null;
  }
}
