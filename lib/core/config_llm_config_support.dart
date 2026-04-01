part of 'config.dart';

ToolChoice _parseToolChoice(Map<String, dynamic> json) {
  final type = json['type'] as String;
  switch (type) {
    case 'auto':
      return const AutoToolChoice();
    case 'required':
      return const AnyToolChoice();
    case 'none':
      return const NoneToolChoice();
    case 'function':
      final functionName = json['function']['name'] as String;
      return SpecificToolChoice(functionName);
    default:
      throw ArgumentError('Unknown tool choice type: $type');
  }
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}
