enum ModelWarningType {
  unsupported,
  compatibility,
  other,
}

final class ModelWarning {
  final ModelWarningType type;
  final String message;
  final String? field;

  const ModelWarning({
    required this.type,
    required this.message,
    this.field,
  });

  @override
  bool operator ==(Object other) {
    return other is ModelWarning &&
        other.type == type &&
        other.message == message &&
        other.field == field;
  }

  @override
  int get hashCode => Object.hash(type, message, field);

  @override
  String toString() {
    return 'ModelWarning(type: $type, message: $message, field: $field)';
  }
}
